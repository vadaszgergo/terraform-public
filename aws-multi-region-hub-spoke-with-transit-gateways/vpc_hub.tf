# HUB VPC in EU West
resource "aws_vpc" "hub_vpc" {
  provider             = aws.eu_west
  cidr_block          = "172.31.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "EU-West-HUB-VPC"
  }
}

# HUB Internet Gateway
resource "aws_internet_gateway" "hub_igw" {
  provider = aws.eu_west
  vpc_id   = aws_vpc.hub_vpc.id

  tags = {
    Name = "HUB-IGW"
  }
}

# HUB EIPs for NAT Gateways
resource "aws_eip" "hub_nat_1a" {
  provider = aws.eu_west
  domain   = "vpc"

  tags = {
    Name = "HUB-NAT-1a-EIP"
  }
}

resource "aws_eip" "hub_nat_1b" {
  provider = aws.eu_west
  domain   = "vpc"

  tags = {
    Name = "HUB-NAT-1b-EIP"
  }
}

# HUB NAT Gateways
resource "aws_nat_gateway" "hub_nat_1a" {
  provider      = aws.eu_west
  allocation_id = aws_eip.hub_nat_1a.id
  subnet_id     = aws_subnet.hub_public_1a.id

  tags = {
    Name = "HUB-NAT-1a"
  }
}

resource "aws_nat_gateway" "hub_nat_1b" {
  provider      = aws.eu_west
  allocation_id = aws_eip.hub_nat_1b.id
  subnet_id     = aws_subnet.hub_public_1b.id

  tags = {
    Name = "HUB-NAT-1b"
  }
}

# HUB Subnets
resource "aws_subnet" "hub_private_1a" {
  provider          = aws.eu_west
  vpc_id            = aws_vpc.hub_vpc.id
  cidr_block        = "172.31.1.0/24"
  availability_zone = "eu-west-1a"

  tags = {
    Name = "HUB-Private-1a"
  }
}

resource "aws_subnet" "hub_private_1b" {
  provider          = aws.eu_west
  vpc_id            = aws_vpc.hub_vpc.id
  cidr_block        = "172.31.2.0/24"
  availability_zone = "eu-west-1b"

  tags = {
    Name = "HUB-Private-1b"
  }
}

resource "aws_subnet" "hub_public_1a" {
  provider                = aws.eu_west
  vpc_id                 = aws_vpc.hub_vpc.id
  cidr_block             = "172.31.3.0/24"
  availability_zone      = "eu-west-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "HUB-Public-1a"
  }
}

resource "aws_subnet" "hub_public_1b" {
  provider                = aws.eu_west
  vpc_id                 = aws_vpc.hub_vpc.id
  cidr_block             = "172.31.4.0/24"
  availability_zone      = "eu-west-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "HUB-Public-1b"
  }
}

# HUB Route Tables
resource "aws_route_table" "hub_public" {
  provider = aws.eu_west
  vpc_id   = aws_vpc.hub_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.hub_igw.id
  }

  route {
    cidr_block         = "10.0.0.0/16"  # EU Spoke VPC CIDR
    transit_gateway_id = aws_ec2_transit_gateway.hub_tgw.id
  }

  route {
    cidr_block         = "192.168.0.0/16"  # US Spoke VPC CIDR
    transit_gateway_id = aws_ec2_transit_gateway.hub_tgw.id
  }

  tags = {
    Name = "HUB-Public-RT"
  }
}

# HUB Route Table Associations
resource "aws_route_table_association" "hub_private_1a" {
  provider       = aws.eu_west
  subnet_id      = aws_subnet.hub_private_1a.id
  route_table_id = aws_route_table.hub_private_1a.id
}

resource "aws_route_table_association" "hub_private_1b" {
  provider       = aws.eu_west
  subnet_id      = aws_subnet.hub_private_1b.id
  route_table_id = aws_route_table.hub_private_1b.id
}

resource "aws_route_table_association" "hub_public_1a" {
  provider       = aws.eu_west
  subnet_id      = aws_subnet.hub_public_1a.id
  route_table_id = aws_route_table.hub_public.id
}

resource "aws_route_table_association" "hub_public_1b" {
  provider       = aws.eu_west
  subnet_id      = aws_subnet.hub_public_1b.id
  route_table_id = aws_route_table.hub_public.id
}

resource "aws_route_table" "hub_private_1a" {
  provider = aws.eu_west
  vpc_id   = aws_vpc.hub_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.hub_nat_1a.id
  }

  route {
    cidr_block         = "10.0.0.0/16"  # EU Spoke VPC CIDR
    transit_gateway_id = aws_ec2_transit_gateway.hub_tgw.id
  }

  route {
    cidr_block         = "192.168.0.0/16"  # US Spoke VPC CIDR
    transit_gateway_id = aws_ec2_transit_gateway.hub_tgw.id
  }

  tags = {
    Name = "HUB-Private-RT-1a"
  }
}

resource "aws_route_table" "hub_private_1b" {
  provider = aws.eu_west
  vpc_id   = aws_vpc.hub_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.hub_nat_1b.id
  }

  route {
    cidr_block         = "10.0.0.0/16"  # EU Spoke VPC CIDR
    transit_gateway_id = aws_ec2_transit_gateway.hub_tgw.id
  }

  route {
    cidr_block         = "192.168.0.0/16"  # US Spoke VPC CIDR
    transit_gateway_id = aws_ec2_transit_gateway.hub_tgw.id
  }

  tags = {
    Name = "HUB-Private-RT-1b"
  }
} 
