# =============================================================================
# Cloud DNS - Full IPAM model
#
# Simulates an enterprise setup where the organization's IPAM solution
# (Infoblox, EfficientIP, BlueCat, etc.) is the single source of truth for
# ALL DNS zones — including GCP-hosted workloads. Cloud DNS is used only as
# a forwarding/peering layer to route queries to the DNS VM (IPAM grid member).
#
# DNS chain (GCP -> On-Prem, e.g. app1.on-prem.example.com):
#   App VM -> Cloud DNS (169.254.169.254)
#   -> peering (app VPC -> infra VPC)
#   -> forwarding (infra VPC -> DNS VM / IPAM)
#   -> BIND forwards to on-prem DNS (192.168.1.10)
#
# DNS chain (GCP -> GCP, e.g. app-server.gcp.example.com):
#   App VM -> Cloud DNS (169.254.169.254)
#   -> peering (app VPC -> infra VPC)
#   -> forwarding (infra VPC -> DNS VM / IPAM)
#   -> BIND resolves locally (authoritative for gcp.example.com)
#
# DNS chain (On-Prem -> GCP, e.g. app-server.gcp.example.com):
#   On-prem DNS -> forwards to DNS VM (10.0.1.10) via SD-WAN
#   -> BIND resolves locally (authoritative for gcp.example.com)
#
# In this model, Cloud DNS has NO private zones — it only peers and forwards.
# The DNS VM (IPAM) is authoritative for gcp.example.com and forwards
# on-prem.example.com to the on-prem DNS server.
#
# Why peering + forwarding instead of direct forwarding from App VPC?
#
#   Cross-VPC forwarding doesn't work with NCC spokes (or VPC peering).
#   Cloud DNS forwarding uses 35.199.192.0/19 as the source IP. This range
#   has a special non-removable route in every VPC that points back to that
#   VPC's own Cloud DNS context. If App VPC forwards to the DNS VM in Infra
#   VPC, the response to 35.199.192.0/19 gets routed to Infra VPC's Cloud
#   DNS — not back to App VPC's Cloud DNS which originated the query.
#   DNS peering avoids this because it delegates resolution to the target
#   VPC's DNS context (metadata-plane), so the forwarding happens entirely
#   within the Infra VPC where the return path is correct.
#   Ref: https://cloud.google.com/vpc/docs/routes#cloud-dns
#   Ref: https://cloud.google.com/dns/docs/zones/forwarding-zones
# =============================================================================

# -----------------------------------------------------------------------------
# DNS Peering: App VPC -> Infra VPC (for on-prem.example.com)
# -----------------------------------------------------------------------------
resource "google_dns_managed_zone" "onprem_peering" {
  name        = "onprem-dns-peering"
  dns_name    = "on-prem.example.com."
  description = "Peers on-prem.example.com queries from App VPC to Infra VPC"
  visibility  = "private"

  private_visibility_config {
    networks {
      network_url = google_compute_network.app.id
    }
  }

  peering_config {
    target_network {
      network_url = google_compute_network.infra.id
    }
  }
}

# -----------------------------------------------------------------------------
# DNS Peering: App VPC -> Infra VPC (for gcp.example.com)
#
# Same pattern as on-prem.example.com. In the full IPAM model, Cloud DNS
# does not host any authoritative zones — all queries are forwarded to the
# DNS VM (IPAM grid member). App VPC peers to Infra VPC, which forwards
# to the DNS VM.
# -----------------------------------------------------------------------------
resource "google_dns_managed_zone" "gcp_peering" {
  name        = "gcp-dns-peering"
  dns_name    = "gcp.example.com."
  description = "Peers gcp.example.com queries from App VPC to Infra VPC"
  visibility  = "private"

  private_visibility_config {
    networks {
      network_url = google_compute_network.app.id
    }
  }

  peering_config {
    target_network {
      network_url = google_compute_network.infra.id
    }
  }
}

# -----------------------------------------------------------------------------
# DNS Forwarding: Infra VPC -> DNS VM (for on-prem.example.com)
#
# Cloud DNS in the Infra VPC forwards on-prem.example.com queries to the
# DNS VM (IPAM). The DNS VM then forwards to the on-prem DNS server using
# its own private IP (10.0.1.10).
# -----------------------------------------------------------------------------
resource "google_dns_managed_zone" "onprem_forwarding" {
  name        = "onprem-dns-forwarding"
  dns_name    = "on-prem.example.com."
  description = "Forwards on-prem.example.com queries to DNS VM (IPAM)"
  visibility  = "private"

  private_visibility_config {
    networks {
      network_url = google_compute_network.infra.id
    }
  }

  forwarding_config {
    target_name_servers {
      ipv4_address    = var.dns_vm_ip
      forwarding_path = "private"
    }
  }
}

# -----------------------------------------------------------------------------
# DNS Forwarding: Infra VPC -> DNS VM (for gcp.example.com)
#
# Cloud DNS forwards GCP zone queries to the DNS VM (IPAM), which is
# authoritative for gcp.example.com. This replaces the Cloud DNS private
# zone — the IPAM is the single source of truth for all DNS records.
# -----------------------------------------------------------------------------
resource "google_dns_managed_zone" "gcp_forwarding" {
  name        = "gcp-dns-forwarding"
  dns_name    = "gcp.example.com."
  description = "Forwards gcp.example.com queries to DNS VM (IPAM)"
  visibility  = "private"

  private_visibility_config {
    networks {
      network_url = google_compute_network.infra.id
    }
  }

  forwarding_config {
    target_name_servers {
      ipv4_address    = var.dns_vm_ip
      forwarding_path = "private"
    }
  }
}
