provider "google" {
  project = var.project_id
  region  = var.region
}

# VPC Network
resource "google_compute_network" "vpc" {
  name                    = var.vpc_name
  auto_create_subnetworks = false
  description             = "VPC network for Cloud Run VPC integration"
}

# Subnet
resource "google_compute_subnetwork" "subnet" {
  name          = var.subnet_name
  ip_cidr_range = var.subnet_cidr
  region        = var.region
  network       = google_compute_network.vpc.id
  description   = "Subnet for Cloud Run direct VPC egress in ${var.region}"

  # Enable private Google access for Cloud Run
  private_ip_google_access = true
}
/*
# Cloud Run Service with Direct VPC Egress
resource "google_cloud_run_v2_service" "default" {
  name         = var.cloud_run_service_name
  location     = var.region
  launch_stage = "GA"

  template {
    containers {
      image = var.cloud_run_image
      ports {
        container_port = var.cloud_run_port
      }
      env {
        name  = "PORT"
        value = tostring(var.cloud_run_port)
      }
    }
    vpc_access {
      network_interfaces {
        network    = google_compute_network.vpc.name
        subnetwork = google_compute_subnetwork.subnet.name
      }
    }
  }
}
*/

# Static IP address for VPN gateway
resource "google_compute_address" "vpn_gateway_ip" {
  name   = "${var.vpn_gateway_name}-ip"
  region = var.region
}

# Classic VPN Gateway (Target VPN Gateway)
resource "google_compute_vpn_gateway" "vpn_gateway" {
  name    = var.vpn_gateway_name
  network = google_compute_network.vpc.id
  region  = var.region
}

# Forwarding rule for ESP protocol
resource "google_compute_forwarding_rule" "vpn_gateway_esp" {
  name        = "${var.vpn_gateway_name}-esp"
  ip_protocol = "ESP"
  ip_address  = google_compute_address.vpn_gateway_ip.address
  target      = google_compute_vpn_gateway.vpn_gateway.id
  region      = var.region
}

# Forwarding rule for UDP port 500 (IKE)
resource "google_compute_forwarding_rule" "vpn_gateway_udp500" {
  name        = "${var.vpn_gateway_name}-udp500"
  ip_protocol = "UDP"
  port_range  = "500"
  ip_address  = google_compute_address.vpn_gateway_ip.address
  target      = google_compute_vpn_gateway.vpn_gateway.id
  region      = var.region
}

# Forwarding rule for UDP port 4500 (NAT-T)
resource "google_compute_forwarding_rule" "vpn_gateway_udp4500" {
  name        = "${var.vpn_gateway_name}-udp4500"
  ip_protocol = "UDP"
  port_range  = "4500"
  ip_address  = google_compute_address.vpn_gateway_ip.address
  target      = google_compute_vpn_gateway.vpn_gateway.id
  region      = var.region
}

# Classic VPN Tunnel (Route-based)
# For route-based VPN, traffic selectors must be set to 0.0.0.0/0
# Routes determine what traffic actually goes through the tunnel
resource "google_compute_vpn_tunnel" "vpn_tunnel" {
  name                   = var.vpn_tunnel_name
  region                 = var.region
  target_vpn_gateway     = google_compute_vpn_gateway.vpn_gateway.id
  peer_ip                = var.vpn_remote_ip
  shared_secret          = var.shared_secret
  local_traffic_selector = ["0.0.0.0/0"]
  remote_traffic_selector = ["0.0.0.0/0"]

  depends_on = [
    google_compute_vpn_gateway.vpn_gateway,
    google_compute_forwarding_rule.vpn_gateway_esp,
    google_compute_forwarding_rule.vpn_gateway_udp500,
    google_compute_forwarding_rule.vpn_gateway_udp4500
  ]
}

# Route for VPN tunnel to route traffic to on-premises network
resource "google_compute_route" "vpn_route" {
  name       = var.route_name
  network    = google_compute_network.vpc.name
  dest_range = var.route_dest_range
  priority   = var.route_priority

  next_hop_vpn_tunnel = google_compute_vpn_tunnel.vpn_tunnel.id
}

