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
  default = false
}

variable "runtime_version" {
  type        = string
  description = "The runtime version of the application"
}

variable "cloud_gateway_id" {
  type        = string
  description = "The ID of the gateway"
}

variable "gateway_routes" {
  type = list(object({
    predicates = list(string),
    filters    = optional(list(string)),
    tags       = list(string)
    ssoEnabled = optional(bool)
    tokenRelay = optional(bool)
  }))
  description = "The gateway routes"
  default = [ ]
}
