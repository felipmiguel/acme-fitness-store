terraform {
  required_providers {
    azurecaf = {
      source  = "aztfmod/azurecaf"
      version = "1.2.22"
    }
  }
}

data "azurerm_client_config" "current" {}

data "azuread_service_principal" "asa_id" {
  display_name = "Azure Spring Cloud Domain-Management"
}

resource "azurecaf_name" "kv" {
  name          = var.application_name
  resource_type = "azurerm_key_vault"
  suffixes      = [var.environment]
}

resource "azurerm_key_vault" "kv" {
  name                = azurecaf_name.kv.result
  resource_group_name = var.resource_group
  location            = var.location

  tenant_id                     = data.azurerm_client_config.current.tenant_id
  sku_name                      = "standard"
  public_network_access_enabled = true
}

resource "azurerm_key_vault_access_policy" "asa_access_policy" {
  key_vault_id = azurerm_key_vault.kv.id
  object_id    = data.azuread_service_principal.asa_id.object_id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  certificate_permissions = [
    "Get",
    "List"
  ]
  secret_permissions = [
    "Get",
    "List"
  ]
}

resource "azurerm_key_vault_access_policy" "current_user" {
  key_vault_id = azurerm_key_vault.kv.id
  object_id    = data.azurerm_client_config.current.object_id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  certificate_permissions = [
    "Create",
    "Delete",
    "DeleteIssuers",
    "Get",
    "GetIssuers",
    "Import",
    "List",
    "ListIssuers",
    "ManageContacts",
    "ManageIssuers",
    "Purge",
    "SetIssuers",
    "Update",
    "Recover",
    "Restore",
    "Backup"
  ]
  key_permissions = [
    "Backup",
    "Create",
    "Decrypt",
    "Delete",
    "Encrypt",
    "Get",
    "Import",
    "List",
    "Purge",
    "Recover",
    "Restore",
    "Sign",
    "UnwrapKey",
    "Update",
    "Verify",
    "WrapKey",
  ]
  secret_permissions = [
    "Backup",
    "Delete",
    "Get",
    "List",
    "Purge",
    "Recover",
    "Restore",
    "Set",
  ]
}


# network setup
resource "azurerm_private_endpoint" "kv_pe" {
  name                = "${azurecaf_name.kv.result}-pe"
  location            = var.location
  resource_group_name = var.resource_group
  subnet_id           = var.subnet_id

  private_service_connection {
    name                           = "${azurecaf_name.kv.result}-privateserviceconnection"
    private_connection_resource_id = azurerm_key_vault.kv.id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "private-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.private_dns_zone.id]
  }
}

resource "azurerm_private_dns_zone" "private_dns_zone" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = var.resource_group
}

resource "azurerm_private_dns_zone_virtual_network_link" "private_dns_zone_link" {
  name                  = "kv-dns-link"
  resource_group_name   = var.resource_group
  private_dns_zone_name = azurerm_private_dns_zone.private_dns_zone.name
  virtual_network_id    = var.virtual_network_id
}

resource "azurerm_private_dns_a_record" "a_record" {
  name                = "*"
  zone_name           = azurerm_private_dns_zone.private_dns_zone.name
  resource_group_name = var.resource_group
  ttl                 = 300
  records             = [azurerm_private_endpoint.kv_pe.private_service_connection[0].private_ip_address]
}


resource "azurerm_key_vault_certificate" "self_signed_cert" {
  name         = "self-${var.application_name}-gw-cert"
  key_vault_id = azurerm_key_vault.kv.id

  certificate_policy {
    issuer_parameters {
      name = "Self"
    }

    key_properties {
      exportable = true
      key_size   = 2048
      key_type   = "RSA"
      reuse_key  = true
    }

    lifetime_action {
      action {
        action_type = "AutoRenew"
      }

      trigger {
        days_before_expiry = 30
      }
    }

    secret_properties {
      content_type = "application/x-pkcs12"
    }

    x509_certificate_properties {
      # Server Authentication = 1.3.6.1.5.5.7.3.1
      # Client Authentication = 1.3.6.1.5.5.7.3.2
      extended_key_usage = ["1.3.6.1.5.5.7.3.1"]

      key_usage = [
        "cRLSign",
        "dataEncipherment",
        "digitalSignature",
        "keyAgreement",
        "keyCertSign",
        "keyEncipherment",
      ]
      subject_alternative_names {
        dns_names = [var.dns_name]
      }

      subject            = "C=US, ST=WA, L=Redmond, O=Contoso, OU=Contoso HR, CN=${var.dns_name}"
      validity_in_months = 12
    }
  }
}
