variable "application_name" {
  type        = string
  description = "The name of your application"
  default     = "fitness-store-prod-vnet"
}

variable "environment" {
  type        = string
  description = "The environment (dev, test, prod...)"
  default     = ""
}

variable "location" {
  type        = string
  description = "The Azure region where all resources in this example should be created"
  default     = "eastus"
}

variable "address_space" {
  type        = string
  description = "Virtual Network address space"
  default     = "10.11.0.0/16"
}

variable "app_subnet_prefix" {
  type        = string
  description = "Application subnet prefix"
  default     = "10.11.0.0/24"
}

variable "service_subnet_prefix" {
  type        = string
  description = "Azure Spring Apps service subnet prefix"
  default     = "10.11.1.0/24"
}

variable "database_subnet_prefix" {
  type        = string
  description = "Database subnet prefix"
  default     = "10.11.2.0/24"
}

variable "redis_subnet_prefix" {
  type        = string
  description = "Redis cache subnet prefix"
  default     = "10.11.3.0/24"
}

variable "loadtests_subnet_prefix" {
  type        = string
  description = "Load tests subnet prefix"
  default     = "10.11.4.0/24"
}

variable "jumpbox_subnet_prefix" {
  type        = string
  description = "Jumpbox subnet prefix"
  default     = "10.11.5.0/24"
}

variable "bastion_subnet_prefix" {
  type        = string
  description = "Bastion subnet prefix"
  default     = "10.11.6.0/24"
}

variable "appgateway_subnet_prefix" {
  type        = string
  description = "Application Gateway subnet prefix"
  default     = "10.11.7.0/24"
}

variable "cosmos_subnet_prefix" {
  type        = string
  description = "Cosmos DB subnet prefix"
  default     = "10.11.8.0/24"
}

variable "cidr_ranges" {
  type        = list(string)
  description = "A list of (at least 3) CIDR ranges (at least /16) which are used to host the Azure Spring Apps infrastructure, which must not overlap with any existing CIDR ranges in the Subnet. Changing this forces a new resource to be created"
  default     = ["10.4.0.0/16", "10.5.0.0/16", "10.3.0.1/16"]
}

variable "config_server_git_uri" {
  type        = string
  description = "The URI of the Git repository that contains the configuration files"
  default     = "https://github.com/Azure-Samples/acme-fitness-store-config"
}

variable "config_patterns" {
  type        = list(string)
  description = "A list of patterns that are used to match the configuration files in the Git repository"
  default = [
    "catalog/default",
    "catalog/key-vault",
    "identity/default",
    "identity/key-vault",
  "payment/default"]
}

variable "jumpbox_admin_password" {
  type      = string
  sensitive = true
}

variable "aad_admin_usernames" {
  type        = list(string)
  description = "The usernames for the administrators account of the virtual machine."
}

variable "app_owners"{
  type        = list(string)
  description = "The usernames for the owners of the application."
}

variable "azure_application_insights_sample_rate" {
  type        = number
  description = "The sample rate of the load test."
  default     = 5
}
