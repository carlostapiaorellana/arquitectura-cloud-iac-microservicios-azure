output "id" {
  description = "ID del recurso de Azure Cache for Redis."
  value       = azurerm_redis_cache.this.id
}

output "redis_id" {
  description = "Alias del ID del recurso de Azure Cache for Redis."
  value       = azurerm_redis_cache.this.id
}

output "name" {
  description = "Nombre de la instancia de Azure Cache for Redis."
  value       = azurerm_redis_cache.this.name
}

output "redis_name" {
  description = "Alias del nombre de la instancia de Azure Cache for Redis."
  value       = azurerm_redis_cache.this.name
}

output "hostname" {
  description = "Hostname para la conexión con el servidor de Redis."
  value       = azurerm_redis_cache.this.hostname
}

output "redis_hostname" {
  description = "Alias del hostname para la conexión con el servidor de Redis."
  value       = azurerm_redis_cache.this.hostname
}

output "ssl_port" {
  description = "Puerto seguro SSL (6380) para conexiones TLS con Redis."
  value       = azurerm_redis_cache.this.ssl_port
}

output "redis_ssl_port" {
  description = "Alias del puerto seguro SSL (6380) para conexiones TLS con Redis."
  value       = azurerm_redis_cache.this.ssl_port
}

output "port" {
  description = "Puerto estándar sin cifrado (6379, deshabilitado por defecto)."
  value       = azurerm_redis_cache.this.port
}

output "primary_access_key" {
  description = "Clave primaria sensible para autenticación en Redis."
  value       = azurerm_redis_cache.this.primary_access_key
  sensitive   = true
}

output "secondary_access_key" {
  description = "Clave secundaria sensible para rotación de credenciales en Redis."
  value       = azurerm_redis_cache.this.secondary_access_key
  sensitive   = true
}

output "primary_connection_string" {
  description = "Cadena de conexión primaria sensible para Redis."
  value       = azurerm_redis_cache.this.primary_connection_string
  sensitive   = true
}
