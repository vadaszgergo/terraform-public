# =============================================================================
# Infra VPC Firewall Rules
# =============================================================================

# Allow all internal traffic (RFC1918)
resource "google_compute_firewall" "infra_internal" {
  name    = "infra-allow-internal"
  network = google_compute_network.infra.id

  allow {
    protocol = "icmp"
  }
  allow {
    protocol = "tcp"
  }
  allow {
    protocol = "udp"
  }

  source_ranges = ["10.0.0.0/8", "192.168.0.0/16"]
}

# Allow Cloud DNS forwarding to reach the DNS VM
# Cloud DNS uses 35.199.192.0/19 as source when forwarding queries
resource "google_compute_firewall" "infra_clouddns" {
  name    = "infra-allow-clouddns-to-dns-vm"
  network = google_compute_network.infra.id

  allow {
    protocol = "tcp"
    ports    = ["53"]
  }
  allow {
    protocol = "udp"
    ports    = ["53"]
  }

  source_ranges = ["35.199.192.0/19"]
  target_tags   = ["dns-server"]
}

# Allow SSH via IAP
resource "google_compute_firewall" "infra_iap_ssh" {
  name    = "infra-allow-iap-ssh"
  network = google_compute_network.infra.id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["35.235.240.0/20"] # IAP range
}

# =============================================================================
# Application VPC Firewall Rules
# =============================================================================

resource "google_compute_firewall" "app_internal" {
  name    = "app-allow-internal"
  network = google_compute_network.app.id

  allow {
    protocol = "icmp"
  }
  allow {
    protocol = "tcp"
  }
  allow {
    protocol = "udp"
  }

  source_ranges = ["10.0.0.0/8", "192.168.0.0/16"]
}

resource "google_compute_firewall" "app_iap_ssh" {
  name    = "app-allow-iap-ssh"
  network = google_compute_network.app.id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["35.235.240.0/20"]
}

# =============================================================================
# On-Prem VPC Firewall Rules
# =============================================================================

resource "google_compute_firewall" "onprem_internal" {
  name    = "onprem-allow-internal"
  network = google_compute_network.onprem.id

  allow {
    protocol = "icmp"
  }
  allow {
    protocol = "tcp"
  }
  allow {
    protocol = "udp"
  }

  source_ranges = ["10.0.0.0/8", "192.168.0.0/16"]
}

resource "google_compute_firewall" "onprem_iap_ssh" {
  name    = "onprem-allow-iap-ssh"
  network = google_compute_network.onprem.id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["35.235.240.0/20"]
}
