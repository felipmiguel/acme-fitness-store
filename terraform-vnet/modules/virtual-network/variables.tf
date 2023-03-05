variable "resource_group" {
  type        = string
  description = "The resource group"
}

variable "application_name" {
  type        = string
  description = "The name of your application"
}

variable "environment" {
  type        = string
  description = "The environment (dev, test, prod...)"
  default     = "dev"
}

variable "location" {
  type        = string
  description = "The Azure region where all resources in this example should be created"
}

variable "address_space" {
  type        = string
  description = "VNet address space"
}

variable "app_subnet_prefix" {
  type        = string
  description = "Application subnet prefix"
}

variable "service_subnet_prefix" {
  type        = string
  description = "Azure Spring Apps service subnet prefix"
}

variable "service_endpoints" {
  type        = list(string)
  description = "Service endpoints used by the solution"
}

variable "database_subnet_prefix" {
  type        = string
  description = "Azure Database subnet prefix"
}

variable "redis_subnet_prefix" {
  type        = string
  description = "Azure Redis Cache subnet prefix"
}

variable "loadtests_subnet_prefix" {
  type        = string
  description = "Load tests subnet prefix"
}

variable "jumpbox_subnet_prefix" {
  type        = string
  description = "Jumpbox subnet prefix"
}

variable "bastion_subnet_prefix" {
  type        = string
  description = "Bastion subnet prefix"
}

variable "appgateway_subnet_prefix" {
  type        = string
  description = "Application Gateway subnet prefix"
}

variable "cosmos_subnet_prefix" {
  type        = string
  description = "Cosmos DB subnet prefix"  
}
