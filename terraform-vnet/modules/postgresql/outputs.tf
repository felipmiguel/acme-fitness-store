output "database_url" {
  value       = "${azurerm_postgresql_flexible_server.database.fqdn}:5432/${azurerm_postgresql_flexible_server_database.database.name}"
  description = "The PostgreSQL server URL."
}

output "database_username" {
  value       = var.administrator_login
  description = "The PostgreSQL server user name."
}

output "database_password" {
  value       = random_password.password.result
  sensitive   = true
  description = "The PostgreSQL server password."
}

output "database_id" {
  value       = azurerm_postgresql_flexible_server_database.database.id
  description = "The PostgreSQL server database id."
}

output "database_name" {
  value       = azurerm_postgresql_flexible_server_database.database.name
  description = "The PostgreSQL server database name."
}

output "database_fqdn" {
  value       = azurerm_postgresql_flexible_server.database.fqdn
  description = "The PostgreSQL server database host."
}