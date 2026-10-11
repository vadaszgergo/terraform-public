terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    # AWS Interconnect has no resource in the aws provider yet (hashicorp/terraform-provider-aws#47458),
    # so the connection is created through the Cloud Control based awscc provider.
    awscc = {
      source  = "hashicorp/awscc"
      version = "~> 1.0"
    }
    # azurerm_express_route_circuit has no partner account / activation key arguments yet,
    # so the Multicloud Interconnect circuit is created through azapi.
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.0"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project = var.prefix
    }
  }
}

provider "awscc" {
  region = var.aws_region
}

provider "azapi" {}
