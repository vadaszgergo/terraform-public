# --- NCC Hub ---
resource "google_network_connectivity_hub" "testing_hub" {
  name        = "ncc-testing-hub"
  project     = var.project_id
  description = "NCC Hub for testing router appliance spokes"
  labels = {
    environment = "testing"
  }
}

# --- NCC Spoke for Internal VPC ---
resource "google_network_connectivity_spoke" "internal_vpc_spoke" {
  name     = "internal-vpc-spoke"
  project  = var.project_id
  location = "global" # VPC spokes are global
  hub      = google_network_connectivity_hub.testing_hub.id
  description = "Spoke connecting internal-vpc to the hub"

  linked_vpc_network {
    uri = google_compute_network.internal_vpc.self_link
    # Exclude export ranges if not needed immediately
    # exclude_export_ranges = ["192.168.1.0/24", "192.168.2.0/24"]
  }

  labels = {
    environment = "testing"
    vpc_name    = google_compute_network.internal_vpc.name
  }
}

# --- NCC Spoke for Router Appliance ---
resource "google_network_connectivity_spoke" "router_appliance_spoke" {
  name        = "router-appliance-spoke"
  project     = var.project_id
  location    = var.region  # Router appliance spokes must be regional
  hub         = google_network_connectivity_hub.testing_hub.id
  description = "Spoke connecting the NVA instance to the hub"

  linked_router_appliance_instances {
    instances {
      virtual_machine = google_compute_instance.nva.self_link
      ip_address     = google_compute_address.nva_internal_ip.address
    }
    site_to_site_data_transfer = true
  }

  labels = {
    environment = "testing"
    type        = "router-appliance"
  }
} 