output "vpc_network_id" {
  description = "The ID of the VPC network"
  value       = google_compute_network.vpc.id
}

output "vpc_network_name" {
  description = "The name of the VPC network"
  value       = google_compute_network.vpc.name
}

output "subnet_id" {
  description = "The ID of the subnet"
  value       = google_compute_subnetwork.subnet.id
}

output "subnet_name" {
  description = "The name of the subnet"
  value       = google_compute_subnetwork.subnet.name
}


output "vpn_gateway_name" {
  description = "The name of the VPN gateway"
  value       = google_compute_vpn_gateway.vpn_gateway.name
}

output "vpn_gateway_ip" {
  description = "The IP address of the VPN gateway"
  value       = google_compute_address.vpn_gateway_ip.address
}

output "vpn_tunnel_name" {
  description = "The name of the VPN tunnel"
  value       = google_compute_vpn_tunnel.vpn_tunnel.name
}

output "vpn_shared_secret" {
  description = "The shared secret for the VPN tunnel"
  value       = var.shared_secret
  sensitive   = true
}

output "vpn_route_name" {
  description = "The name of the VPN route"
  value       = google_compute_route.vpn_route.name
}

output "vpn_route_dest_range" {
  description = "The destination range of the VPN route"
  value       = google_compute_route.vpn_route.dest_range
}

