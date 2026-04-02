# =============================================================================
# NCC Hub
# =============================================================================
resource "google_network_connectivity_hub" "hub" {
  name       = "ncc-hub"
  depends_on = [google_project_service.apis]
}

# =============================================================================
# VPC Spokes
# =============================================================================
resource "google_network_connectivity_spoke" "infra" {
  name     = "infra-spoke"
  hub      = google_network_connectivity_hub.hub.id
  location = "global"

  linked_vpc_network {
    uri = google_compute_network.infra.self_link
  }
}

resource "google_network_connectivity_spoke" "app" {
  name     = "app-spoke"
  hub      = google_network_connectivity_hub.hub.id
  location = "global"

  linked_vpc_network {
    uri = google_compute_network.app.self_link
  }
}

# =============================================================================
# SD-WAN Router Appliance Spoke
# =============================================================================
resource "google_network_connectivity_spoke" "sdwan" {
  name     = "sdwan-spoke"
  hub      = google_network_connectivity_hub.hub.id
  location = var.region

  linked_router_appliance_instances {
    instances {
      virtual_machine = google_compute_instance.sdwan.self_link
      ip_address      = var.sdwan_vm_infra_ip
    }
    site_to_site_data_transfer = false
  }
}

# =============================================================================
# Cloud Router interfaces for BGP with SD-WAN VM
# Two interfaces for redundancy (NCC best practice)
# =============================================================================
resource "google_compute_router_interface" "sdwan_0" {
  name               = "sdwan-iface-0"
  router             = google_compute_router.ncc.name
  region             = var.region
  subnetwork         = google_compute_subnetwork.infra.self_link
  private_ip_address = var.ncc_router_ip_0
}

resource "google_compute_router_interface" "sdwan_1" {
  name                = "sdwan-iface-1"
  router              = google_compute_router.ncc.name
  region              = var.region
  subnetwork          = google_compute_subnetwork.infra.self_link
  private_ip_address  = var.ncc_router_ip_1
  redundant_interface = google_compute_router_interface.sdwan_0.name
}

# =============================================================================
# BGP peers - Cloud Router <-> SD-WAN VM (FRR)
# =============================================================================
resource "google_compute_router_peer" "sdwan_0" {
  name                      = "sdwan-peer-0"
  router                    = google_compute_router.ncc.name
  region                    = var.region
  interface                 = google_compute_router_interface.sdwan_0.name
  peer_ip_address           = var.sdwan_vm_infra_ip
  peer_asn                  = 64515
  router_appliance_instance = google_compute_instance.sdwan.self_link
  depends_on                = [google_network_connectivity_spoke.sdwan]
}

resource "google_compute_router_peer" "sdwan_1" {
  name                      = "sdwan-peer-1"
  router                    = google_compute_router.ncc.name
  region                    = var.region
  interface                 = google_compute_router_interface.sdwan_1.name
  peer_ip_address           = var.sdwan_vm_infra_ip
  peer_asn                  = 64515
  router_appliance_instance = google_compute_instance.sdwan.self_link
  depends_on                = [google_network_connectivity_spoke.sdwan]
}
