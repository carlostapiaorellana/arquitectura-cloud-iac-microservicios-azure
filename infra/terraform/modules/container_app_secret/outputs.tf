output "id" {
  description = "ID versionado del secreto en Azure Key Vault."
  value       = azurerm_key_vault_secret.this.id
}

output "versionless_id" {
  description = "ID sin versión del secreto en Azure Key Vault (recomendado para referencias automáticas en Azure Container Apps)."
  value       = azurerm_key_vault_secret.this.versionless_id
}

output "name" {
  description = "Nombre del secreto en Azure Key Vault."
  value       = azurerm_key_vault_secret.this.name
}

output "secret_name" {
  description = "Alias del nombre del secreto."
  value       = azurerm_key_vault_secret.this.name
}

output "aca_secret_reference" {
  description = "Estructura de referencia para el bloque secret de azurerm_container_app."
  value = {
    name                = azurerm_key_vault_secret.this.name
    key_vault_secret_id = azurerm_key_vault_secret.this.versionless_id
    identity            = var.identity_id
  }
}
