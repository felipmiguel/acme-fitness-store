variable "resource_group" {
  type        = string
  description = "The resource group"
}

variable "application_name" {
  type        = string
  description = "The name of your application"
}

variable "spring_apps_service_name" {
  type        = string
  description = "The name of the Azure Spring App Service"
}

variable "assign_public_endpoint" {
  type        = bool
  description = "Whether to assign a public endpoint to the application"
  default     = false
}

variable "runtime_version" {
  type        = string
  description = "The runtime version of the application"
}

variable "service_registry_bind" {
  type        = bool
  description = "Whether to bind the application to the service registry"
}

variable "configuration_service_bind" {
  type        = bool
  description = "Whether to bind the application to the configuration service"
}

variable "cloud_gateway_id" {
  type        = string
  description = "The ID of the gateway"
}

variable "gateway_routes" {
  type = list(object({
    title       = optional(string),
    description = optional(string),
    predicates  = list(string),
    filters     = optional(list(string)),
    order       = optional(number)
    tags        = list(string)
    ssoEnabled  = optional(bool)
    tokenRelay  = optional(bool)
    uri         = optional(string)
  }))
  description = "The gateway routes"
  default     = []
}

variable "cosmos_database_name" {
  type        = string
  description = "The name of the Cosmos DB database"
  default     = null
}

variable "cosmos_database_id" {
  type        = string
  description = "The ID of the Cosmos DB database"
  default     = null
}

variable "cosmos_endpoint" {
  type        = string
  description = "The endpoint of the Cosmos DB database"
  default     = null
}

variable "cosmos_app_role_definition_id" {
  type        = string
  description = "The ID of the Cosmos DB role definition"
  default     = null
}

variable "cosmos_account_name" {
  type        = string
  description = "The name of the Cosmos DB account"
  default     = null
}

variable "cosmos_account_id" {
  type        = string
  description = "The ID of the Cosmos DB account"
  default     = null
}

variable "environment_variables" {
  type        = map(string)
  description = "The environment variables"
  default     = {}
}
