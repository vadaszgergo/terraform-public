# EU Central Spoke Transit Gateway
resource "aws_ec2_transit_gateway" "eu_spoke_tgw" {
  provider    = aws.eu_central
  description = "Transit Gateway for EU Central Spoke region"
  
  amazon_side_asn = 64512

  tags = {
    Name = "EU-Spoke-Transit-Gateway"
  }
}

# EU Central Spoke VPC Attachment
resource "aws_ec2_transit_gateway_vpc_attachment" "eu_spoke_vpc_attachment" {
  provider           = aws.eu_central
  subnet_ids         = [aws_subnet.eu_spoke_private_1a.id, aws_subnet.eu_spoke_private_1b.id]
  transit_gateway_id = aws_ec2_transit_gateway.eu_spoke_tgw.id
  vpc_id             = aws_vpc.eu_spoke_vpc.id

  tags = {
    Name = "EU-Spoke-VPC-TGW-Attachment"
  }
}

# US East Spoke Transit Gateway
resource "aws_ec2_transit_gateway" "us_spoke_tgw" {
  provider    = aws.us_east
  description = "Transit Gateway for US East Spoke region"
  
  amazon_side_asn = 64513

  tags = {
    Name = "US-Spoke-Transit-Gateway"
  }
}

# US East Spoke VPC Attachment
resource "aws_ec2_transit_gateway_vpc_attachment" "us_spoke_vpc_attachment" {
  provider           = aws.us_east
  subnet_ids         = [aws_subnet.us_spoke_private_1a.id, aws_subnet.us_spoke_private_1b.id]
  transit_gateway_id = aws_ec2_transit_gateway.us_spoke_tgw.id
  vpc_id             = aws_vpc.us_spoke_vpc.id

  tags = {
    Name = "US-Spoke-VPC-TGW-Attachment"
  }
}

# HUB Transit Gateway
resource "aws_ec2_transit_gateway" "hub_tgw" {
  provider    = aws.eu_west
  description = "Transit Gateway for EU West HUB region"
  
  amazon_side_asn = 64514

  tags = {
    Name = "HUB-Transit-Gateway"
  }
}

# HUB VPC Attachment
resource "aws_ec2_transit_gateway_vpc_attachment" "hub_vpc_attachment" {
  provider           = aws.eu_west
  subnet_ids         = [aws_subnet.hub_private_1a.id, aws_subnet.hub_private_1b.id]
  transit_gateway_id = aws_ec2_transit_gateway.hub_tgw.id
  vpc_id             = aws_vpc.hub_vpc.id

  tags = {
    Name = "HUB-VPC-TGW-Attachment"
  }
}

# Create peering attachment from HUB to EU Spoke
resource "aws_ec2_transit_gateway_peering_attachment" "hub_to_eu_spoke" {
  provider                = aws.eu_west
  peer_account_id        = aws_ec2_transit_gateway.eu_spoke_tgw.owner_id
  peer_region            = "eu-central-1"
  peer_transit_gateway_id = aws_ec2_transit_gateway.eu_spoke_tgw.id
  transit_gateway_id     = aws_ec2_transit_gateway.hub_tgw.id

  tags = {
    Name = "HUB-to-EU-Spoke-Peering"
  }
}

# Accept the peering attachment in EU Central
resource "aws_ec2_transit_gateway_peering_attachment_accepter" "eu_spoke_accepter" {
  provider                      = aws.eu_central
  transit_gateway_attachment_id = aws_ec2_transit_gateway_peering_attachment.hub_to_eu_spoke.id

  tags = {
    Name = "EU-Spoke-Accepter"
  }
}

# Create peering attachment from HUB to US Spoke
resource "aws_ec2_transit_gateway_peering_attachment" "hub_to_us_spoke" {
  provider                = aws.eu_west
  peer_account_id        = aws_ec2_transit_gateway.us_spoke_tgw.owner_id
  peer_region            = "us-east-1"
  peer_transit_gateway_id = aws_ec2_transit_gateway.us_spoke_tgw.id
  transit_gateway_id     = aws_ec2_transit_gateway.hub_tgw.id

  tags = {
    Name = "HUB-to-US-Spoke-Peering"
  }
}

