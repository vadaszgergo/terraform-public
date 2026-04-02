terraform {
  required_version = ">= 1.5"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# Enable required APIs
resource "google_project_service" "apis" {
  for_each = toset([
    "compute.googleapis.com",
    "dns.googleapis.com",
    "networkconnectivity.googleapis.com",
  ])
  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}
