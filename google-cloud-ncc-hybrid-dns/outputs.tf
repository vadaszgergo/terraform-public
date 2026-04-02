output "dns_vm_ip" {
  description = "DNS VM internal IP (IPAM grid member)"
  value       = google_compute_instance.dns.network_interface[0].network_ip
}

output "sdwan_vm_infra_ip" {
  description = "SD-WAN VM IP in Infra VPC"
  value       = google_compute_instance.sdwan.network_interface[0].network_ip
}

output "sdwan_vm_onprem_ip" {
  description = "SD-WAN VM IP in On-Prem VPC"
  value       = google_compute_instance.sdwan.network_interface[1].network_ip
}

output "app_vm_ip" {
  description = "Application VM IP"
  value       = google_compute_instance.app.network_interface[0].network_ip
}

output "onprem_dns_ip" {
  description = "On-Prem DNS VM IP"
  value       = google_compute_instance.onprem_dns.network_interface[0].network_ip
}

output "test_instructions" {
  description = "Step-by-step testing guide"
  value       = <<-EOT

    ====================================================================
    Test DNS Resolution (Full IPAM Model)
    ====================================================================

    Wait 2-3 minutes after apply for startup scripts to complete.

    In this model, Cloud DNS has NO private zones. The DNS VM (IPAM)
    is authoritative for gcp.example.com and forwards on-prem.example.com
    to the on-prem DNS server. All queries flow through the DNS VM.

    --- Test 1: GCP -> On-Prem (from App VM) ---

    gcloud compute ssh app-vm --zone=${var.zone} --tunnel-through-iap

    # These should resolve to 192.168.1.x IPs:
    dig app1.on-prem.example.com
    dig db1.on-prem.example.com
    dig web1.on-prem.example.com

    --- Test 2: GCP -> GCP (from App VM) ---

    # Still on app-vm — these now go through the DNS VM (IPAM),
    # NOT through a Cloud DNS private zone:
    dig app-server.gcp.example.com    # Expected: 10.0.2.10
    dig dns-server.gcp.example.com    # Expected: 10.0.1.10

    --- Test 3: On-Prem -> GCP (from On-Prem DNS VM) ---

    gcloud compute ssh onprem-dns-vm --zone=${var.zone} --tunnel-through-iap

    # These should resolve to 10.0.x.x IPs:
    dig app-server.gcp.example.com @localhost
    dig dns-server.gcp.example.com @localhost

    --- Test 4: Verify BGP (from SD-WAN VM) ---

    gcloud compute ssh sdwan-vm --zone=${var.zone} --tunnel-through-iap

    sudo vtysh -c "show bgp summary"
    sudo vtysh -c "show ip bgp"

    --- Test 5: Verify IPAM is authoritative (from DNS VM) ---

    gcloud compute ssh dns-vm --zone=${var.zone} --tunnel-through-iap

    # GCP zone - resolved locally (authoritative):
    dig app-server.gcp.example.com @localhost

    # On-prem zone - forwarded to on-prem DNS:
    dig app1.on-prem.example.com @localhost

    ====================================================================
    DNS Flow Diagram (Full IPAM Model)
    ====================================================================

    GCP -> GCP (gcp.example.com):
      App VM -> Cloud DNS (169.254.169.254)
        -> peering (app-vpc -> infra-vpc)
        -> forwarding (infra-vpc -> DNS VM 10.0.1.10)
        -> DNS VM resolves locally (authoritative)

    GCP -> On-Prem (on-prem.example.com):
      App VM -> Cloud DNS (169.254.169.254)
        -> peering (app-vpc -> infra-vpc)
        -> forwarding (infra-vpc -> DNS VM 10.0.1.10)
        -> DNS VM forwards to on-prem DNS (192.168.1.10)
        -> via SD-WAN VM (NCC router appliance BGP)

    On-Prem -> GCP (gcp.example.com):
      On-prem DNS (192.168.1.10)
        -> forwards gcp.example.com to DNS VM (10.0.1.10)
        -> via SD-WAN VM
        -> DNS VM resolves locally (authoritative)

  EOT
}
