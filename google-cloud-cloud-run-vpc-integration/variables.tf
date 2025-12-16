variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region"
  type        = string
  default     = "europe-west4"
}

variable "vpc_name" {
  description = "Name of the VPC network"
  type        = string
  default     = "cloud-run-vpc"
}

variable "subnet_name" {
  description = "Name of the subnet"
  type        = string
  default     = "cloud-run-subnet"
}

variable "subnet_cidr" {
  description = "CIDR block for the subnet"
  type        = string
  default     = "10.12.1.0/24"
}

variable "cloud_run_service_name" {
  description = "Name of the Cloud Run service"
  type        = string
  default     = "cloudrun-service"
}

variable "cloud_run_image" {
  description = "Container image for Cloud Run service"
  type        = string
  default     = "gcr.io/vadaszgergo/cloud-run-proxy"
}

variable "cloud_run_port" {
  description = "Port that the Cloud Run service listens on"
  type        = number
  default     = 8080
}

variable "vpn_gateway_name" {
  description = "Name of the VPN gateway"
  type        = string
  default     = "vpn-gateway"
}

variable "vpn_tunnel_name" {
  description = "Name of the VPN tunnel"
  type        = string
  default     = "vpn-tunnel"
}

variable "vpn_remote_ip" {
  description = "Remote IP address for the VPN tunnel"
  type        = string
  default     = "91.189.63.246"
}

variable "shared_secret" {
  description = "Shared secret for the VPN tunnel"
  type        = string
  sensitive   = true
  default     = "password1234"
}

variable "route_name" {
  description = "Name of the route for VPN tunnel"
  type        = string
  default     = "vpn-route"
}

variable "route_dest_range" {
  description = "Destination CIDR range for the VPN route (on-premises network)"
  type        = string
  default     = "192.168.1.0/24"
}

variable "route_priority" {
  description = "Priority of the route"
  type        = number
  default     = 1000
}

