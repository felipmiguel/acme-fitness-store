variable "resource_group" {
  type        = string
  description = "The resource group"
  default     = ""
}

variable "application_name" {
  type        = string
  description = "The name of your application"
  default     = ""
}

variable "environment" {
  type        = string
  description = "The environment (dev, test, prod...)"
  default     = "dev"
}

variable "location" {
  type        = string
  description = "The Azure region where all resources in this example should be created"
  default     = ""
}

variable "bastion_subnet_id" {
  type        = string
  description = "The Subnet from which the access is allowed"
}

variable "vm_subnet_id" {
  type        = string
  description = "The Subnet from which the access is allowed"
}

variable "admin_password" {
  type        = string
  description = "The password for the administrator account of the virtual machine."
}

variable "aad_admin_username" {
  type        = string
  description = "The username for the administrator account of the virtual machine."
}

variable "enroll_with_mdm" {
  type        = bool
  description = "Enroll the VM with Azure Monitor for VMs"
  default     = false
}