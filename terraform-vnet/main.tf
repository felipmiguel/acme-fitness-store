terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.47"
    }
    azurecaf = {
      source  = "aztfmod/azurecaf"
      version = "1.2.22"
    }
    azapi = {
      source = "azure/azapi"
    }
  }
}

provider "azurerm" {
  features {}
}

locals {
  // If an environment is set up (dev, test, prod...), it is used in the application name
  environment = var.environment == "" ? "dev" : var.environment
}

data "http" "myip" {
  url = "http://whatismyip.akamai.com"
}

locals {
  myip                = chomp(data.http.myip.response_body)
  resource_group_name = "Fitness-Store-Prod-VNET"
}

# resource "azurecaf_name" "resource_group" {
#   name          = var.application_name
#   resource_type = "azurerm_resource_group"
#   suffixes      = [local.environment]
# }

resource "azurerm_resource_group" "main" {
  name     = local.resource_group_name
  location = var.location

  tags = {
    "terraform"        = "true"
    "environment"      = local.environment
    "application-name" = var.application_name
    "nubesgen-version" = "undefined"
  }
}

module "application_insights" {
  source           = "./modules/application_insights"
  resource_group   = azurerm_resource_group.main.name
  application_name = var.application_name
  environment      = local.environment
  location         = var.location
}

module "application" {
  source           = "./modules/spring-cloud"
  resource_group   = azurerm_resource_group.main.name
  application_name = var.application_name
  environment      = local.environment
  location         = var.location

  database_url = module.database.database_url

  azure_redis_host = module.redis.azure_redis_host

  virtual_network_id = module.network.virtual_network_id
  app_subnet_id      = module.network.app_subnet_id
  service_subnet_id  = module.network.service_subnet_id
  cidr_ranges        = var.cidr_ranges

  config_server_git_uri                        = var.config_server_git_uri
  config_patterns                              = var.config_patterns
  azure_application_insights_connection_string = module.application_insights.azure_application_insights_connection_string
  azure_application_insights_sample_rate       = var.azure_application_insights_sample_rate

  app_owners = var.app_owners

  cert_id         = module.keyvault.certificate_id
  cert_name       = module.keyvault.certificate_name
  cert_thumbprint = module.keyvault.certificate_thumbprint
  dns_name        = var.dns_name
}

module "database" {
  source           = "./modules/postgresql"
  resource_group   = azurerm_resource_group.main.name
  application_name = var.application_name
  environment      = local.environment
  location         = var.location

  subnet_id          = module.network.database_subnet_id
  virtual_network_id = module.network.virtual_network_id
}

module "redis" {
  source           = "./modules/redis"
  resource_group   = azurerm_resource_group.main.name
  application_name = var.application_name
  environment      = local.environment
  location         = var.location
  subnet_id        = module.network.redis_subnet_id
}

module "network" {
  source           = "./modules/virtual-network"
  resource_group   = azurerm_resource_group.main.name
  application_name = var.application_name
  environment      = local.environment
  location         = var.location

  service_endpoints = ["Microsoft.Sql", "Microsoft.KeyVault"]

  address_space                   = var.address_space
  app_subnet_prefix               = var.app_subnet_prefix
  service_subnet_prefix           = var.service_subnet_prefix
  database_subnet_prefix          = var.database_subnet_prefix
  redis_subnet_prefix             = var.redis_subnet_prefix
  loadtests_subnet_prefix         = var.loadtests_subnet_prefix
  jumpbox_subnet_prefix           = var.jumpbox_subnet_prefix
  bastion_subnet_prefix           = var.bastion_subnet_prefix
  appgateway_subnet_prefix        = var.appgateway_subnet_prefix
  cosmos_subnet_prefix            = var.cosmos_subnet_prefix
  private_endpoints_subnet_prefix = var.private_endpoints_subnet_prefix
}

module "jumpbox" {
  source           = "./modules/jumpbox"
  resource_group   = azurerm_resource_group.main.name
  application_name = var.application_name
  environment      = local.environment
  location         = var.location

