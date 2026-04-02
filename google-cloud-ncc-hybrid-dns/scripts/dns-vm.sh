#!/bin/bash
set -e

apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y bind9 bind9-utils dnsutils

# BIND options - recursive resolver with specific zone forwards
cat > /etc/bind/named.conf.options <<'EOF'
options {
    directory "/var/cache/bind";
    listen-on { any; };
    allow-query { any; };
    dnssec-validation no;
    recursion yes;
    allow-recursion { any; };
    max-cache-ttl 0;
    max-ncache-ttl 0;
};
EOF

# Zone configuration - full IPAM model
# This VM simulates an IPAM grid member (Infoblox, EfficientIP, BlueCat, etc.)
# that is the single source of truth for ALL DNS zones:
#   - gcp.example.com: authoritative (master zone hosted here)
#   - on-prem.example.com: forwarded to on-prem DNS server
cat > /etc/bind/named.conf.local <<'EOF'
// Authoritative zone for GCP workloads.
// In production, this would be managed by the IPAM solution.
// All GCP VPCs forward gcp.example.com queries here via Cloud DNS
// forwarding zones, instead of using Cloud DNS private zones.
zone "gcp.example.com" {
    type master;
    file "/etc/bind/zones/db.gcp.example.com";
};

// Forward on-prem.example.com queries to the on-prem DNS server.
// Traffic goes via the SD-WAN VM (NCC router appliance) using this
// VM's private IP (10.0.1.10) as source - NOT a Google public range.
zone "on-prem.example.com" {
    type forward;
    forward only;
    forwarders { 192.168.1.10; };
};
EOF

mkdir -p /etc/bind/zones

# GCP zone - managed by the IPAM (this VM)
cat > /etc/bind/zones/db.gcp.example.com <<'EOF'
$TTL 300
@   IN  SOA ns1.gcp.example.com. admin.gcp.example.com. (
            2024010101  ; serial
            3600        ; refresh
            600         ; retry
            86400       ; expire
            300 )       ; minimum TTL

    IN  NS  ns1.gcp.example.com.

ns1         IN  A   10.0.1.10
app-server  IN  A   10.0.2.10
dns-server  IN  A   10.0.1.10
EOF

systemctl restart bind9
systemctl enable bind9

echo "DNS VM (BIND/IPAM) setup complete - authoritative for gcp.example.com"
