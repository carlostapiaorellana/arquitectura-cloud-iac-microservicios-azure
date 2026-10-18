output "id" {
  description = "ID del recurso de Azure Container App."
  value       = azurerm_container_app.this.id
}

output "container_app_id" {
  description = "Alias del ID de Azure Container App."
  value       = azurerm_container_app.this.id
}

output "name" {
  description = "Nombre de la Container App."
  value       = azurerm_container_app.this.name
}

output "container_app_name" {
  description = "Alias del nombre de la Container App."
  value       = azurerm_container_app.this.name
}

output "latest_revision_name" {
  description = "Nombre de la última revisión desplegada de la Container App."
  value       = azurerm_container_app.this.latest_revision_name
}

output "latest_revision_fqdn" {
  description = "FQDN de la última revisión activa de la Container App."
  value       = azurerm_container_app.this.latest_revision_fqdn
}

output "ingress_fqdn" {
  description = "FQDN de ingreso de la Container App (público o interno según external_enabled)."
  value       = try(azurerm_container_app.this.ingress[0].fqdn, null)
}

output "fqdn" {
  description = "Alias del FQDN de ingreso de la Container App."
  value       = try(azurerm_container_app.this.ingress[0].fqdn, null)
}