  vm_subnet_id      = module.network.jumpbox_subnet_id
  bastion_subnet_id = module.network.bastion_subnet_id
  admin_password    = var.jumpbox_admin_password
  enroll_with_mdm   = true
}

module "jumpbox_admins" {
  count              = length(var.aad_admin_usernames)
  source             = "./modules/jumpbox_admin"
  aad_admin_username = var.aad_admin_usernames[count.index]
  vm_id              = module.jumpbox.vm_id
}

module "keyvault" {
  source           = "./modules/keyvault"
  resource_group   = azurerm_resource_group.main.name
  application_name = var.application_name
  environment      = local.environment
  location         = var.location

  virtual_network_id = module.network.virtual_network_id
  subnet_id          = module.network.private_endpoints_subnet_id
  dns_name           = var.dns_name
}

module "appgateway" {
  source           = "./modules/application_gateway"
  resource_group   = azurerm_resource_group.main.name
  application_name = var.application_name
  environment      = local.environment
  location         = var.location

  appgateway_subnet_id  = module.network.appgateway_subnet_id
  backend_fqdn          = module.application.spring_cloud_gateway_url
  keyvault_id           = module.keyvault.kv_id
  dns_name              = var.dns_name
  certificate_secret_id = module.keyvault.certificate_secret_id
}

module "cosmosdb" {
  source             = "./modules/cosmosdb"
  resource_group     = azurerm_resource_group.main.name
  application_name   = var.application_name
  environment        = local.environment
  location           = var.location
  virtual_network_id = module.network.virtual_network_id
  subnet_id          = module.network.cosmos_subnet_id
}

// cart-service
module "cart_service" {
  source                     = "./modules/app"
  resource_group             = azurerm_resource_group.main.name
  application_name           = "cart-service"
  runtime_version            = "Java_17"
  spring_apps_service_name   = module.application.spring_cloud_service_name
  cloud_gateway_id           = module.application.cloud_gateway_id
  gateway_routes             = jsondecode(file("../routes/cart-service.json"))
  service_registry_bind      = false
  configuration_service_bind = false
  environment_variables = {
    "AUTH_URL"               = module.application.spring_cloud_gateway_url
    "CART_PORT"              = "8080"
    "INSTRUMENTATION_KEY"    = module.application_insights.azure_application_insights_instrumentation_key
    "REDIS_CONNECTIONSTRING" = module.redis.azure_redis_connection_string
  }
}

# resource "azurerm_spring_cloud_connection" "cart_service" {
#   name = "cart_service_cache"
#   authentication {
#     type   = "secret"
#     name   = "cart_service"
#     secret = module.redis.azure_redis_password
#   }
#   # authentication {
#   #   type = "systemAssignedIdentity"
#   # }

#   client_type        = "java"
#   spring_cloud_id    = module.cart_service.spring_cloud_id
#   target_resource_id = module.redis.azure_redis_id
# }

// catalog-service
# module "catalog_service" {
#   source                   = "./modules/app"
#   resource_group           = azurerm_resource_group.main.name
#   application_name         = "catalog-service"
#   runtime_version          = "Java_17"
#   spring_apps_service_name = module.application.spring_cloud_service_name
#   cloud_gateway_id         = module.application.cloud_gateway_id
#   gateway_routes           = jsondecode(file("../routes/catalog-service.json"))
#   assign_public_endpoint   = true
# service_registry_bind    = true
#   configuration_service_bind = true
# }

# resource "azurerm_spring_cloud_connection" "catalog_service" {
#   name = "catalog_service_db"
#   authentication {
#     type = "systemAssignedIdentity"
#   }

#   client_type        = "springBoot"
#   spring_cloud_id    = module.catalog_service.spring_cloud_id
#   target_resource_id = module.database.database_id
# }

