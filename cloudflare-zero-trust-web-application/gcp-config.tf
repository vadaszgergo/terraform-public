# OS the server will use
data "google_compute_image" "image" {
  family  = "ubuntu-2204-lts"
  project = "ubuntu-os-cloud"
}

# GCP Instance resource
resource "google_compute_instance" "http_server" {
  name         = "test"
  machine_type = var.machine_type
  zone         = var.zone
  tags         = []
  boot_disk {
    initialize_params {
      image = data.google_compute_image.image.self_link
    }
  }

network_interface {
  subnetwork   = "projects/vadaszgergo/regions/europe-west4/subnetworks/subnet-gergo-01"
  access_config {}
}
  // Optional config to make instance ephemeral
/*  scheduling {
    preemptible       = true
    automatic_restart = false
  } */

  // Pass the tunnel token to the GCP server so that the server can install and run the tunnel upon startup.
  metadata_startup_script = templatefile("./install-tunnel.tftpl",
    {
      tunnel_token = data.cloudflare_zero_trust_tunnel_cloudflared_token.gcp_tunnel_token.token
    })
}
