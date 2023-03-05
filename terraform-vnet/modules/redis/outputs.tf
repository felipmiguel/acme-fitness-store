output "azure_redis_host" {
  value       = azurerm_redis_cache.redis.hostname
  description = "The Redis server URL."
}

output "azure_redis_id" {
  value       = azurerm_redis_cache.redis.id
  description = "The Redis server ID."  
}

output "azure_redis_password" {
  value       = azurerm_redis_cache.redis.primary_access_key
  sensitive   = true
  description = "The Redis server password."
}

output "azure_redis_connection_string" {
  value       = azurerm_redis_cache.redis.primary_connection_string
  description = "The Redis server connection string."
}
