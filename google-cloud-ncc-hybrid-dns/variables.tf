variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region for all resources"
  type        = string
  default     = "europe-west1"
}

variable "zone" {
  description = "GCP zone for VM instances"
  type        = string
  default     = "europe-west1-b"
}

variable "infra_subnet_cidr" {
  description = "CIDR for the infra VPC subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "app_subnet_cidr" {
  description = "CIDR for the application VPC subnet"
  type        = string
  default     = "10.0.2.0/24"
}

variable "onprem_subnet_cidr" {
  description = "CIDR for the simulated on-prem VPC subnet"
  type        = string
  default     = "192.168.1.0/24"
}

# Static IPs for key VMs
variable "dns_vm_ip" {
  default = "10.0.1.10"
}

variable "sdwan_vm_infra_ip" {
  default = "10.0.1.20"
}

variable "sdwan_vm_onprem_ip" {
  default = "192.168.1.20"
}

variable "onprem_dns_ip" {
  default = "192.168.1.10"
}

variable "app_vm_ip" {
  default = "10.0.2.10"
}

# NCC Cloud Router BGP IPs (in infra subnet)
variable "ncc_router_ip_0" {
  default = "10.0.1.100"
}

variable "ncc_router_ip_1" {
  default = "10.0.1.101"
}
