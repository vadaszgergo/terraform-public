variable "project_id" {
  description = "The Google Cloud project ID."
  type        = string
  # Consider adding your project ID as default or using tfvars
  default = "your-gcp_projectID" 
}

variable "region" {
  description = "The Google Cloud region for deployment."
  type        = string
  default     = "europe-west1"
}

variable "nva_asn" {
  description = "BGP ASN for the NVA (FRR) instance."
  type        = number
  default     = 65001
}

variable "cloud_router_asn" {
  description = "BGP ASN for the GCP Cloud Router."
  type        = number
  default     = 64512
} 