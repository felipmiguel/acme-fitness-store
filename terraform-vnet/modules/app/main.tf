data "azurerm_spring_cloud_service" "spring_apps_service" {
  name                = var.spring_apps_service_name
  resource_group_name = var.resource_group
}
locals {
  app_env_vars = var.cosmos_database_name != null ? {
    "SPRING_CLOUD_AZURE_COSMOS_DATABASE" = var.cosmos_database_name
    "SPRING_CLOUD_AZURE_COSMOS_ENDPOINT" = var.cosmos_endpoint
  } : {}
  addon_json = {
    applicationConfigurationService : var.configuration_service_bind ? {
      resourceId : "${data.azurerm_spring_cloud_service.spring_apps_service.id}/configurationServices/default"
    } : {},
    serviceRegistry : var.service_registry_bind ? {
      resourceId : "${data.azurerm_spring_cloud_service.spring_apps_service.id}/serviceRegistries/default"
    } : {}
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

  addon_json = jsonencode(local.addon_json)
}



resource "azurerm_spring_cloud_build_deployment" "application_deployment" {
  name                = "default"
  spring_cloud_app_id = azurerm_spring_cloud_app.application.id
  instance_count      = 1
  build_result_id     = var.build_result_id

  quota {
    cpu    = var.cpu
    memory = var.memory
  }
  environment_variables = merge(var.environment_variables, local.app_env_vars)
}

resource "azurerm_spring_cloud_active_deployment" "active_deployment" {
  deployment_name     = azurerm_spring_cloud_build_deployment.application_deployment.name
  spring_cloud_app_id = azurerm_spring_cloud_app.application.id
}

resource "random_uuid" "role_uuid" {

}

resource "azurerm_cosmosdb_sql_role_assignment" "app_role" {
  count               = var.cosmos_database_name != null ? 1 : 0
  name                = random_uuid.role_uuid.result
  resource_group_name = var.resource_group
  account_name        = var.cosmos_account_name
  scope               = var.cosmos_database_scope
  role_definition_id  = var.cosmos_app_role_definition_id
  principal_id        = azurerm_spring_cloud_app.application.identity[0].principal_id
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

resource "azurerm_spring_cloud_gateway_route_config" "gateway_route" {
  count                   = length(var.gateway_routes) > 0 ? 1 : 0
  name                    = azurerm_spring_cloud_app.application.name
  spring_cloud_app_id     = azurerm_spring_cloud_app.application.id
  spring_cloud_gateway_id = var.cloud_gateway_id

  dynamic "route" {
    for_each = var.gateway_routes
    content {
      order                  = var.gateway_routes[route.key].order == null ? 0 : var.gateway_routes[route.key].order
      filters                = var.gateway_routes[route.key].filters
      classification_tags    = var.gateway_routes[route.key].tags
      predicates             = var.gateway_routes[route.key].predicates
      sso_validation_enabled = var.gateway_routes[route.key].ssoEnabled
      token_relay            = var.gateway_routes[route.key].tokenRelay
      uri                    = var.gateway_routes[route.key].uri
      title                  = var.gateway_routes[route.key].title
      description            = var.gateway_routes[route.key].description
    }
  }
}
