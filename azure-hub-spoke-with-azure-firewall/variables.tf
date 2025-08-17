variable "prefix" {
  description = "Prefix used for all resources"
  type        = string
  default     = "hubspoke"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "westeurope"
} 