resource "random_string" "random_suffix" {
  length  = 6
  lower   = true
  special = false
}
# Azure Spring Apps is not yet supported in azurecaf_name
locals {
  spring_cloud_service_name = "fitness-store-prod-vnet"
  spring_cloud_app_name     = "app-${var.application_name}"

  # Azure Spring Apps Resource Provider object id. It is a constant and it is required to manage the VNET.
  azure_spring_apps_provisioner_object_id = "d2531223-68f9-459e-b225-5592f90d145e"

  # Azure AD application registration name
  azure_ad_application_name = "${var.application_name}-${random_string.random_suffix.result}"
}

# Assign Owner role to Azure Spring Apps Resource Provider on the Virtual Network used by the deployed service
# Make sure the SPID used to provision terraform has privileges to do role assignments.
resource "azurerm_role_assignment" "provider_owner" {
  scope                = var.virtual_network_id
  role_definition_name = "Owner"
  principal_id         = local.azure_spring_apps_provisioner_object_id
}

# This creates the Azure Spring Apps that the service use
resource "azurerm_spring_cloud_service" "application" {
  name                = local.spring_cloud_service_name
  resource_group_name = var.resource_group
  location            = var.location
  sku_name            = "E0"

  tags = {
    "environment"      = var.environment
    "application-name" = var.application_name
  }

  network {
    app_subnet_id             = var.app_subnet_id
    service_runtime_subnet_id = var.service_subnet_id
    cidr_ranges               = var.cidr_ranges
  }

  depends_on = [
    azurerm_role_assignment.provider_owner
  ]

  service_registry_enabled = true

  log_stream_public_endpoint_enabled = true
  build_agent_pool_size              = "S4"

  trace {
    connection_string = var.azure_application_insights_connection_string
    sample_rate       = var.azure_application_insights_sample_rate
  }
}

resource "azurerm_spring_cloud_configuration_service" "acs" {
  name                    = "default"
  spring_cloud_service_id = azurerm_spring_cloud_service.application.id
  repository {
    name     = "${var.application_name}-configterr"
    patterns = var.config_patterns
    uri      = var.config_server_git_uri
    label    = "main"
  }
  timeouts {
    create = "30m"
    update = "10m"
  }
}

resource "azurerm_spring_cloud_builder" "builder" {
  name                    = "no-bindings-builder"
  spring_cloud_service_id = azurerm_spring_cloud_service.application.id

  stack {
    id      = "io.buildpacks.stacks.bionic"
    version = "full"
  }
  build_pack_group {
    name = "default"
    build_pack_ids = [
      "tanzu-buildpacks/nodejs",
      "tanzu-buildpacks/dotnet-core",
      "tanzu-buildpacks/go",
      "tanzu-buildpacks/python"
    ]
  }
}

resource "azurerm_spring_cloud_dev_tool_portal" "dev_tool_portal" {
  name                            = "default"
  spring_cloud_service_id         = azurerm_spring_cloud_service.application.id
  public_network_access_enabled   = true
  application_accelerator_enabled = true
  application_live_view_enabled   = true
}

data "azuread_user" "app_owners" {
  count               = length(var.app_owners)
  user_principal_name = var.app_owners[count.index]
}

resource "azuread_application" "gateway_app_registration" {
  display_name = local.azure_ad_application_name
  owners       = data.azuread_user.app_owners.*.object_id
  web {
    redirect_uris = [
      "https://${var.dns_name}/login/oauth2/code/azure",
      "https://${var.dns_name}/login/oauth2/code/sso"
    ]
  }
}

resource "azuread_application_password" "gateway_app_password" {
  application_object_id = azuread_application.gateway_app_registration.object_id
}

resource "azurerm_spring_cloud_gateway" "spring_gateway" {
  name                          = "default"
  public_network_access_enabled = true
  spring_cloud_service_id       = azurerm_spring_cloud_service.application.id
  https_only                    = true

  sso {
    issuer_uri    = "https://login.microsoftonline.com/72f988bf-86f1-41af-91ab-2d7cd011db47/v2.0"
    scope         = ["openid,profile"]
    client_id     = azuread_application.gateway_app_registration.application_id
    client_secret = azuread_application_password.gateway_app_password.value
  }



  api_metadata {
    title       = "ACME Fitness"
    description = "ACME Fitness API"
    version     = "v.01"
    server_url  = "https://${var.dns_name}"

  }

  cors {
    allowed_origins = ["*"]
  }
}

