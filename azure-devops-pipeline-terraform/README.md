# Azure DevOps Pipeline with Terraform

This repository contains infrastructure as code (IaC) using Terraform to deploy Azure resources, along with an Azure DevOps pipeline configuration for automated deployment.

## Contents

### 1. `main.tf`
This Terraform configuration file defines the following Azure resources:
- Resource Group
- Virtual Network with a subnet
- Public IP address
- Network Interface
- Ubuntu Linux Virtual Machine (22.04 LTS)

The infrastructure is configured to deploy in the UK South region and includes basic networking setup with a public IP for the VM.

### 2. `azure-pipelines.yml`
This Azure DevOps pipeline configuration file defines a CI/CD process with two stages:

#### Validate Stage
- Installs Terraform
- Initializes Terraform with Azure backend configuration
- Validates the Terraform configuration

#### Deploy Stage
- Runs after successful validation
- Installs Terraform
- Initializes Terraform
- Creates an execution plan
- Applies the infrastructure changes

## Prerequisites

1. Azure subscription
2. Azure DevOps organization
3. Service connection to Azure (named 'service-conn-azure' in the pipeline)
4. Storage account for Terraform state (configured in pipeline variables)

## Configuration

Before using this repository:

1. Update the `subscription_id` in `main.tf` with your Azure subscription ID
2. Modify the pipeline variables in `azure-pipelines.yml` to match your environment:
   - `resourcegroup`
   - `accountname`
   - `containername`
   - `key`

## Security Note

The current configuration includes a hardcoded password in `main.tf`. In a production environment, you should:
1. Use Azure Key Vault for sensitive information
2. Implement proper password management
3. Consider using SSH keys instead of password authentication

## Usage

1. Push your code to the main branch or new branch with pull request
2. The pipeline will automatically trigger
3. The validate stage will run first
4. If validation succeeds, the deploy stage will execute

## Customization

You can modify the infrastructure by:
1. Adding or removing resources in `main.tf`
2. Adjusting the VM size, location, or other parameters
3. Modifying the pipeline stages or adding additional steps as needed 