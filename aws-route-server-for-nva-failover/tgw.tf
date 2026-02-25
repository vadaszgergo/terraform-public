resource "aws_ec2_transit_gateway" "main" {
  description = "hub-workload-tgw"

  default_route_table_association = "disable"
  default_route_table_propagation = "disable"

  tags = {
    Name = "main-tgw"
  }
}

resource "aws_ec2_transit_gateway_route_table" "main" {
  transit_gateway_id = aws_ec2_transit_gateway.main.id

  tags = {
    Name = "main-tgw-rt"
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "hub" {
  subnet_ids         = [aws_subnet.hub_private_subnet01.id, aws_subnet.hub_private_subnet02.id]
  transit_gateway_id = aws_ec2_transit_gateway.main.id
  vpc_id             = aws_vpc.hub.id

  tags = {
    Name = "tgw-attach-hub"
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "workload" {
  subnet_ids         = [aws_subnet.workload_subnet.id]
  transit_gateway_id = aws_ec2_transit_gateway.main.id
  vpc_id             = aws_vpc.workload.id

  tags = {
    Name = "tgw-attach-workload"
  }
}

resource "aws_ec2_transit_gateway_route_table_association" "hub" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.hub.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.main.id
}

resource "aws_ec2_transit_gateway_route_table_association" "workload" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.workload.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.main.id
}

resource "aws_ec2_transit_gateway_route" "default_to_hub" {
  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.hub.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.main.id
}

resource "aws_ec2_transit_gateway_route" "hub_vpc_cidr" {
  destination_cidr_block         = local.hub_vpc_cidr
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.hub.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.main.id
}

resource "aws_ec2_transit_gateway_route" "workload_vpc_cidr" {
  destination_cidr_block         = local.workload_vpc_cidr
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.workload.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.main.id
}
