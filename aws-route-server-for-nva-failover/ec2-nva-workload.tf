# This will upload your public key to AWS and create a key pair named "route-server-lab-key". 
# Make sure to replace the path in the `file()` function with the actual path to your public key if it's different.
resource "aws_key_pair" "shared" {
  key_name   = "route-server-lab-key"
  public_key = file(pathexpand("~/.ssh/id_rsa.pub"))
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_security_group" "nva" {
  name        = "nva-sg"
  description = "NVA SSH and BGP"
  vpc_id      = aws_vpc.hub.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "BGP"
    from_port   = 179
    to_port     = 179
    protocol    = "tcp"
    cidr_blocks = [local.hub_vpc_cidr]
  }

  ingress {
    description = "Forwarded workload HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [local.workload_vpc_cidr]
  }

  ingress {
    description = "Forwarded workload HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [local.workload_vpc_cidr]
  }

  ingress {
    description = "ICMP"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "workload" {
  name        = "workload-sg"
  description = "Workload SSH"
  vpc_id      = aws_vpc.workload.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "ICMP"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "nva01" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.nano"
  subnet_id                   = aws_subnet.nva_subnet01.id
  key_name                    = aws_key_pair.shared.key_name
  vpc_security_group_ids      = [aws_security_group.nva.id]
  associate_public_ip_address = true
  source_dest_check           = false

  user_data = <<-EOT
    #!/bin/bash
    set -euxo pipefail

    export DEBIAN_FRONTEND=noninteractive
    apt-get update
    apt-get install -y frr frr-pythontools curl iptables-persistent

    sysctl -w net.ipv4.ip_forward=1
    grep -q '^net.ipv4.ip_forward=1' /etc/sysctl.conf || echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf
    sysctl -w net.ipv4.conf.all.rp_filter=0
    grep -q '^net.ipv4.conf.all.rp_filter=0' /etc/sysctl.conf || echo 'net.ipv4.conf.all.rp_filter=0' >> /etc/sysctl.conf
    sysctl -w net.ipv4.conf.default.rp_filter=0
    grep -q '^net.ipv4.conf.default.rp_filter=0' /etc/sysctl.conf || echo 'net.ipv4.conf.default.rp_filter=0' >> /etc/sysctl.conf

    WAN_IF=$(ip -o -4 route show to default | awk '{print $5}' | head -n1)
    iptables -t nat -A POSTROUTING -o $${WAN_IF} -j MASQUERADE
    iptables -A FORWARD -i $${WAN_IF} -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
    iptables -A FORWARD -o $${WAN_IF} -j ACCEPT
    netfilter-persistent save

    ROUTER_ID=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)

    cat > /etc/frr/daemons <<'DAEMONS'
    bgpd=yes
    zebra=yes
    DAEMONS

    cat > /etc/frr/frr.conf <<FRRCONF
    frr version 10.0
    frr defaults traditional
    hostname nva01
    service integrated-vtysh-config
    ip nht resolve-via-default

    ip prefix-list DEFAULT_ONLY seq 5 permit 0.0.0.0/0
    route-map RS-IN deny 10
    !
    route-map RS-OUT permit 10
      match ip address prefix-list DEFAULT_ONLY
      set metric 10
    !

    router bgp ${local.nva1_asn}
      bgp router-id $${ROUTER_ID}
      neighbor ${aws_vpc_route_server_endpoint.hub_private_subnet01.eni_address} remote-as ${local.route_server_hub_asn}
      neighbor ${aws_vpc_route_server_endpoint.hub_private_subnet01.eni_address} ebgp-multihop 2
      neighbor ${aws_vpc_route_server_endpoint.hub_private_subnet01.eni_address} disable-connected-check
      neighbor ${aws_vpc_route_server_endpoint.hub_private_subnet01.eni_address} timers 10 30
      network 0.0.0.0/0
      neighbor ${aws_vpc_route_server_endpoint.hub_private_subnet01.eni_address} route-map RS-IN in
      neighbor ${aws_vpc_route_server_endpoint.hub_private_subnet01.eni_address} route-map RS-OUT out
    !

    line vty
    FRRCONF

    chown frr:frr /etc/frr/frr.conf
    chmod 640 /etc/frr/frr.conf

    systemctl enable frr
    systemctl restart frr
  EOT

  depends_on = [aws_vpc_route_server_endpoint.hub_private_subnet01]

  tags = {
    Name = "nva01"
  }
}