resource "azurerm_spring_cloud_gateway_custom_domain" "gateway_domain" {
  spring_cloud_gateway_id = azurerm_spring_cloud_gateway.spring_gateway.id
  name                    = var.dns_name
  thumbprint              = var.cert_thumbprint
}


# Gets the Azure Spring Apps internal load balancer IP address once it is deployed
data "azurerm_lb" "asc_internal_lb" {
  resource_group_name = "ap-svc-rt_${azurerm_spring_cloud_service.application.name}_${azurerm_spring_cloud_service.application.location}"
  name                = "kubernetes-internal"
  depends_on = [
    azurerm_spring_cloud_service.application
  ]
}

# Create DNS zone
resource "azurerm_private_dns_zone" "private_dns_zone" {
  name                = "private.azuremicroservices.io"
  resource_group_name = var.resource_group
}

# Link DNS to Azure Spring Apps virtual network
resource "azurerm_private_dns_zone_virtual_network_link" "private_dns_zone_link_asc" {
  name                  = "asa-dns-link"
  resource_group_name   = var.resource_group
  private_dns_zone_name = azurerm_private_dns_zone.private_dns_zone.name
  virtual_network_id    = var.virtual_network_id
}

# Creates an A record that points to Azure Spring Apps internal balancer IP
resource "azurerm_private_dns_a_record" "internal_lb_record" {
  name                = "*"
  zone_name           = azurerm_private_dns_zone.private_dns_zone.name
  resource_group_name = var.resource_group
  ttl                 = 300
  records             = [data.azurerm_lb.asc_internal_lb.private_ip_address]
}

resource "azurerm_spring_cloud_certificate" "asa_cert" {
  name                     = var.cert_name
  resource_group_name      = var.resource_group
  service_name             = azurerm_spring_cloud_service.application.name
  key_vault_certificate_id = var.cert_id
}

# # This creates the application definition
# resource "azurerm_spring_cloud_app" "application" {
#   name                = local.spring_cloud_app_name
#   resource_group_name = var.resource_group
#   service_name        = azurerm_spring_cloud_service.application.name
#   identity {
#     type = "SystemAssigned"
#   }
# }

# # This creates the application deployment. Terraform provider doesn't support dotnet yet
# resource "azurerm_spring_cloud_java_deployment" "application_deployment" {
#   name                = "default"
#   spring_cloud_app_id = azurerm_spring_cloud_app.application.id
#   instance_count      = 1
#   runtime_version     = "Java_17"

#   quota {
#     cpu    = "1"
#     memory = "1Gi"
#   }

#   environment_variables = {
#     "SPRING_PROFILES_ACTIVE" = "prod,azure"

#     # Required for configuring the azure-spring-boot-starter-keyvault-secrets library
#     "AZURE_KEYVAULT_ENABLED" = "true"
#     "AZURE_KEYVAULT_URI"     = var.vault_uri

#     "SPRING_DATASOURCE_URL" = "jdbc:postgresql://${var.database_url}"
#     # Credentials should be retrieved from Azure Key Vault
#     "SPRING_DATASOURCE_USERNAME" = "stored-in-azure-key-vault"
#     "SPRING_DATASOURCE_PASSWORD" = "stored-in-azure-key-vault"

#     "SPRING_REDIS_HOST" = var.azure_redis_host
#     # Credentials should be retrieved from Azure Key Vault
#     "SPRING_REDIS_PASSWORD" = "stored-in-azure-key-vault"
#     "SPRING_REDIS_PORT"     = "6380"
#     "SPRING_REDIS_SSL"      = "true"
#   }
# }

# data "azurerm_client_config" "current" {}

# resource "azurerm_key_vault_access_policy" "application" {
#   key_vault_id = var.vault_id
#   tenant_id    = data.azurerm_client_config.current.tenant_id
#   object_id    = azurerm_spring_cloud_app.application.identity[0].principal_id

#   secret_permissions = [
#     "Get",
#     "List"
#   ]
# }
