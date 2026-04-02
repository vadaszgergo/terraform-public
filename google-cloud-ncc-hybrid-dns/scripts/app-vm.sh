#!/bin/bash
set -e

apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y dnsutils

echo "App VM setup complete"
