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

variable "database_url" {
  type        = string
  description = "The URL to the database"
}

# variable "vault_id" {
#   type        = string
#   description = "The Azure Key Vault ID"
# }

# variable "vault_uri" {
#   type        = string
#   description = "The Azure Key Vault URI"
# }

variable "azure_redis_host" {
  type        = string
  description = "The Azure Cache for Redis hostname"
}

variable "virtual_network_id" {
  type        = string
  description = "Virtual Network ID where Azure Spring Apps will be deployed"
}

variable "app_subnet_id" {
  type        = string
  description = "Azure Spring Apps apps subnet ID"
}

variable "service_subnet_id" {
  type        = string
  description = "Azure Spring Apps services subnet ID"
}

variable "cidr_ranges" {
  type        = list(string)
  description = "A list of (at least 3) CIDR ranges (at least /16) which are used to host the Azure Spring Apps infrastructure, which must not overlap with any existing CIDR ranges in the Subnet. Changing this forces a new resource to be created"
}

variable "config_server_git_uri" {
  type        = string
  description = "The URI of the Git repository that contains the configuration files"
}

variable "config_patterns" {
  type        = list(string)
  description = "A list of patterns that match the configuration files"

}

variable "azure_application_insights_connection_string" {
  type        = string
  description = "The Azure Application Insights connection string"
}

variable "azure_application_insights_sample_rate" {
  type        = number
  description = "The Azure Application Insights sampling rate"
}

variable "app_owners" {
  type        = list(string)
  description = "A list of owners for the application"  
}
