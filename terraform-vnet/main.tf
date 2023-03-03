terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.36.0"
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

  config_server_git_uri = var.config_server_git_uri
  config_patterns       = var.config_patterns
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

  address_space            = var.address_space
  app_subnet_prefix        = var.app_subnet_prefix
  service_subnet_prefix    = var.service_subnet_prefix
  database_subnet_prefix   = var.database_subnet_prefix
  redis_subnet_prefix      = var.redis_subnet_prefix
  loadtests_subnet_prefix  = var.loadtests_subnet_prefix
  jumpbox_subnet_prefix    = var.jumpbox_subnet_prefix
  bastion_subnet_prefix    = var.bastion_subnet_prefix
  appgateway_subnet_prefix = var.appgateway_subnet_prefix
}

module "jumpbox" {
  source           = "./modules/jumpbox"
  resource_group   = azurerm_resource_group.main.name
  application_name = var.application_name
  environment      = local.environment
  location         = var.location

  vm_subnet_id       = module.network.jumpbox_subnet_id
  bastion_subnet_id  = module.network.bastion_subnet_id
  admin_password     = var.jumpbox_admin_password
  aad_admin_username = var.aad_admin_username
  enroll_with_mdm    = true
}

module "appgateway" {
  source           = "./modules/application_gateway"
  resource_group   = azurerm_resource_group.main.name
  application_name = var.application_name
  environment      = local.environment
  location         = var.location

  appgateway_subnet_id = module.network.appgateway_subnet_id
}

module "cosmosdb" {
  source           = "./modules/cosmosdb"
  resource_group   = azurerm_resource_group.main.name
  application_name = var.application_name
  environment      = local.environment
  location         = var.location

  subnet_id = module.network.database_subnet_id
}

// cart-service
module "cart_service" {
  source                   = "./modules/app"
  resource_group           = azurerm_resource_group.main.name
  application_name         = "cart-service"
  runtime_version          = "Java_17"
  spring_apps_service_name = module.application.spring_cloud_service_name
  cloud_gateway_id         = module.application.cloud_gateway_id
  gateway_routes           = jsondecode(file("../routes/cart-service.json"))
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
  source                   = "./modules/app"
  resource_group           = azurerm_resource_group.main.name
  application_name         = "frontend"
  runtime_version          = "Java_17"
  spring_apps_service_name = module.application.spring_cloud_service_name
  cloud_gateway_id         = module.application.cloud_gateway_id
  gateway_routes           = jsondecode(file("../routes/frontend.json"))
}
// identity-service
module "identity_service" {
  source                   = "./modules/app"
  resource_group           = azurerm_resource_group.main.name
  application_name         = "identity-service"
  runtime_version          = "Java_17"
  spring_apps_service_name = module.application.spring_cloud_service_name
  cloud_gateway_id         = module.application.cloud_gateway_id
  gateway_routes           = jsondecode(file("../routes/identity-service.json"))
}

// order-service
module "order_service" {
  source                   = "./modules/app"
  resource_group           = azurerm_resource_group.main.name
  application_name         = "order-service"
  runtime_version          = "dotnet"
  spring_apps_service_name = module.application.spring_cloud_service_name
  cloud_gateway_id         = module.application.cloud_gateway_id
  gateway_routes           = jsondecode(file("../routes/order-service.json"))
}

resource "azurerm_spring_cloud_connection" "order_service" {
  name = "order_service_db"
  authentication {
    type   = "secret"
    name   = module.database.database_username
    secret = module.database.database_password
  }

  client_type        = "dotnet"
  spring_cloud_id    = module.order_service.spring_cloud_id
  target_resource_id = module.database.database_id
}

// payment-service
module "payment_service" {
  source                   = "./modules/app"
  resource_group           = azurerm_resource_group.main.name
  application_name         = "payment-service"
  runtime_version          = "java"
  spring_apps_service_name = module.application.spring_cloud_service_name
  cloud_gateway_id         = module.application.cloud_gateway_id
}
