# Cloud Infrastructure Examples

Collection of infrastructure-as-code examples using Terraform for AWS and Azure cloud platforms.

## AWS Examples

### [EC2 NAT Instance](aws-ec2-nat-instance/)
Cost-effective NAT solution using EC2 instance instead of AWS NAT Gateway.

### [Multi-Region Hub-Spoke with Transit Gateways](aws-multi-region-hub-spoke-with-transit-gateways/)
Multi-region network architecture using Transit Gateways for centralized routing.

## Azure Examples

### [Free App Service with Docker](azure-free-app-service-with-docker/)
Deploys a containerized application using Azure's free-tier App Service.

### [Route Server with NVA Peering](azure-route-server-peering-nva/)
Hub-spoke network with Azure Route Server and Network Virtual Appliance (NVA) for BGP routing.

## Usage

Each folder contains:
- Complete Terraform configurations
- Detailed README with setup instructions
- Architecture diagrams (where applicable)

## Prerequisites

- AWS/Azure account
- Terraform >= 1.0
- AWS CLI or Azure CLI
- Basic cloud networking knowledge

## Note
These configurations may create cloud resources that incur costs. Remember to destroy resources after testing.
