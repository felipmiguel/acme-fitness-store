terraform {
  required_providers {
    azurecaf = {
      source  = "aztfmod/azurecaf"
      version = "1.2.22"
    }
  }
}

resource "azurerm_private_dns_zone" "database" {
  name                = var.dns_zone
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