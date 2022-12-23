locals {
  service_connector_name = "${var.application_name}-${var.environment}-${var.db}"
}


resource "azurerm_spring_cloud_connection" "service_connector" {
  authentication {
    type = "ManagedIdentity"
  }
  name               = local.service_connector_name
  client_type        = "springBoot"
  spring_cloud_id    = var.spring_app_id
  target_resource_id = var.target_resource_id
  vnet_solution      = "serviceEndpoint"
}
