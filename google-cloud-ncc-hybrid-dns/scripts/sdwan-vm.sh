#!/bin/bash
set -e

# Enable IP forwarding at the OS level
sysctl -w net.ipv4.ip_forward=1
cat > /etc/sysctl.d/99-ip-forward.conf <<'EOF'
net.ipv4.ip_forward = 1
EOF

apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y frr

# Enable BGP daemon in FRR
sed -i 's/^bgpd=no/bgpd=yes/' /etc/frr/daemons

# FRR BGP configuration
# - Local ASN 64515 (SD-WAN / on-prem side)
# - Peers with NCC Cloud Router ASN 64514 at 10.0.1.100 and 10.0.1.101
# - Advertises the on-prem network (192.168.1.0/24) to NCC
cat > /etc/frr/frr.conf <<'EOF'
frr version 8.1
frr defaults traditional
hostname sdwan-vm
log syslog informational
!
router bgp 64515
 bgp router-id 10.0.1.20
 no bgp ebgp-requires-policy
 neighbor 10.0.1.100 remote-as 64514
 neighbor 10.0.1.101 remote-as 64514
 !
 address-family ipv4 unicast
  network 192.168.1.0/24
 exit-address-family
!
line vty
!
EOF

chown frr:frr /etc/frr/frr.conf

systemctl restart frr
systemctl enable frr

echo "SD-WAN VM (FRR/BGP) setup complete"
