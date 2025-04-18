# Cloud Router in Router Appliance VPC
resource "google_compute_router" "router_for_nva" {
  name    = "router-for-nva-ha"
  project = var.project_id
  region  = var.region
  network = google_compute_network.router_appliance_vpc.id
  description = "Cloud Router with HA interfaces to peer with the NVA"

  bgp {
    asn = var.cloud_router_asn
    advertise_mode = "DEFAULT"
    # Keep alive interval can be added if needed
    # keepalive_interval = 20
  }
}

# --- Interface 1 ---
resource "google_compute_router_interface" "router_interface_1" {
  name    = "interface-1-for-nva-peer"
  project = google_compute_router.router_for_nva.project
  region  = google_compute_router.router_for_nva.region
  router  = google_compute_router.router_for_nva.name
  subnetwork = google_compute_subnetwork.router_appliance_subnet.id
  # Assign a specific IP
  private_ip_address = cidrhost(google_compute_subnetwork.router_appliance_subnet.ip_cidr_range, 4) # e.g., 10.1.0.4
}

# --- Interface 2 (Redundant) ---
resource "google_compute_router_interface" "router_interface_2" {
  name    = "interface-2-for-nva-peer"
  project = google_compute_router.router_for_nva.project
  region  = google_compute_router.router_for_nva.region
  router  = google_compute_router.router_for_nva.name
  subnetwork = google_compute_subnetwork.router_appliance_subnet.id
  # Assign a different specific IP
  private_ip_address = cidrhost(google_compute_subnetwork.router_appliance_subnet.ip_cidr_range, 5) # e.g., 10.1.0.5
  # Link to the first interface for redundancy
  redundant_interface = google_compute_router_interface.router_interface_1.name
}

# --- BGP Peer 1 (Using Interface 1) ---
resource "google_compute_router_peer" "peer_1_to_nva" {
  name            = "peer-1-to-nva"
  project         = google_compute_router.router_for_nva.project
  region          = google_compute_router.router_for_nva.region
  router          = google_compute_router.router_for_nva.name
  interface       = google_compute_router_interface.router_interface_1.name
  peer_ip_address = google_compute_address.nva_internal_ip.address # NVA's static IP
  peer_asn        = var.nva_asn
  router_appliance_instance = google_compute_instance.nva.self_link
  enable                      = true
  # advertised_route_priority = 100 # Default
}

# --- BGP Peer 2 (Using Interface 2) ---
resource "google_compute_router_peer" "peer_2_to_nva" {
  name            = "peer-2-to-nva"
  project         = google_compute_router.router_for_nva.project
  region          = google_compute_router.router_for_nva.region
  router          = google_compute_router.router_for_nva.name
  interface       = google_compute_router_interface.router_interface_2.name
  peer_ip_address = google_compute_address.nva_internal_ip.address # NVA's static IP (same instance)
  peer_asn        = var.nva_asn
  router_appliance_instance = google_compute_instance.nva.self_link
  enable                      = true
  # advertised_route_priority = 100 # Can adjust if needed
} 