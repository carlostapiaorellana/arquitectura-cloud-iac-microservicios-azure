output "id" {
  description = "ID del recurso de Azure Container Registry."
  value       = azurerm_container_registry.this.id
}

output "acr_id" {
  description = "Alias del ID de Azure Container Registry."
  value       = azurerm_container_registry.this.id
}

output "name" {
  description = "Nombre del Azure Container Registry."
  value       = azurerm_container_registry.this.name
}

output "acr_name" {
  description = "Alias del nombre de Azure Container Registry."
  value       = azurerm_container_registry.this.name
}

output "login_server" {
  description = "Servidor de inicio de sesión (login server) para docker tag y docker push."
  value       = azurerm_container_registry.this.login_server
}

output "acr_login_server" {
  description = "Alias del login server del Azure Container Registry."
  value       = azurerm_container_registry.this.login_server
}

output "admin_username" {
  description = "Nombre de usuario administrador del ACR (solo si admin_enabled = true)."
  value       = azurerm_container_registry.this.admin_username
  sensitive   = true
}

output "admin_password" {
  description = "Contraseña de administrador del ACR (solo si admin_enabled = true)."
  value       = azurerm_container_registry.this.admin_password
  sensitive   = true
}
