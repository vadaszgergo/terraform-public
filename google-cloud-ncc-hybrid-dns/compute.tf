# =============================================================================
# DNS VM - BIND9 conditional forwarder in Infra VPC
#
# This VM is the bridge between GCP and on-prem DNS.
# In a real setup, this would be an IPAM grid member (Infoblox, EfficientIP, etc.)
# =============================================================================
resource "google_compute_instance" "dns" {
  name         = "dns-vm"
  machine_type = "e2-small"
  zone         = var.zone
  tags         = ["dns-server"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.infra.id
    network_ip = var.dns_vm_ip
    access_config {} # External IP for SSH access - remove in production
  }

  metadata_startup_script = file("${path.module}/scripts/dns-vm.sh")

  depends_on = [google_project_service.apis]
}

# =============================================================================
# SD-WAN VM - Router Appliance with FRR (BGP) - Multi-NIC
#
# Simulates an SD-WAN appliance connecting GCP to on-prem.
# NIC0 is in the Infra VPC (GCP side), NIC1 is in the On-Prem VPC.
# Peers BGP with NCC Cloud Router to advertise on-prem routes.
# =============================================================================
resource "google_compute_instance" "sdwan" {
  name           = "sdwan-vm"
  machine_type   = "e2-medium" # Needs 2+ vCPUs for multi-NIC
  zone           = var.zone
  tags           = ["sdwan-appliance"]
  can_ip_forward = true

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
    }
  }

  # NIC0 - Infra VPC (GCP side, BGP peering with NCC)
  network_interface {
    subnetwork = google_compute_subnetwork.infra.id
    network_ip = var.sdwan_vm_infra_ip
    access_config {}
  }

  # NIC1 - On-Prem VPC (simulated WAN side)
  network_interface {
    subnetwork = google_compute_subnetwork.onprem.id
    network_ip = var.sdwan_vm_onprem_ip
  }

  metadata_startup_script = file("${path.module}/scripts/sdwan-vm.sh")

  depends_on = [google_project_service.apis]
}

# =============================================================================
# Application VM - Test workload in App VPC
# Used to verify DNS resolution from the application side
# =============================================================================
resource "google_compute_instance" "app" {
  name         = "app-vm"
  machine_type = "e2-small"
  zone         = var.zone
  tags         = ["app-workload"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.app.id
    network_ip = var.app_vm_ip
    access_config {}
  }

  metadata_startup_script = file("${path.module}/scripts/app-vm.sh")

  depends_on = [google_project_service.apis]
}

# =============================================================================
# On-Prem DNS VM - Authoritative for on-prem.example.com
# Simulates the corporate DNS/IPAM infrastructure
# =============================================================================
resource "google_compute_instance" "onprem_dns" {
  name         = "onprem-dns-vm"
  machine_type = "e2-small"
  zone         = var.zone
  tags         = ["onprem-dns"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.onprem.id
    network_ip = var.onprem_dns_ip
    access_config {}
  }

  metadata_startup_script = file("${path.module}/scripts/onprem-dns.sh")

  depends_on = [google_project_service.apis]
}
