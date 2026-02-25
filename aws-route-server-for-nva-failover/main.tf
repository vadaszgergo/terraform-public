terraform {
  required_version = ">= 1.2.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.100.0"
    }
  }
}

provider "aws" {
  region = "eu-central-1"
}

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  hub_vpc_cidr      = "10.0.0.0/16"
  workload_vpc_cidr = "192.168.0.0/16"

  nva1_asn             = 65101
  nva2_asn             = 65101
  route_server_hub_asn = 65000
}
