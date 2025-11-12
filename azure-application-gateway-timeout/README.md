# Azure Application Gateway Timeout Configuration

This Terraform configuration sets up an Azure VNet with Application Gateway infrastructure for testing timeout scenarios.

## Architecture

- **VNet**: 10.0.0.0/16
  - **Client Subnet**: 10.0.0.0/24
  - **App Gateway Subnet**: 10.0.1.0/24
  - **Server Subnet**: 10.0.2.0/24

- **Virtual Machines**:
  - Client VM in the client subnet with public IP
  - Server VM in the server subnet with public IP
  - Server VM runs:
    - **nginx** on port 999 (direct access)
    - **Flask webserver** on port 80 via nginx reverse proxy (delays 450 seconds per request)

- **Application Gateway**:
  - Standard_v2 SKU with public and private frontend IPs
  - Backend pool containing the server VM
  - Request timeout extended to 600 seconds to handle the delayed response

## Resources Created

- Resource Group
- Virtual Network with 3 subnets
- Application Gateway (Standard_v2) with public and private frontend IPs
- 2 Linux VMs (Ubuntu 22.04 LTS)
- 3 Public IPs (client VM, server VM, Application Gateway)

## Usage

1. Initialize Terraform:
   ```bash
   terraform init
   ```

2. Review the plan:
   ```bash
   terraform plan
   ```

3. Apply the configuration:
   ```bash
   terraform apply
   ```

4. Access the services:
   - **Direct server access**:
     - **nginx**: `http://<server-ip>:999` (via output `server_vm_nginx_url`)
     - **Flask webserver**: `http://<server-ip>:80` (via output `server_vm_flask_url`)
   - **Via Application Gateway**:
     - **Public frontend**: `http://<appgw-public-ip>` (via output `appgw_public_url`)
     - **Private frontend**: `http://10.0.1.10` (via output `appgw_private_url` from within VNet)
     - **Note**: Flask delays 450 seconds (7.5 minutes) before responding, designed for testing timeout scenarios

5. SSH to VMs:
   - Use the SSH commands from the outputs

## Default Credentials

- Username: `gergo` (SSH key authentication)
- Password: `Password123!` (fallback)

**Note**: Change the password in `servers.tf` before deploying to production!

## Security

**Important**: This configuration has **no Network Security Groups (NSGs)** for simplicity and testing purposes. All ports are open on all VMs. **Do not use this in production** without proper security hardening.

## Monitoring

To check the status of the Flask webserver on the server VM:
```bash
ssh gergo@<server-ip>
sudo systemctl status flask-app
sudo journalctl -u flask-app -f
```

## Troubleshooting

If the VMs were deployed without the Custom Script Extension, you can manually run the installation script:

```bash
# SSH to the server VM
ssh gergo@51.136.102.59

# Copy and run the install script
curl -O https://raw.githubusercontent.com/your-repo/azure-application-gateway-timeout/main/install.sh
chmod +x install.sh
sudo ./install.sh
```

Or you can copy the script from your local machine:
```bash
scp install.sh gergo@51.136.102.59:~/
ssh gergo@51.136.102.59
chmod +x install.sh
sudo ./install.sh
```

## Clean Up

```bash
terraform destroy
```

