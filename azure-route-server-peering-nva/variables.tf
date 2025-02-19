# Define variables
variable "location" {
  description = "The Azure region to deploy resources"
  default     = "West Europe"
}

variable "resource_group_name" {
  description = "The name of the resource group"
  default     = "hub-spoke-rg"
}