# On-Prem Destination Server

A simple Python HTTP server that displays connection information, showing the source IP from Cloud Run and the destination server's IP address.

## Usage

Run the server on the destination (on-prem) machine:

```bash
python3 destination-server.py
```

The server listens on port 80 and returns an HTML page showing:
- Cloud Run source IP (the IP address of the incoming request)
- Destination server IP (the private IP of this server)
- Port number

This allows you to verify the VPN connectivity path from Cloud Run through the VPC and VPN tunnel to the on-premises server.

