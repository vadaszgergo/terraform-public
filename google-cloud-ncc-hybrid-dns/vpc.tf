# =============================================================================
# Infra VPC - Hosts DNS VM and SD-WAN appliance
# =============================================================================
resource "google_compute_network" "infra" {
  name                    = "infra-vpc"
  auto_create_subnetworks = false
  depends_on              = [google_project_service.apis]
}

resource "google_compute_subnetwork" "infra" {
  name          = "infra-subnet"
  network       = google_compute_network.infra.id
  region        = var.region
  ip_cidr_range = var.infra_subnet_cidr
}

# =============================================================================
# Application VPC - Hosts application workloads
# =============================================================================
resource "google_compute_network" "app" {
  name                    = "app-vpc"
  auto_create_subnetworks = false
  depends_on              = [google_project_service.apis]
}

resource "google_compute_subnetwork" "app" {
  name          = "app-subnet"
  network       = google_compute_network.app.id
  region        = var.region
  ip_cidr_range = var.app_subnet_cidr
}

# =============================================================================
# Simulated On-Prem VPC - Represents the corporate data center
# =============================================================================
resource "google_compute_network" "onprem" {
  name                    = "onprem-vpc"
  auto_create_subnetworks = false
  depends_on              = [google_project_service.apis]
}

resource "google_compute_subnetwork" "onprem" {
  name          = "onprem-subnet"
  network       = google_compute_network.onprem.id
  region        = var.region
  ip_cidr_range = var.onprem_subnet_cidr
}

# =============================================================================
# Cloud Router for NCC Router Appliance BGP peering
# =============================================================================
resource "google_compute_router" "ncc" {
  name    = "ncc-router"
  network = google_compute_network.infra.id
  region  = var.region

  bgp {
    asn = 64514
  }
}

# =============================================================================
# Static route in on-prem VPC to reach GCP networks via SD-WAN VM
# =============================================================================
resource "google_compute_route" "onprem_to_gcp" {
  name        = "onprem-to-gcp-via-sdwan"
  network     = google_compute_network.onprem.id
  dest_range  = "10.0.0.0/8"
  next_hop_ip = var.sdwan_vm_onprem_ip
  priority    = 100
  depends_on  = [google_compute_instance.sdwan]
}
