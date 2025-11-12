# Cloudflare Zero Trust Web Application (Terraform)

This project provisions a demo web application on Google Cloud Platform and exposes it securely through Cloudflare Zero Trust using Terraform. It deploys an Ubuntu VM that installs Nginx and Cloudflared at boot, serves a simple greeting page, and publishes the instance behind a Cloudflare Tunnel with Access policies.

## Architecture
- **Compute**: Single `google_compute_instance` in a user-supplied VPC subnet. The startup script installs Nginx, replaces the default landing page, and launches `cloudflared` with a tunnel token.
- **Cloudflare Zero Trust**:
  - Creates a remotely-managed Cloudflared tunnel and retrieves the tunnel token.
  - Publishes a CNAME record (`http_app.<zone>`) pointing to the tunnel.
  - Configures the tunnel ingress to forward traffic.
  - Defines an Access policy and Access application controlling who can reach the hostname.
- **Networking**: Requires an existing VPC and subnet in the target project/region. The VM receives an ephemeral external IP.

## Prerequisites
- Terraform `>= 1.2.0`
- HashiCorp Google provider credentials (e.g., `gcloud auth application-default login`, service account JSON, or other supported auth)
- Cloudflare account with:
  - Zone already onboarded (DNS managed by Cloudflare)
  - API token with permissions: Zero Trust Tunnel, DNS:Edit, Access:Edit
- Existing GCP network + subnetwork (`gergo-vpc-01` in the example). Adjust values to match your environment.
- (Optional) `gcloud` CLI for validating networks/subnets.

## Configuration
Set the required variables before applying:

| Variable | Description |
| --- | --- |
| `gcp_project_id` | Target GCP project |
| `zone` | Compute Engine zone (e.g., `europe-west4-a`) |
| `machine_type` | Instance machine type (e.g., `e2-medium`) |
| `cloudflare_zone` | Root domain (e.g., `example.com`) |
| `cloudflare_zone_id` | Cloudflare zone ID |
| `cloudflare_account_id` | Cloudflare account ID |
| `cloudflare_email` | Email used for Access policy (example) |
| `cloudflare_token` | Cloudflare API token |

You can copy `terraform.tfvars` and update the values, or use environment variables / CLI flags. Keep secrets secure (consider using Terraform Cloud workspaces, environment variables, or Vault instead of committing real tokens).

The VM startup logic lives in `install-tunnel.tftpl`. Use the template to customize installed packages, the HTML content, or tunnel command.

## Usage
```bash
# 1. Initialize providers/modules
terraform init

# 2. Preview the changes
terraform plan

# 3. Apply the infrastructure
terraform apply
```

After apply completes:
- Visit `http_app.<your_zone>` in a browser. You should see the greeting page served via the Cloudflare tunnel.
- Check Cloudflare Zero Trust dashboard → Access → Tunnels to confirm the tunnel is healthy.

## Cleanup
Destroy all resources (VM, DNS records, tunnel, Access configs):
```bash
terraform destroy
```

## Troubleshooting Notes
- Ensure the VM `network_interface` specifies a valid subnetwork in the selected region; custom-mode VPCs require `subnetwork` instead of only `network`.
- Cloudflare tunnel provisioning can take a few seconds. If config or route resources fail with “Tunnel not found,” re-run `terraform apply` or add a short delay (`time_sleep`) after tunnel creation.
- The startup script installs packages on first boot, which may take a few minutes. Consider baking a custom image or containerizing the workload for faster provisioning.

