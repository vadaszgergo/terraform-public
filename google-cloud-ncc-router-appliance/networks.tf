# --- Internal VPC ---
resource "google_compute_network" "internal_vpc" {
  name                    = "internal-vpc"
  project                 = var.project_id
  auto_create_subnetworks = false
  description             = "VPC for internal resources"
}

resource "google_compute_subnetwork" "internal_subnet" {
  name          = "internal-subnet-ew1"
  project       = var.project_id
  ip_cidr_range = "10.0.0.0/24"
  region        = var.region
  network       = google_compute_network.internal_vpc.id
  description   = "Internal subnet in ${var.region}"
}

# --- Router Appliance VPC ---
resource "google_compute_network" "router_appliance_vpc" {
  name                    = "router-appliance-vpc"
  project                 = var.project_id
  auto_create_subnetworks = false
  description             = "VPC for router appliance"
}

resource "google_compute_subnetwork" "router_appliance_subnet" {
  name          = "router-appliance-subnet-ew1"
  project       = var.project_id
  ip_cidr_range = "10.1.0.0/24"
  region        = var.region
  network       = google_compute_network.router_appliance_vpc.id
  description   = "Router appliance subnet in ${var.region}"
} 