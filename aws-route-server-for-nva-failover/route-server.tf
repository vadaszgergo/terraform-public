resource "aws_vpc_route_server" "hub" {
  amazon_side_asn = local.route_server_hub_asn
  persist_routes  = "disable"

  tags = {
    Name = "hub-route-server"
  }
}

resource "aws_vpc_route_server_vpc_association" "hub" {
  route_server_id = aws_vpc_route_server.hub.route_server_id
  vpc_id          = aws_vpc.hub.id
}

resource "aws_vpc_route_server_propagation" "hub_private_tgw" {
  route_server_id = aws_vpc_route_server.hub.route_server_id
  route_table_id  = aws_route_table.hub_private_tgw.id

  depends_on = [
    aws_vpc_route_server_vpc_association.hub,
    aws_route_table_association.hub_private_subnet01,
    aws_route_table_association.hub_private_subnet02
  ]
}

resource "aws_vpc_route_server_endpoint" "hub_private_subnet01" {
  route_server_id = aws_vpc_route_server.hub.route_server_id
  subnet_id       = aws_subnet.hub_private_subnet01.id

  depends_on = [aws_vpc_route_server_vpc_association.hub]

  tags = {
    Name = "hub-rs-endpoint-private-subnet01"
  }
}

resource "aws_vpc_route_server_endpoint" "hub_private_subnet02" {
  route_server_id = aws_vpc_route_server.hub.route_server_id
  subnet_id       = aws_subnet.hub_private_subnet02.id

  depends_on = [aws_vpc_route_server_vpc_association.hub]

  tags = {
    Name = "hub-rs-endpoint-private-subnet02"
  }
}

resource "aws_security_group" "route_server_endpoint_hub" {
  name        = "hub-route-server-endpoint-sg"
  description = "Allow BGP and ICMP to route server endpoints"
  vpc_id      = aws_vpc.hub.id

  ingress {
    description = "BGP from hub vpc"
    from_port   = 179
    to_port     = 179
    protocol    = "tcp"
    cidr_blocks = [local.hub_vpc_cidr]
  }

  ingress {
    description = "ICMP from hub vpc"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [local.hub_vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "hub-route-server-endpoint-sg"
  }
}

resource "aws_network_interface_sg_attachment" "rs_endpoint_subnet01_sg" {
  security_group_id    = aws_security_group.route_server_endpoint_hub.id
  network_interface_id = aws_vpc_route_server_endpoint.hub_private_subnet01.eni_id
}

resource "aws_network_interface_sg_attachment" "rs_endpoint_subnet02_sg" {
  security_group_id    = aws_security_group.route_server_endpoint_hub.id
  network_interface_id = aws_vpc_route_server_endpoint.hub_private_subnet02.eni_id
}

resource "aws_vpc_route_server_peer" "nva01" {
  route_server_endpoint_id = aws_vpc_route_server_endpoint.hub_private_subnet01.route_server_endpoint_id
  peer_address             = aws_instance.nva01.private_ip

  bgp_options {
    peer_asn                = local.nva1_asn
    peer_liveness_detection = "bgp-keepalive"
  }

  tags = {
    Name = "peer-nva01"
  }
}

resource "aws_vpc_route_server_peer" "nva02" {
  route_server_endpoint_id = aws_vpc_route_server_endpoint.hub_private_subnet02.route_server_endpoint_id
  peer_address             = aws_instance.nva02.private_ip

  bgp_options {
    peer_asn                = local.nva2_asn
    peer_liveness_detection = "bgp-keepalive"
  }

  tags = {
    Name = "peer-nva02"
  }
}
