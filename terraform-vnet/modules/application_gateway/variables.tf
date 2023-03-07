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

variable "appgateway_subnet_id" {
  type        = string
  description = "value of the subnet id"
}

variable "backend_fqdn" {
  type = string
}

variable "keyvault_id" {
  type = string
}

variable "dns_name" {
  type = string
}

variable "certificate_secret_id" {
  type = string  
}
