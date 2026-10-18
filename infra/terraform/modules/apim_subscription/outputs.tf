output "id" {
  value       = azurerm_api_management_subscription.this.id
  description = "Resource ID de la suscripción de Azure API Management."
}

output "subscription_id" {
  value       = azurerm_api_management_subscription.this.subscription_id
  description = "Identificador de la suscripción."
}

output "primary_key" {
  value       = azurerm_api_management_subscription.this.primary_key
  description = "Clave primaria de acceso para Ocp-Apim-Subscription-Key (sensible)."
  sensitive   = true
}

output "secondary_key" {
  value       = azurerm_api_management_subscription.this.secondary_key
  description = "Clave secundaria de acceso para rotación de credenciales (sensible)."
  sensitive   = true
}
