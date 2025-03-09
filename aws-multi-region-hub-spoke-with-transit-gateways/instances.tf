# Ubuntu server in EU Spoke public subnet
resource "aws_instance" "eu_spoke_public" {
  provider               = aws.eu_central
  ami                   = "ami-04e601abe3e1a910f"  # Ubuntu 22.04 LTS in eu-central-1
  instance_type         = "t2.micro"
  subnet_id             = aws_subnet.eu_spoke_public_1a.id
  key_name             = "aws-key"
  associate_public_ip_address = true
  
  vpc_security_group_ids = [aws_security_group.eu_spoke_sg.id]

  tags = {
    Name = "EU-Spoke-Public-Server"
  }
}

# Ubuntu server in US Spoke private subnet
resource "aws_instance" "us_spoke_private" {
  provider               = aws.us_east
  ami                   = "ami-0c7217cdde317cfec"  # Ubuntu 22.04 LTS in us-east-1
  instance_type         = "t2.micro"
  subnet_id             = aws_subnet.us_spoke_private_1a.id
  key_name             = "test"
  
  vpc_security_group_ids = [aws_security_group.us_spoke_sg.id]

  tags = {
    Name = "US-Spoke-Private-Server"
  }
}

# Security Group for EU Spoke instances
resource "aws_security_group" "eu_spoke_sg" {
  provider    = aws.eu_central
  name        = "eu-spoke-sg"
  description = "Security group for EU spoke servers"
  vpc_id      = aws_vpc.eu_spoke_vpc.id

  # SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ICMP (ping) from all VPCs
  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["10.0.0.0/16", "192.168.0.0/16", "172.31.0.0/16"]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "EU-Spoke-SG"
  }
}

# Security Group for US Spoke instances
resource "aws_security_group" "us_spoke_sg" {
  provider    = aws.us_east
  name        = "us-spoke-sg"
  description = "Security group for US spoke servers"
  vpc_id      = aws_vpc.us_spoke_vpc.id

  # SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ICMP (ping) from all VPCs
  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["10.0.0.0/16", "192.168.0.0/16", "172.31.0.0/16"]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "US-Spoke-SG"
  }
} 