# Accept the peering attachment in US East
resource "aws_ec2_transit_gateway_peering_attachment_accepter" "us_spoke_accepter" {
  provider                      = aws.us_east
  transit_gateway_attachment_id = aws_ec2_transit_gateway_peering_attachment.hub_to_us_spoke.id

  tags = {
    Name = "US-Spoke-Accepter"
  }
}

# Add routes in the Transit Gateways
resource "aws_ec2_transit_gateway_route" "hub_to_eu_spoke" {
  provider                       = aws.eu_west
  destination_cidr_block        = "10.0.0.0/16"  # EU Spoke VPC CIDR
  transit_gateway_attachment_id = aws_ec2_transit_gateway_peering_attachment.hub_to_eu_spoke.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway.hub_tgw.association_default_route_table_id

  depends_on = [
    aws_ec2_transit_gateway_peering_attachment_accepter.eu_spoke_accepter
  ]
}

resource "aws_ec2_transit_gateway_route" "hub_to_us_spoke" {
  provider                       = aws.eu_west
  destination_cidr_block        = "192.168.0.0/16"  # US Spoke VPC CIDR
  transit_gateway_attachment_id = aws_ec2_transit_gateway_peering_attachment.hub_to_us_spoke.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway.hub_tgw.association_default_route_table_id

  depends_on = [
    aws_ec2_transit_gateway_peering_attachment_accepter.us_spoke_accepter
  ]
}

resource "aws_ec2_transit_gateway_route" "eu_spoke_to_hub" {
  provider                       = aws.eu_central
  destination_cidr_block        = "172.31.0.0/16"  # HUB VPC CIDR
  transit_gateway_attachment_id = aws_ec2_transit_gateway_peering_attachment.hub_to_eu_spoke.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway.eu_spoke_tgw.association_default_route_table_id

  depends_on = [
    aws_ec2_transit_gateway_peering_attachment_accepter.eu_spoke_accepter
  ]
}

resource "aws_ec2_transit_gateway_route" "us_spoke_to_hub" {
  provider                       = aws.us_east
  destination_cidr_block        = "172.31.0.0/16"  # HUB VPC CIDR
  transit_gateway_attachment_id = aws_ec2_transit_gateway_peering_attachment.hub_to_us_spoke.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway.us_spoke_tgw.association_default_route_table_id

  depends_on = [
    aws_ec2_transit_gateway_peering_attachment_accepter.us_spoke_accepter
  ]
}

# Add default route in EU Spoke TGW to route internet traffic through HUB
resource "aws_ec2_transit_gateway_route" "eu_spoke_to_internet" {
  provider                       = aws.eu_central
  destination_cidr_block        = "0.0.0.0/0"
  transit_gateway_attachment_id = aws_ec2_transit_gateway_peering_attachment.hub_to_eu_spoke.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway.eu_spoke_tgw.association_default_route_table_id

  depends_on = [
    aws_ec2_transit_gateway_peering_attachment_accepter.eu_spoke_accepter
  ]
}

# Add default route in US Spoke TGW to route internet traffic through HUB
resource "aws_ec2_transit_gateway_route" "us_spoke_to_internet" {
  provider                       = aws.us_east
  destination_cidr_block        = "0.0.0.0/0"
  transit_gateway_attachment_id = aws_ec2_transit_gateway_peering_attachment.hub_to_us_spoke.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway.us_spoke_tgw.association_default_route_table_id

  depends_on = [
    aws_ec2_transit_gateway_peering_attachment_accepter.us_spoke_accepter
  ]
}

# Add default route in HUB TGW to route internet traffic through HUB VPC NAT Gateways
resource "aws_ec2_transit_gateway_route" "hub_to_internet" {
  provider                       = aws.eu_west
  destination_cidr_block        = "0.0.0.0/0"
  transit_gateway_attachment_id = aws_ec2_transit_gateway_vpc_attachment.hub_vpc_attachment.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway.hub_tgw.association_default_route_table_id

  depends_on = [
    aws_ec2_transit_gateway_vpc_attachment.hub_vpc_attachment
  ]
} 