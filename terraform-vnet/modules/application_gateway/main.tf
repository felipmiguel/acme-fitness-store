terraform {
  required_providers {
    azurecaf = {
      source  = "aztfmod/azurecaf"
      version = "1.2.22"
    }
  }
}

resource "azurecaf_name" "app_gw_public_ip" {
  name          = var.application_name
  resource_type = "azurerm_public_ip"
  suffixes      = [var.environment, "appgw"]
}

resource "azurerm_public_ip" "app_gw_public_ip" {
  name                = azurecaf_name.app_gw_public_ip.result
  location            = var.location
  resource_group_name = var.resource_group
  allocation_method   = "Static"
  sku                 = "Standard"
}



locals {
  backend_address_pool_name      = "${var.application_name}-beap"
  frontend_port_name             = "${var.application_name}-feport"
  frontend_ip_configuration_name = "${var.application_name}-feip"
  http_setting_name              = "${var.application_name}-be-htst"
  listener_name                  = "${var.application_name}-httplstn"
  request_routing_rule_name      = "${var.application_name}-rqrt"
  redirect_configuration_name    = "${var.application_name}-rdrcfg"
  rootcert_name                  = "${var.application_name}-rootcert"
  cert_name                      = "${var.application_name}-cert"
  probe_name                     = "${var.application_name}-probe"
}

resource "azurecaf_name" "app_gateway" {
  name          = var.application_name
  resource_type = "azurerm_application_gateway"
  suffixes      = [var.environment, "appgw"]
}

resource "azurerm_application_gateway" "app_gateway" {
  name                = azurecaf_name.app_gateway.result
  location            = var.location
  resource_group_name = var.resource_group

  sku {
    name = "WAF_v2"
    tier = "WAF_v2"
  }
  autoscale_configuration {
    min_capacity = 1
    max_capacity = 125
  }

  frontend_port {
    name = "${local.frontend_port_name}-http"
    port = 80
  }

  frontend_port {
    name = local.frontend_port_name
    port = 443
  }

  gateway_ip_configuration {
    name      = "gateway_subnet_config"
    subnet_id = var.appgateway_subnet_id
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.app_gw_public_ip.id
  }

  backend_address_pool {
    name  = local.backend_address_pool_name
    fqdns = [var.backend_fqdn]
  }

  backend_http_settings {
    name                                = local.http_setting_name
    cookie_based_affinity               = "Disabled"
    port                                = 443
    protocol                            = "Https"
    request_timeout                     = 60
    pick_host_name_from_backend_address = false
    trusted_root_certificate_names      = [local.rootcert_name]
    probe_name                          = local.probe_name
  }

  probe {
    interval = 30
    name     = local.probe_name
    host                = var.dns_name
    pick_host_name_from_backend_http_settings = false
    protocol                                  = "Https"
    path                                      = "/"
    timeout                                   = 30
    unhealthy_threshold                       = 3
  }

  # http_listener {
  #   name                           = "${local.listener_name}-https"
  #   frontend_ip_configuration_name = local.frontend_ip_configuration_name
  #   frontend_port_name             = local.frontend_port_name
  #   protocol                       = "Https"
  #   firewall_policy_id             = azurerm_web_application_firewall_policy.waf_policy.id
  # }

  http_listener {
    name                           = "${local.listener_name}-http"
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = "${local.frontend_port_name}-http"
    protocol                       = "Http"
    firewall_policy_id             = azurerm_web_application_firewall_policy.waf_policy.id
  }

  http_listener {
    name                           = "${local.listener_name}-https"
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.frontend_port_name
    protocol                       = "Https"
    ssl_certificate_name           = local.cert_name
    firewall_policy_id             = azurerm_web_application_firewall_policy.waf_policy.id
  }

  request_routing_rule {
    name                       = "${local.request_routing_rule_name}-http"
    rule_type                  = "Basic"
    http_listener_name         = "${local.listener_name}-http"
    backend_address_pool_name  = local.backend_address_pool_name
    backend_http_settings_name = local.http_setting_name
    priority                   = 200
  }

  request_routing_rule {
    name                       = "${local.request_routing_rule_name}-https"
    rule_type                  = "Basic"
    http_listener_name         = "${local.listener_name}-https"
    backend_address_pool_name  = local.backend_address_pool_name
    backend_http_settings_name = local.http_setting_name
    priority                   = 100
  }

  trusted_root_certificate {
    name                = local.rootcert_name
    key_vault_secret_id = var.certificate_secret_id
  }

  ssl_certificate {
    name                = local.cert_name
    key_vault_secret_id = var.certificate_secret_id
  }

  # waf_configuration {
  #   enabled          = true
  #   firewall_mode    = "Detection"
  #   rule_set_type    = "OWASP"
  #   rule_set_version = "3.1"
  # }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.appgw_id.id]
  }
}

resource "azurerm_web_application_firewall_policy" "waf_policy" {
  name                = "acmefitness-wafpolicy"
  resource_group_name = var.resource_group
  location            = var.location

  policy_settings {
    enabled = true
    mode    = "Detection"
  }

  managed_rules {
    managed_rule_set {
      type    = "OWASP"
      version = "3.1"
    }
  }
}

resource "azurecaf_name" "appgw_id" {
  name          = var.application_name
  resource_type = "azurerm_user_assigned_identity"
  suffixes      = [var.environment, "appgw"]
}

resource "azurerm_user_assigned_identity" "appgw_id" {
  resource_group_name = var.resource_group
  location            = var.location
  name                = azurecaf_name.appgw_id.result
}

resource "azurerm_key_vault_access_policy" "appgateway_access_policy" {
  key_vault_id = var.keyvault_id
  object_id    = azurerm_user_assigned_identity.appgw_id.principal_id
  tenant_id    = azurerm_user_assigned_identity.appgw_id.tenant_id
  certificate_permissions = [
    "Get",
    "List"
  ]
  secret_permissions = [
    "Get",
    "List"
  ]
}
