# Deploy a Free Azure App Service with a Docker Image Using Terraform

This Terraform script sets up a free-tier (F1) Azure App Service that runs a Docker container.

## Prerequisites

Before running the Terraform script, ensure you have:

- An **Azure subscription**
- **Terraform** installed ([Install Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli))
- **Azure CLI** installed ([Install Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli))

## Deployment Steps

### 1. Authenticate with Azure

```sh
az login
az account set --subscription "<your-subscription-id>"
```

### 2. Initialize Terraform

```sh
terraform init
```

### 3. Review the Terraform Plan

```sh
terraform plan
```

### 4. Deploy the Infrastructure

```sh
terraform apply 
```

### 5. Retrieve the Web App URL

After deployment, get the web app URL with:

```sh
az webapp show --name ipcalculator-app --resource-group free-appservice-rg --query "defaultHostName" -o tsv
```

## Resources Created

- **Resource Group:** `free-appservice-rg`
- **App Service Plan:** `free-appservice-plan` (F1 Free Tier)
- **App Service (Web App):** `ipcalculator-app` running the Docker image `vadaszgergo/ip-tools:latest`

## Cleanup

To remove all deployed resources:

```sh
terraform destroy 
```

## Notes

- The **F1 tier** is free but has limitations (e.g., low compute power, no custom domain binding, no SLA).
- **VNET integration is not available** on the Free tier.
- Modify the `docker_image_name` in `main.tf` to deploy a different Docker image.

## Troubleshooting

- If you encounter permission issues, ensure your Azure CLI session is authenticated.
- Run `terraform apply` again if deployment fails due to transient issues.
- Check the Azure Portal for deployment errors in the **App Service > Deployment Center**.

---