// frontend
module "frontend" {
  source                     = "./modules/app"
  resource_group             = azurerm_resource_group.main.name
  application_name           = "frontend"
  runtime_version            = "Java_17"
  spring_apps_service_name   = module.application.spring_cloud_service_name
  cloud_gateway_id           = module.application.cloud_gateway_id
  gateway_routes             = jsondecode(file("../routes/frontend.json"))
  service_registry_bind      = false
  configuration_service_bind = false
  environment_variables = {
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = "value"
  }
}
// identity-service
module "identity_service" {
  source                     = "./modules/app"
  resource_group             = azurerm_resource_group.main.name
  application_name           = "identity-service"
  runtime_version            = "Java_17"
  spring_apps_service_name   = module.application.spring_cloud_service_name
  cloud_gateway_id           = module.application.cloud_gateway_id
  gateway_routes             = jsondecode(file("../routes/identity-service.json"))
  service_registry_bind      = true
  configuration_service_bind = true
  environment_variables = {
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = module.application_insights.azure_application_insights_connection_string
  }
}

locals {
  order_routes = jsondecode(file("../routes/order-service.json"))
}

// order-service
module "order_service" {
  source                     = "./modules/app"
  resource_group             = azurerm_resource_group.main.name
  application_name           = "order-service"
  runtime_version            = "dotnet"
  spring_apps_service_name   = module.application.spring_cloud_service_name
  cloud_gateway_id           = module.application.cloud_gateway_id
  gateway_routes             = jsondecode(file("../routes/order-service.json"))
  service_registry_bind      = false
  configuration_service_bind = false
  environment_variables = {
    "DatabaseProvider"                      = "Postgres"
    "ConnectionStrings__OrderContext"       = "Server=${module.database.database_fqdn};Database=${module.database.database_name};Port=5432;Ssl Mode=Require;User Id=${module.database.database_username};Password=${module.database.database_password};}"
    "ApplicationInsights__ConnectionString" = "InstrumentationKey=${module.application_insights.azure_application_insights_connection_string}"
    "AcmeServiceSettings__AuthUrl"          = module.application.spring_cloud_gateway_url
  }
}

# resource "azurerm_spring_cloud_connection" "order_service" {
#   name = "order_service_db"
#   authentication {
#     type   = "secret"
#     name   = module.database.database_username
#     secret = module.database.database_password
#   }

#   client_type        = "dotnet"
#   spring_cloud_id    = module.order_service.spring_cloud_id
#   target_resource_id = module.database.database_id
# }

// payment-service
module "payment_service" {
  source                     = "./modules/app"
  resource_group             = azurerm_resource_group.main.name
  application_name           = "payment-service"
  runtime_version            = "java"
  spring_apps_service_name   = module.application.spring_cloud_service_name
  cloud_gateway_id           = module.application.cloud_gateway_id
  service_registry_bind      = true
  configuration_service_bind = true
}

locals {
  cosmosdb_scope ="${module.cosmosdb.azure_cosmosdb_account_id}/dbs/${module.cosmosdb.azure_cosmosdb_database_name}"
}

// catalog cosmos
module "catalog_cosmos" {
  source                        = "./modules/app"
  resource_group                = azurerm_resource_group.main.name
  application_name              = "catalog-service-cosmos"
  runtime_version               = "java"
  spring_apps_service_name      = module.application.spring_cloud_service_name
  cloud_gateway_id              = module.application.cloud_gateway_id
  assign_public_endpoint        = true
  cosmos_account_id             = module.cosmosdb.azure_cosmosdb_account_id
  cosmos_account_name           = module.cosmosdb.azure_cosmosdb_account_name
  cosmos_database_scope            =  local.cosmosdb_scope
  cosmos_database_name          = module.cosmosdb.azure_cosmosdb_database_name
  cosmos_endpoint               = module.cosmosdb.azure_cosmosdb_uri
  cosmos_app_role_definition_id = module.cosmosdb.cosmos_app_role_definition_id
  service_registry_bind         = true
  configuration_service_bind    = true
}
