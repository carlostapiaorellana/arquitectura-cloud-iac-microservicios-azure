output "id" {
  description = "ID de recurso del Azure Key Vault."
  value       = azurerm_key_vault.this.id
}

output "key_vault_id" {
  description = "Alias del ID de recurso del Azure Key Vault."
  value       = azurerm_key_vault.this.id
}

output "name" {
  description = "Nombre del Azure Key Vault aprovisionado."
  value       = azurerm_key_vault.this.name
}

output "key_vault_name" {
  description = "Alias del nombre del Azure Key Vault aprovisionado."
  value       = azurerm_key_vault.this.name
}

output "vault_uri" {
  description = "URI HTTPS del endpoint del Azure Key Vault."
  value       = azurerm_key_vault.this.vault_uri
}

output "key_vault_uri" {
  description = "Alias de la URI HTTPS del endpoint del Azure Key Vault."
  value       = azurerm_key_vault.this.vault_uri
}
