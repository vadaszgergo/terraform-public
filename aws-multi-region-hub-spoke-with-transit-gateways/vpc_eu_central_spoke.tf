# EU Central Spoke VPC
resource "aws_vpc" "eu_spoke_vpc" {
  provider             = aws.eu_central
  cidr_block          = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "EU-Central-Spoke-VPC"
  }
}

# EU Spoke Subnets
resource "aws_subnet" "eu_spoke_private_1a" {
  provider          = aws.eu_central
  vpc_id            = aws_vpc.eu_spoke_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "eu-central-1a"

  tags = {
    Name = "EU-Spoke-Private-1a"
  }
}

resource "aws_subnet" "eu_spoke_private_1b" {
  provider          = aws.eu_central
  vpc_id            = aws_vpc.eu_spoke_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "eu-central-1b"

  tags = {
    Name = "EU-Spoke-Private-1b"
  }
}

resource "aws_subnet" "eu_spoke_public_1a" {
  provider                = aws.eu_central
  vpc_id                 = aws_vpc.eu_spoke_vpc.id
  cidr_block             = "10.0.3.0/24"
  availability_zone      = "eu-central-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "EU-Spoke-Public-1a"
  }
}

resource "aws_subnet" "eu_spoke_public_1b" {
  provider                = aws.eu_central
  vpc_id                 = aws_vpc.eu_spoke_vpc.id
  cidr_block             = "10.0.4.0/24"
  availability_zone      = "eu-central-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "EU-Spoke-Public-1b"
  }
}

# EU Spoke Route Tables
resource "aws_route_table" "eu_spoke_public" {
  provider = aws.eu_central
  vpc_id   = aws_vpc.eu_spoke_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.eu_spoke_igw.id
  }

  route {
    cidr_block         = "192.168.0.0/16"  # US Spoke VPC CIDR
    transit_gateway_id = aws_ec2_transit_gateway.eu_spoke_tgw.id
  }

  tags = {
    Name = "EU-Spoke-Public-RT"
  }
}

resource "aws_route_table" "eu_spoke_private" {
  provider = aws.eu_central
  vpc_id   = aws_vpc.eu_spoke_vpc.id

  route {
    cidr_block         = "0.0.0.0/0"
    transit_gateway_id = aws_ec2_transit_gateway.eu_spoke_tgw.id
  }

  route {
    cidr_block         = "192.168.0.0/16"  # US Spoke VPC CIDR
    transit_gateway_id = aws_ec2_transit_gateway.eu_spoke_tgw.id
  }

  tags = {
    Name = "EU-Spoke-Private-RT"
  }
}

# EU Spoke Internet Gateway
resource "aws_internet_gateway" "eu_spoke_igw" {
  provider = aws.eu_central
  vpc_id   = aws_vpc.eu_spoke_vpc.id

  tags = {
    Name = "EU-Spoke-IGW"
  }
}

# EU Spoke Route Table Associations
resource "aws_route_table_association" "eu_spoke_private_1a" {
  provider       = aws.eu_central
  subnet_id      = aws_subnet.eu_spoke_private_1a.id
  route_table_id = aws_route_table.eu_spoke_private.id
}

resource "aws_route_table_association" "eu_spoke_private_1b" {
  provider       = aws.eu_central
  subnet_id      = aws_subnet.eu_spoke_private_1b.id
  route_table_id = aws_route_table.eu_spoke_private.id
}

resource "aws_route_table_association" "eu_spoke_public_1a" {
  provider       = aws.eu_central
  subnet_id      = aws_subnet.eu_spoke_public_1a.id
  route_table_id = aws_route_table.eu_spoke_public.id
}

resource "aws_route_table_association" "eu_spoke_public_1b" {
  provider       = aws.eu_central
  subnet_id      = aws_subnet.eu_spoke_public_1b.id
  route_table_id = aws_route_table.eu_spoke_public.id
}

