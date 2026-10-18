output "resource_group_name" {
  value       = azurerm_resource_group.rg.name
  description = "Nombre del Resource Group principal de desarrollo."
}

output "apim_gateway_url" {
  value       = module.apim_service.gateway_url
  description = "URL pública de entrada perimetral de Azure API Management."
}

output "ca_gateway_fqdn" {
  value       = module.ca_gateway.ingress_fqdn
  description = "FQDN HTTPS perimetral de la Container App del API Gateway en Go."
}

output "acr_login_server" {
  value       = module.container_registry.login_server
  description = "Servidor de inicio de sesión de Azure Container Registry."
}

output "mysql_server_fqdn" {
  value       = module.mysql_server.fqdn
  description = "FQDN privado del servidor MySQL Flexible."
}

output "service_bus_fqdn" {
  value       = module.service_bus.fqdn
  description = "FQDN del namespace de Azure Service Bus."
}

output "key_vault_uri" {
  value       = module.key_vault.vault_uri
  description = "URI del almacén Azure Key Vault."
}

output "web_subscription_primary_key" {
  value       = module.apim_subscription_web.primary_key
  description = "Clave primaria de suscripción para el Portal Web Estudiantil (sensible)."
  sensitive   = true
}
