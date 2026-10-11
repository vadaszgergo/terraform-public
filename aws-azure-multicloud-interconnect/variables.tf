variable "prefix" {
  description = "Short prefix used in resource names."
  type        = string
  default     = "awsazure"
}

variable "azure_location" {
  description = "Azure region for all Azure resources."
  type        = string
  default     = "germanywestcentral"
}

variable "aws_region" {
  description = "AWS region for all AWS resources."
  type        = string
  default     = "eu-central-1"
}

variable "admin_username" {
  description = "Admin user for the Azure Ubuntu VM (the AWS VM uses the default 'ubuntu' user)."
  type        = string
  default     = "azureuser"
}

variable "ssh_public_key_path" {
  description = "Path to the SSH public key used for VM access."
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "azure_vm_size" {
  description = "Size for the Azure lab VM."
  type        = string
  default     = "Standard_D2as_v4"
}

variable "aws_instance_type" {
  description = "Instance type for the AWS lab VM (kept small/cheap)."
  type        = string
  default     = "t3.micro"
}

variable "my_ssh_source_cidr" {
  description = "Source CIDR allowed to SSH into the VMs. Tighten to your /32 for safety."
  type        = string
  default     = "0.0.0.0/0"
}

variable "interconnect_peering_location" {
  description = "Azure Multicloud Interconnect peering location. Must pair with aws_region (germanywc <-> eu-central-1)."
  type        = string
  default     = "germanywc"
}

variable "interconnect_bandwidth_mbps" {
  description = "Interconnect bandwidth. Only 1 Gbps is offered during the preview."
  type        = number
  default     = 1000
}

variable "azure_ergw_sku" {
  description = "SKU of the Azure ExpressRoute virtual network gateway."
  type        = string
  default     = "ErGw1AZ"
}

# Keep both ASNs outside 65515-65520, which Microsoft reserves
variable "aws_dxgw_asn" {
  description = "Amazon side ASN of the Direct Connect gateway."
  type        = number
  default     = 65534
}

variable "aws_vgw_asn" {
  description = "Amazon side ASN of the virtual private gateway."
  type        = number
  default     = 64512
}

# Address space layout (non-overlapping, so the two sides can be routed to each other later)
locals {
  azure_vnet_cidr   = "10.10.0.0/16"
  azure_subnet_cidr = "10.10.1.0/24"

  azure_gateway_subnet_cidr = "10.10.255.0/27"

  aws_vpc_cidr    = "10.20.0.0/16"
  aws_subnet_cidr = "10.20.1.0/24"
}
