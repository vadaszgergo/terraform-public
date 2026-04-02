#!/bin/bash
set -e

apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y bind9 bind9-utils dnsutils

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

cat > /etc/bind/named.conf.local <<'EOF'
// Authoritative zone for on-prem - simulates corporate DNS/IPAM
zone "on-prem.example.com" {
    type master;
    file "/etc/bind/zones/db.on-prem.example.com";
};

// Forward GCP queries to the DNS VM in GCP (via SD-WAN path)
zone "gcp.example.com" {
    type forward;
    forward only;
    forwarders { 10.0.1.10; };
};
EOF

mkdir -p /etc/bind/zones

cat > /etc/bind/zones/db.on-prem.example.com <<'EOF'
$TTL 300
@   IN  SOA ns1.on-prem.example.com. admin.on-prem.example.com. (
            2024010101  ; serial
            3600        ; refresh
            600         ; retry
            86400       ; expire
            300 )       ; minimum TTL

    IN  NS  ns1.on-prem.example.com.

ns1     IN  A   192.168.1.10
app1    IN  A   192.168.1.50
db1     IN  A   192.168.1.51
web1    IN  A   192.168.1.52
mail    IN  A   192.168.1.53
EOF

systemctl restart bind9
systemctl enable bind9

echo "On-prem DNS VM (BIND) setup complete"
