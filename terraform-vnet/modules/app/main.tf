terraform {
  required_providers {
    azapi = {
      source = "azure/azapi"
    }
  }
}

resource "azurerm_spring_cloud_app" "application" {
  name                = var.application_name
  resource_group_name = var.resource_group
  service_name        = var.spring_apps_service_name
  is_public           = var.assign_public_endpoint
  identity {
    type = "SystemAssigned"
  }


}

# resource "azurerm_spring_cloud_con" "name" {

# }


resource "azurerm_spring_cloud_build_deployment" "application_deployment" {
  name                = "default"
  spring_cloud_app_id = azurerm_spring_cloud_app.application.id
  instance_count      = 1
  build_result_id     = "<default>"
  
  
  quota {
    cpu    = "1"
    memory = "1Gi"
  }
}

resource "azurerm_spring_cloud_active_deployment" "active_deployment" {
  deployment_name = azurerm_spring_cloud_build_deployment.application_deployment.name
  spring_cloud_app_id = azurerm_spring_cloud_app.application.id  
}

# resource "azapi_resource" "gateway_route"{
#   count = length(var.gateway_routes) > 0 ? 1 : 0
#   type = "Microsoft.AppPlatform/Spring/gateways/routeConfigs@2022-09-01-preview"
#   name = azurerm_spring_cloud_app.application.name
#   parent_id = var.cloud_gateway_id
#   body = jsonencode({
#     properties = {
#       appResourceId = azurerm_spring_cloud_app.application.id
#       routes = [for r in var.gateway_routes : {
#         order = index(var.gateway_routes, r)
#         filters = r.filters
#         tags =  r.tags
#         predicates = r.predicates
#         ssoEnabled = r.ssoEnabled
#         tokenRelay = r.tokenRelay
#       }]
#   }})
# }

# resource "azurerm_spring_cloud_gateway_route_config" "gateway_route" {
#   count                   = length(var.gateway_routes) > 0 ? 1 : 0
#   name                    = azurerm_spring_cloud_app.application.name
#   spring_cloud_app_id     = azurerm_spring_cloud_app.application.id
#   spring_cloud_gateway_id = var.cloud_gateway_id
#   dynamic "route" {
#     for_each = var.gateway_routes
#     content {
#       order                  = index(var.gateway_routes, var.gateway_routes[route.key])
#       filters                = var.gateway_routes[route.key].filters
#       classification_tags    = var.gateway_routes[route.key].tags
#       predicates             = var.gateway_routes[route.key].predicates
#       sso_validation_enabled = var.gateway_routes[route.key].ssoEnabled
#       token_relay            = var.gateway_routes[route.key].tokenRelay
#     }
#   }
# }
