data "azuread_user" "vm_admin" {
  user_principal_name = var.aad_admin_username
}

resource "azurerm_role_assignment" "vm_admins" {
  scope                = var.vm_id
  role_definition_name = "Virtual Machine Administrator Login"
  principal_id         = data.azuread_user.vm_admin.object_id
}
