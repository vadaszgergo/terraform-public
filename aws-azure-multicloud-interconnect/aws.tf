############################
# VPC, subnet and internet access
############################

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "vpc" {
  cidr_block           = local.aws_vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.prefix}-vpc"
  }
}

resource "aws_subnet" "vm" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = local.aws_subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.prefix}-vm-subnet"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.prefix}-igw"
  }
}

resource "aws_route_table" "vm" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.prefix}-vm-rt"
  }
}

resource "aws_route_table_association" "vm" {
  subnet_id      = aws_subnet.vm.id
  route_table_id = aws_route_table.vm.id
}

############################
# Security group: SSH from my IP, everything from the Azure VNET
############################

resource "aws_security_group" "vm" {
  name        = "${var.prefix}-vm-sg"
  description = "SSH from my IP, all traffic from the Azure VNET"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ssh_source_cidr]
  }

  ingress {
    description = "All traffic from the Azure VNET"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [local.azure_vnet_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.prefix}-vm-sg"
  }
}

############################
# Ubuntu VM
############################

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_key_pair" "vm" {
  key_name   = "${var.prefix}-key"
  public_key = file(pathexpand(var.ssh_public_key_path))
}

resource "aws_instance" "vm" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.aws_instance_type
  subnet_id              = aws_subnet.vm.id
  vpc_security_group_ids = [aws_security_group.vm.id]
  key_name               = aws_key_pair.vm.key_name

  tags = {
    Name = "${var.prefix}-aws-vm"
  }

  lifecycle {
    # Don't replace the VM just because Canonical published a newer AMI
    ignore_changes = [ami]
  }
}
