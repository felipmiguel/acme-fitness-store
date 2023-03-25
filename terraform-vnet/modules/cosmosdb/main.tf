terraform {
  required_providers {
    azurecaf = {
      source  = "aztfmod/azurecaf"
      version = "1.2.22"
    }
  }
}

resource "azurecaf_name" "cosmosdb_account" {
  name          = var.application_name
  resource_type = "azurerm_cosmosdb_account"
  suffixes      = [var.environment]
}

resource "azurerm_cosmosdb_account" "cosmosdb" {
  name                = azurecaf_name.cosmosdb_account.result
  resource_group_name = var.resource_group
  location            = var.location
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"

  tags = {
    "environment"      = var.environment
    "application-name" = var.application_name
  }

  consistency_policy {
    consistency_level = "BoundedStaleness"
  }

  geo_location {
    failover_priority = 0
    location          = var.location
    zone_redundant    = true
  }

  public_network_access_enabled = false
  # is_virtual_network_filter_enabled = true

  # virtual_network_rule {
  #   id = var.subnet_id
  # }

  capacity {
    total_throughput_limit = -1
  }
}

resource "azurecaf_name" "cosmosdb_private_endpoint" {
  name          = var.application_name
  resource_type = "azurerm_private_endpoint"
  suffixes      = [var.environment]
}

resource "azurerm_private_endpoint" "cosmos_private_endpoint" {
  name                = azurecaf_name.cosmosdb_private_endpoint.result
  location            = var.location
  resource_group_name = var.resource_group
  subnet_id           = var.subnet_id
  private_dns_zone_group {
    name                 = "cosmosdb"
    private_dns_zone_ids = [azurerm_private_dns_zone.cosmos.id]
  }
  private_service_connection {
    name                           = "cosmosdb"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_cosmosdb_account.cosmosdb.id
    subresource_names              = ["sql"]
  }
}


resource "azurerm_private_dns_zone" "cosmos" {
  name                = "privatelink.documents.azure.com"
  resource_group_name = var.resource_group
}

resource "azurecaf_name" "private_dns_zone_virtual_network_link" {
  name          = var.application_name
  resource_type = "azurerm_private_dns_zone_virtual_network_link"
  suffixes      = [var.environment, "cosmos"]
}

resource "azurerm_private_dns_zone_virtual_network_link" "database" {
  name                  = azurecaf_name.private_dns_zone_virtual_network_link.result
  resource_group_name   = var.resource_group
  private_dns_zone_name = azurerm_private_dns_zone.cosmos.name
  virtual_network_id    = var.virtual_network_id
}


resource "azurerm_cosmosdb_sql_role_definition" "app_access" {
  account_name        = azurerm_cosmosdb_account.cosmosdb.name
  resource_group_name = azurerm_cosmosdb_account.cosmosdb.resource_group_name
  name                = "${var.application_name}-app-access"
  type                = "CustomRole"
  assignable_scopes   = ["${azurerm_cosmosdb_account.cosmosdb.id}/dbs/${azurerm_cosmosdb_sql_database.cosmosdb.name}"]
  # assignable_scopes = [ "/" ]
  permissions {
    data_actions = [
      "Microsoft.DocumentDB/databaseAccounts/readMetadata",
      "Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers/items/*",
      "Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers/*"
    ]
  }

}

resource "azurerm_cosmosdb_sql_database" "cosmosdb" {
  name                = "cosmos-${var.application_name}-001"
  resource_group_name = azurerm_cosmosdb_account.cosmosdb.resource_group_name
  account_name        = azurerm_cosmosdb_account.cosmosdb.name
  autoscale_settings {
    max_throughput = 1000000
  }
}

resource "azurerm_cosmosdb_sql_container" "products_container" {
  account_name        = azurerm_cosmosdb_account.cosmosdb.name
  database_name       = azurerm_cosmosdb_sql_database.cosmosdb.name
  resource_group_name = azurerm_cosmosdb_sql_database.cosmosdb.resource_group_name
  name                = "products"
  partition_key_path  = "/id"
}
