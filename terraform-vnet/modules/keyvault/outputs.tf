output "kv_id" {
  value = azurerm_key_vault.kv.id
}


output "certificate_secret_id" {
  value = azurerm_key_vault_certificate.self_signed_cert.secret_id
}

output "certificate_id" {
  value = azurerm_key_vault_certificate.self_signed_cert.id
}

output "certificate_name" {
  value = azurerm_key_vault_certificate.self_signed_cert.name
}

output "certificate_thumbprint" {
  value = azurerm_key_vault_certificate.self_signed_cert.thumbprint  
}
