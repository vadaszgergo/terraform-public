resource "google_compute_instance" "internal_vm" {
  name         = "internal-vm"
  project      = var.project_id
  zone         = "${var.region}-b" # Example zone
  machine_type = "e2-micro"

  tags = ["internal-vm", "allow-all-ingress"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 10
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.internal_subnet.id
    access_config {
      // Ephemeral public IP will be assigned
    }
  }

  service_account {
    scopes = ["cloud-platform"]
  }

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
  }

  allow_stopping_for_update = true
} 