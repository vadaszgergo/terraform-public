output "nva01_public_ip" {
  value = aws_instance.nva01.public_ip
}

output "nva02_public_ip" {
  value = aws_instance.nva02.public_ip
}

output "workload_private_ip" {
  value = aws_instance.workload.private_ip
}

output "route_server_id" {
  value = aws_vpc_route_server.hub.route_server_id
}

output "route_server_endpoint_subnet01_ip" {
  value = aws_vpc_route_server_endpoint.hub_private_subnet01.eni_address
}

output "route_server_endpoint_subnet02_ip" {
  value = aws_vpc_route_server_endpoint.hub_private_subnet02.eni_address
}

output "transit_gateway_id" {
  value = aws_ec2_transit_gateway.main.id
}
