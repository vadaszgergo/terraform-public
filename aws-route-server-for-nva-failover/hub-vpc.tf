resource "aws_vpc" "hub" {
  cidr_block           = local.hub_vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "hub-vpc"
  }
}

resource "aws_subnet" "nva_subnet01" {
  vpc_id                  = aws_vpc.hub.id
  cidr_block              = "10.0.0.0/24"
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "nva-subnet01-public"
  }
}

resource "aws_subnet" "nva_subnet02" {
  vpc_id                  = aws_vpc.hub.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "nva-subnet02-public"
  }
}

resource "aws_subnet" "hub_private_subnet01" {
  vpc_id            = aws_vpc.hub.id
  cidr_block        = "10.0.10.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "hub-private-subnet01"
  }
}

resource "aws_subnet" "hub_private_subnet02" {
  vpc_id            = aws_vpc.hub.id
  cidr_block        = "10.0.11.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "hub-private-subnet02"
  }
}

resource "aws_internet_gateway" "hub" {
  vpc_id = aws_vpc.hub.id

  tags = {
    Name = "hub-igw"
  }
}

resource "aws_route_table" "hub_nva_public" {
  vpc_id = aws_vpc.hub.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.hub.id
  }

  tags = {
    Name = "hub-nva-public-rt"
  }
}

resource "aws_route" "hub_public_to_workload_via_tgw" {
  route_table_id         = aws_route_table.hub_nva_public.id
  destination_cidr_block = local.workload_vpc_cidr
  transit_gateway_id     = aws_ec2_transit_gateway.main.id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.hub]
}

resource "aws_route_table_association" "hub_nva_subnet01" {
  subnet_id      = aws_subnet.nva_subnet01.id
  route_table_id = aws_route_table.hub_nva_public.id
}

resource "aws_route_table_association" "hub_nva_subnet02" {
  subnet_id      = aws_subnet.nva_subnet02.id
  route_table_id = aws_route_table.hub_nva_public.id
}

resource "aws_route_table" "hub_private_tgw" {
  vpc_id = aws_vpc.hub.id

  tags = {
    Name = "hub-private-tgw-rt"
  }
}

resource "aws_route_table_association" "hub_private_subnet01" {
  subnet_id      = aws_subnet.hub_private_subnet01.id
  route_table_id = aws_route_table.hub_private_tgw.id
}

resource "aws_route_table_association" "hub_private_subnet02" {
  subnet_id      = aws_subnet.hub_private_subnet02.id
  route_table_id = aws_route_table.hub_private_tgw.id
}
