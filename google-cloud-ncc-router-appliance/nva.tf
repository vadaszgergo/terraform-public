# Reserve static internal IP for NVA
resource "google_compute_address" "nva_internal_ip" {
  name         = "nva-internal-ip"
  project      = var.project_id
  subnetwork   = google_compute_subnetwork.router_appliance_subnet.id
  address_type = "INTERNAL"
  region       = var.region
  description  = "Static internal IP for NVA instance"
  # You can specify an address if needed, e.g., address = "10.1.0.5"
}

# NVA Instance (Ubuntu + FRR)
resource "google_compute_instance" "nva" {
  name         = "nva-instance"
  project      = var.project_id
  zone         = "${var.region}-b" # Example zone
  machine_type = "e2-micro"

  tags = ["nva", "allow-all-ingress"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 10
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.router_appliance_subnet.id
    network_ip = google_compute_address.nva_internal_ip.address # Assign static IP
    access_config {
      // Ephemeral public IP will be assigned
    }
  }

  # Enable IP forwarding on GCP infrastructure level
  can_ip_forward = true

  # Startup script to install FRR, enable BGP, and enable kernel forwarding
  metadata_startup_script = <<-EOT
    #!/bin/bash
    set -e # Exit on error

    echo "Starting NVA setup..."

    # Update package list
    apt-get update -y

    # Enable IP forwarding in kernel and make persistent
    echo "Enabling Kernel IP Forwarding..."
    sysctl -w net.ipv4.ip_forward=1
    sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf
    sysctl -p # Apply changes immediately

    # Install FRR
    echo "Installing FRR..."
    curl -s https://deb.frrouting.org/frr/keys.asc | apt-key add -
    FRRVER="frr-stable"
    echo deb https://deb.frrouting.org/frr $(lsb_release -s -c) $FRRVER | tee /etc/apt/sources.list.d/frr.list
    apt-get update -y
    apt-get install -y frr frr-pythontools --allow-unauthenticated || apt-get install -y frr frr-pythontools # Retry without auth if needed

    # Enable BGP daemon in FRR configuration
    echo "Configuring FRR daemons..."
    sed -i 's/bgpd=no/bgpd=yes/' /etc/frr/daemons

    # Restart FRR service
    echo "Restarting FRR service..."
    systemctl restart frr
    
    # Adding loopback ip and route to simulate remote network on the NVA
    ip addr add 192.168.0.1/24 dev lo
    ip route add 192.168.0.0/24 dev lo

    vtysh -c 'conf t' \
    -c 'route-map ACCEPT-ALL permit 10' \
    -c 'exit' \
    -c 'router bgp 65001' \
    -c 'neighbor 10.1.0.4 remote-as 64512' \
    -c 'neighbor 10.1.0.4 description "GCP Peer 1"' \
    -c 'neighbor 10.1.0.4 ebgp-multihop' \
    -c 'neighbor 10.1.0.4 disable-connected-check' \
    -c 'neighbor 10.1.0.5 remote-as 64512' \
    -c 'neighbor 10.1.0.5 description "GCP 2"' \
    -c 'neighbor 10.1.0.5 ebgp-multihop' \
    -c 'neighbor 10.1.0.5 disable-connected-check' \
    -c 'address-family ipv4 unicast' \
    -c 'network 192.168.0.0/24' \
    -c 'neighbor 10.1.0.4 soft-reconfiguration inbound' \
    -c 'neighbor 10.1.0.4 route-map ACCEPT-ALL in' \
    -c 'neighbor 10.1.0.4 route-map ACCEPT-ALL out' \
    -c 'neighbor 10.1.0.5 soft-reconfiguration inbound' \
    -c 'neighbor 10.1.0.5 route-map ACCEPT-ALL in' \
    -c 'neighbor 10.1.0.5 route-map ACCEPT-ALL out' \
    -c 'end' \
    -c 'write'
    

    echo "NVA setup complete."
    EOT

  service_account {
    scopes = ["cloud-platform"]
  }

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
  }

  allow_stopping_for_update = true
} 