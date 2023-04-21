output "kv_id" {
  value = azurerm_key_vault.kv.id
}


# output "certificate_secret_id" {
#   value = azurerm_key_vault_certificate.self_signed_cert.secret_id
# }

# output "certificate_id" {
#   value = azurerm_key_vault_certificate.self_signed_cert.id
# }

# output "certificate_name" {
#   value = azurerm_key_vault_certificate.self_signed_cert.name
# }

# output "certificate_thumbprint" {
#   value = azurerm_key_vault_certificate.self_signed_cert.thumbprint  
# }


output "certificate_secret_id" {
  value = data.azurerm_key_vault_certificate.public_certificate.secret_id
}

output "certificate_id" {
  value = data.azurerm_key_vault_certificate.public_certificate.id
}

output "certificate_name" {
  value = data.azurerm_key_vault_certificate.public_certificate.name
}

output "certificate_thumbprint" {
  value = data.azurerm_key_vault_certificate.public_certificate.thumbprint  
}