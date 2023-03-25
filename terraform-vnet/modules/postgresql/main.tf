terraform {
  required_providers {
    azurecaf = {
      source  = "aztfmod/azurecaf"
      version = "1.2.22"
    }
  }
}

resource "azurecaf_name" "postgresql_server" {
  name          = var.application_name
  resource_type = "azurerm_postgresql_flexible_server"
  suffixes      = [var.environment]
}

resource "random_password" "password" {
  length           = 32
  special          = true
  override_special = "_%@"
}

resource "azurerm_postgresql_flexible_server" "database" {
  name                = azurecaf_name.postgresql_server.result
  resource_group_name = var.resource_group
  location            = var.location

  administrator_login    = var.administrator_login
  administrator_password = random_password.password.result

  sku_name                     = "GP_Standard_D16ds_v4"
  storage_mb                   = 32768
  backup_retention_days        = 7
  version                      = "14"
  geo_redundant_backup_enabled = true
  high_availability {
    mode                      = "ZoneRedundant"
    standby_availability_zone = "1"
  }
  zone                = "2"
  delegated_subnet_id = var.subnet_id
  private_dns_zone_id = azurerm_private_dns_zone.database.id
  depends_on          = [azurerm_private_dns_zone_virtual_network_link.database]

  tags = {
    "environment"      = var.environment
    "application-name" = var.application_name
  }

  authentication {
    active_directory_auth_enabled = true
    password_auth_enabled         = true
    tenant_id                     = data.azurerm_client_config.current.tenant_id
  }

  #uuid-ossp
}

resource "azurerm_postgresql_flexible_server_configuration" "uuid_extension" {
  server_id = azurerm_postgresql_flexible_server.database.id
  name      = "azure.extensions"
  value     = "uuid-ossp"
}

resource "azurecaf_name" "postgresql_database" {
  name          = var.application_name
  resource_type = "azurerm_postgresql_flexible_server_database"
  suffixes      = [var.environment]
}

resource "azurerm_postgresql_flexible_server_database" "database" {
  name      = azurecaf_name.postgresql_database.result
  server_id = azurerm_postgresql_flexible_server.database.id
  charset   = "utf8"
  collation = "en_US.utf8"
}

resource "azurerm_private_dns_zone" "database" {
  name                = "db1.private.postgres.database.azure.com"
  resource_group_name = var.resource_group
}

resource "azurecaf_name" "private_dns_zone_virtual_network_link" {
  name          = var.application_name
  resource_type = "azurerm_private_dns_zone_virtual_network_link"
  suffixes      = [var.environment]
}

resource "azurerm_private_dns_zone_virtual_network_link" "database" {
  name                  = azurecaf_name.private_dns_zone_virtual_network_link.result
  resource_group_name   = var.resource_group
  private_dns_zone_name = azurerm_private_dns_zone.database.name
  virtual_network_id    = var.virtual_network_id
}

data "azurerm_client_config" "current" {}

data "azuread_user" "current" {
  object_id = data.azurerm_client_config.current.object_id
}

resource "azurerm_postgresql_flexible_server_active_directory_administrator" "psql_aad_admin" {
  server_name         = azurerm_postgresql_flexible_server.database.name
  resource_group_name = var.resource_group
  tenant_id           = data.azurerm_client_config.current.tenant_id
  object_id           = data.azurerm_client_config.current.object_id
  principal_name      = data.azuread_user.current.user_principal_name
  principal_type      = "User"
}

