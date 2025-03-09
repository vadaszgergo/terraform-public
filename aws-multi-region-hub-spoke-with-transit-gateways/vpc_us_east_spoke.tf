# US East Spoke VPC
resource "aws_vpc" "us_spoke_vpc" {
  provider             = aws.us_east
  cidr_block          = "192.168.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "US-East-Spoke-VPC"
  }
}

# US Spoke Subnets
resource "aws_subnet" "us_spoke_private_1a" {
  provider          = aws.us_east
  vpc_id            = aws_vpc.us_spoke_vpc.id
  cidr_block        = "192.168.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "US-Spoke-Private-1a"
  }
}

resource "aws_subnet" "us_spoke_private_1b" {
  provider          = aws.us_east
  vpc_id            = aws_vpc.us_spoke_vpc.id
  cidr_block        = "192.168.2.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "US-Spoke-Private-1b"
  }
}

# US Spoke Route Tables
resource "aws_route_table" "us_spoke_private" {
  provider = aws.us_east
  vpc_id   = aws_vpc.us_spoke_vpc.id

  route {
    cidr_block         = "0.0.0.0/0"
    transit_gateway_id = aws_ec2_transit_gateway.us_spoke_tgw.id
  }

  route {
    cidr_block         = "10.0.0.0/16"  # EU Spoke VPC CIDR
    transit_gateway_id = aws_ec2_transit_gateway.us_spoke_tgw.id
  }

  tags = {
    Name = "US-Spoke-Private-RT"
  }
}

# US Spoke Route Table Associations
resource "aws_route_table_association" "us_spoke_private_1a" {
  provider       = aws.us_east
  subnet_id      = aws_subnet.us_spoke_private_1a.id
  route_table_id = aws_route_table.us_spoke_private.id
}

resource "aws_route_table_association" "us_spoke_private_1b" {
  provider       = aws.us_east
  subnet_id      = aws_subnet.us_spoke_private_1b.id
  route_table_id = aws_route_table.us_spoke_private.id
} 