resource "aws_instance" "nva02" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.nano"
  subnet_id                   = aws_subnet.nva_subnet02.id
  key_name                    = aws_key_pair.shared.key_name
  vpc_security_group_ids      = [aws_security_group.nva.id]
  associate_public_ip_address = true
  source_dest_check           = false

  user_data = <<-EOT
    #!/bin/bash
    set -euxo pipefail

    export DEBIAN_FRONTEND=noninteractive
    apt-get update
    apt-get install -y frr frr-pythontools curl iptables-persistent

    sysctl -w net.ipv4.ip_forward=1
    grep -q '^net.ipv4.ip_forward=1' /etc/sysctl.conf || echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf
    sysctl -w net.ipv4.conf.all.rp_filter=0
    grep -q '^net.ipv4.conf.all.rp_filter=0' /etc/sysctl.conf || echo 'net.ipv4.conf.all.rp_filter=0' >> /etc/sysctl.conf
    sysctl -w net.ipv4.conf.default.rp_filter=0
    grep -q '^net.ipv4.conf.default.rp_filter=0' /etc/sysctl.conf || echo 'net.ipv4.conf.default.rp_filter=0' >> /etc/sysctl.conf

    WAN_IF=$(ip -o -4 route show to default | awk '{print $5}' | head -n1)
    iptables -t nat -A POSTROUTING -o $${WAN_IF} -j MASQUERADE
    iptables -A FORWARD -i $${WAN_IF} -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
    iptables -A FORWARD -o $${WAN_IF} -j ACCEPT
    netfilter-persistent save

    ROUTER_ID=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)

    cat > /etc/frr/daemons <<'DAEMONS'
    bgpd=yes
    zebra=yes
    DAEMONS

    cat > /etc/frr/frr.conf <<FRRCONF
    frr version 10.0
    frr defaults traditional
    hostname nva02
    service integrated-vtysh-config
    ip nht resolve-via-default

    ip prefix-list DEFAULT_ONLY seq 5 permit 0.0.0.0/0
    route-map RS-IN deny 10
    !
    route-map RS-OUT permit 10
      match ip address prefix-list DEFAULT_ONLY
      set metric 100
    !

    router bgp ${local.nva2_asn}
      bgp router-id $${ROUTER_ID}
      neighbor ${aws_vpc_route_server_endpoint.hub_private_subnet02.eni_address} remote-as ${local.route_server_hub_asn}
      neighbor ${aws_vpc_route_server_endpoint.hub_private_subnet02.eni_address} ebgp-multihop 2
      neighbor ${aws_vpc_route_server_endpoint.hub_private_subnet02.eni_address} disable-connected-check
      neighbor ${aws_vpc_route_server_endpoint.hub_private_subnet02.eni_address} timers 10 30
      network 0.0.0.0/0
      neighbor ${aws_vpc_route_server_endpoint.hub_private_subnet02.eni_address} route-map RS-IN in
      neighbor ${aws_vpc_route_server_endpoint.hub_private_subnet02.eni_address} route-map RS-OUT out
    !

    line vty
    FRRCONF

    chown frr:frr /etc/frr/frr.conf
    chmod 640 /etc/frr/frr.conf

    systemctl enable frr
    systemctl restart frr
  EOT

  depends_on = [aws_vpc_route_server_endpoint.hub_private_subnet02]

  tags = {
    Name = "nva02"
  }
}

resource "aws_instance" "workload" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.nano"
  subnet_id              = aws_subnet.workload_subnet.id
  key_name               = aws_key_pair.shared.key_name
  vpc_security_group_ids = [aws_security_group.workload.id]

  tags = {
    Name = "workload01"
  }
}
