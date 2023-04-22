variable "resource_group" {
  type        = string
  description = "The resource group"
  default     = ""
}

variable "application_name" {
  type        = string
  description = "The name of your application"
  default     = ""
}

variable "environment" {
  type        = string
  description = "The environment (dev, test, prod...)"
  default     = "dev"
}

variable "location" {
  type        = string
  description = "The Azure region where all resources in this example should be created"
  default     = ""
}

variable "virtual_network_id" {
  type        = string
  description = "Azure Virtual Network ID"
}

variable "dns_zone"{
    type        = string
    description = "The DNS zone"
    default     = "db1.private.postgres.database.azure.com"
}