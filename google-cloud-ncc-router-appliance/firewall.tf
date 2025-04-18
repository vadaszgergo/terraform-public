# WARNING: Less secure SSH rule
# resource "google_compute_firewall" "allow_ssh_all" {
#   name    = "allow-ssh-all-networks" # Give unique name
#   project = var.project_id
#   network = google_compute_network.internal_vpc.name # Select network
#   allow {
#     protocol = "tcp"
#     ports    = ["22"]
#   }
#   source_ranges = ["0.0.0.0/0"] # Insecure - Allow from anywhere
#   target_tags   = ["allow-ssh"]
#   description   = "WARNING: Allow SSH from anywhere (less secure)"
# }
# # Duplicate for router_appliance_vpc if using this rule

# --- WARNING: HIGHLY INSECURE INGRESS RULE ---
# Allows ALL protocols/ports from ANY source. Use only for isolated testing.
resource "google_compute_firewall" "allow_all_ingress_internal_vpc" {
  name    = "allow-all-ingress-internal-vpc"
  project = var.project_id
  network = google_compute_network.internal_vpc.name # Apply to internal VPC

  # Allow all protocols
  allow {
    protocol = "all"
    # No ports specified means all ports
  }
  # Allow from any source IP
  source_ranges = ["0.0.0.0/0"]
  # Apply to instances tagged with "allow-all-ingress"
  target_tags   = ["allow-all-ingress"]
  description   = "WARNING: Allows all ingress traffic from any source to tagged instances in internal VPC."
}

# --- WARNING: HIGHLY INSECURE INGRESS RULE ---
# Allows ALL protocols/ports from ANY source. Use only for isolated testing.
resource "google_compute_firewall" "allow_all_ingress_router_vpc" {
  name    = "allow-all-ingress-router-vpc"
  project = var.project_id
  network = google_compute_network.router_appliance_vpc.name # Apply to router VPC

  # Allow all protocols
  allow {
    protocol = "all"
    # No ports specified means all ports
  }
  # Allow from any source IP
  source_ranges = ["0.0.0.0/0"]
  # Apply to instances tagged with "allow-all-ingress"
  target_tags   = ["allow-all-ingress"]
  description   = "WARNING: Allows all ingress traffic from any source to tagged instances in router VPC."
}
# --- End Insecure Rules ---



resource "google_compute_firewall" "allow_nva_forwarded_traffic" {
  # Allows traffic originating *from behind* the NVA to egress the VPC
  name        = "allow-nva-forwarded-traffic"
  project     = var.project_id
  network     = google_compute_network.router_appliance_vpc.name
  direction   = "EGRESS" # Apply to outgoing traffic
  priority    = 900      # Higher priority (lower number) than default deny egress

  allow {
    protocol = "all" # Allow all protocols, refine if needed
  }

  destination_ranges = ["0.0.0.0/0"] # Allow to any destination
  # Apply ONLY to traffic leaving the NVA instance
  target_tags = ["nva"]
  description = "Allow EGRESS traffic forwarded by the NVA instance"
}

