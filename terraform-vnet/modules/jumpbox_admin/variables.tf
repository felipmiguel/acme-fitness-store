variable "vm_id" {
  type        = string
  description = "The ID of the VM to assign the role to."
}

variable "aad_admin_username" {
  type        = string
  description = "The AAD username of the user to assign the role to."
}
