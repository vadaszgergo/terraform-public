# Creates a new remotely-managed tunnel for the GCP VM.
resource "cloudflare_zero_trust_tunnel_cloudflared" "gcp_tunnel" {
  account_id    = var.cloudflare_account_id
  name          = "Terraform GCP tunnel"
  config_src    = "cloudflare"
}

# Reads the token used to run the tunnel on the server.
data "cloudflare_zero_trust_tunnel_cloudflared_token" "gcp_tunnel_token" {
  account_id   = var.cloudflare_account_id
  tunnel_id   = cloudflare_zero_trust_tunnel_cloudflared.gcp_tunnel.id
}

# Creates the CNAME record that routes http_app.${var.cloudflare_zone} to the tunnel.
resource "cloudflare_dns_record" "http_app" {
  zone_id = var.cloudflare_zone_id
  name    = "http_app"
  content = "${cloudflare_zero_trust_tunnel_cloudflared.gcp_tunnel.id}.cfargotunnel.com"
  type    = "CNAME"
  ttl     = 1
  proxied = true
}

# Configures tunnel with a published application for clientless access.
resource "cloudflare_zero_trust_tunnel_cloudflared_config" "gcp_tunnel_config" {
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.gcp_tunnel.id
  account_id = var.cloudflare_account_id
  config     = {
    ingress   = [
      {
        hostname = "http_app.${var.cloudflare_zone}"
        service  = "http://localhost:80"
      },
      {
        service  = "http_status:404"
      }
    ]
  }
}

# (Optional) Routes internal IP of GCP instance through the tunnel for private network access using WARP.
# resource "cloudflare_zero_trust_tunnel_cloudflared_route" "example_tunnel_route" {
# account_id         = var.cloudflare_account_id
# tunnel_id          = cloudflare_zero_trust_tunnel_cloudflared.gcp_tunnel.id
# network            = google_compute_instance.http_server.network_interface.0.network_ip
# comment            = "Example tunnel route"
# }

# Creates a list of allowed emails, who can access the private website.
resource "cloudflare_zero_trust_list" "allowed_emails" {
  account_id  = var.cloudflare_account_id
  name        = "Allowed Emails"
  description = "Managed by Terraform"
  type        = "EMAIL"
  items = [
    {
      value = "test@test.com"
    },
    {
      value = "test2@test.com"
    },
    {
      value = var.cloudflare_email
    }
  ]
}

# Creates a reusable Access policy.
resource "cloudflare_zero_trust_access_policy" "allow_policy" {
  account_id   = var.cloudflare_account_id
  name         = "Policy for private website"
  decision     = "allow"
  include      = [ # include means OR if there are multiple conditions, so user must match one of the conditions
    {
      email_list = {
        id = cloudflare_zero_trust_list.allowed_emails.id
      }
    }
  ]
  exclude      = [
    {
      geo = {
        country_code = "RU"
      }
    }
  ]
}

# Creates an Access application to control who can connect to the public hostname.
resource "cloudflare_zero_trust_access_application" "http_app" {
  account_id       = var.cloudflare_account_id
  type             = "self_hosted"
  name             = "http_app.${var.cloudflare_zone}"
  domain           = "http_app.${var.cloudflare_zone}"
  policies = [
    {
      id = cloudflare_zero_trust_access_policy.allow_policy.id
      precedence = 1
    }
  ]
}
