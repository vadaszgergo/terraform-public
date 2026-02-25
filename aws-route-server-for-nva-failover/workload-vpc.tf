resource "aws_vpc" "workload" {
  cidr_block           = local.workload_vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "workload-vpc"
  }
}

resource "aws_subnet" "workload_subnet" {
  vpc_id     = aws_vpc.workload.id
  cidr_block = "192.168.0.0/24"

  tags = {
    Name = "workload-subnet"
  }
}

resource "aws_route_table" "workload" {
  vpc_id = aws_vpc.workload.id

  route {
    cidr_block         = "0.0.0.0/0"
    transit_gateway_id = aws_ec2_transit_gateway.main.id
  }

  tags = {
    Name = "workload-rt"
  }
}

resource "aws_route_table_association" "workload" {
  subnet_id      = aws_subnet.workload_subnet.id
  route_table_id = aws_route_table.workload.id
}
