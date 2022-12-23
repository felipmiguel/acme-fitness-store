terraform {
  required_providers {
    azurecaf = {
      source  = "aztfmod/azurecaf"
      version = "1.2.22"
    }
  }
}

resource "azurecaf_name" "bastion_public_ip" {
  name          = var.application_name
  resource_type = "azurerm_public_ip"
  suffixes      = [var.environment, "bastion"]
}

resource "azurerm_public_ip" "bastion_public_ip" {
  name                = azurecaf_name.bastion_public_ip.result
  location            = var.location
  resource_group_name = var.resource_group
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurecaf_name" "bastion_host" {
  name          = var.application_name
  resource_type = "azurerm_bastion_host"
  suffixes      = [var.environment, "bastion"]
}

resource "azurerm_bastion_host" "bastion_host" {
  name                = azurecaf_name.bastion_host.result
  location            = var.location
  resource_group_name = var.resource_group
  sku                 = "Standard"

  ip_configuration {
    name                 = "configuration"
    subnet_id            = var.bastion_subnet_id
    public_ip_address_id = azurerm_public_ip.bastion_public_ip.id
  }

  tunneling_enabled = true
}

resource "azurecaf_name" "jumpbox_vm_nic" {
  name          = var.application_name
  resource_type = "azurerm_network_interface"
  suffixes      = [var.environment, "jumpbox"]
}

resource "azurerm_network_interface" "jumpbox_vm_nic" {
  name                = azurecaf_name.jumpbox_vm_nic.result
  location            = var.location
  resource_group_name = var.resource_group

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.vm_subnet_id
    private_ip_address_allocation = "Dynamic"
    # public_ip_address_id          = azurerm_public_ip.bastion_public_ip.id
  }
}

resource "azurecaf_name" "jumpbox_vm" {
  name          = var.application_name
  resource_type = "azurerm_windows_virtual_machine"
  suffixes      = [var.environment, "jumpbox"]
}

resource "azurerm_windows_virtual_machine" "jumpbox_vm" {
  name                = azurecaf_name.jumpbox_vm.result
  computer_name       = "acme-jumpbox"
  location            = var.location
  resource_group_name = var.resource_group
  size                = "Standard_D2as_v5"
  admin_username      = "adminuser"
  admin_password      = var.admin_password
  network_interface_ids = [
    azurerm_network_interface.jumpbox_vm_nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  identity {
    type = "SystemAssigned"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsDesktop"
    offer     = "windows-11"
    sku       = "win11-22h2-pro"
    version   = "latest"
  }

  provision_vm_agent         = true
  allow_extension_operations = true
  

}

data "azuread_user" "vm-admin" {
  user_principal_name = var.aad_admin_username
}

resource "azurerm_role_assignment" "vm-admins" {
  scope                = azurerm_windows_virtual_machine.jumpbox_vm.id
  role_definition_name = "Virtual Machine Administrator Login"
  principal_id         = data.azuread_user.vm-admin.object_id
}

resource "azurerm_virtual_machine_extension" "aad" {
  name                       = "aad-login-for-windows"
  publisher                  = "Microsoft.Azure.ActiveDirectory"
  type                       = "AADLoginForWindows"
  type_handler_version       = "1.0"
  auto_upgrade_minor_version = true
  virtual_machine_id         = azurerm_windows_virtual_machine.jumpbox_vm.id

  settings = !var.enroll_with_mdm ? null : <<SETTINGS
    {
      "mdmId": "0000000a-0000-0000-c000-000000000000"
    }
  SETTINGS
}

