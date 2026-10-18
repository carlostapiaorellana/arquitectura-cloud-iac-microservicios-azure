output "resource_group_name" {
  description = "Nombre del Resource Group donde se aloja el Storage Account del backend remoto."
  value       = azurerm_resource_group.this.name
}

output "storage_account_id" {
  description = "ID del Storage Account creado para el backend de Terraform."
  value       = azurerm_storage_account.this.id
}

output "storage_account_name" {
  description = "Nombre del Storage Account para configurar el backend remoto de Terraform."
  value       = azurerm_storage_account.this.name
}

output "container_name" {
  description = "Nombre del contenedor de blobs donde se almacena el archivo tfstate."
  value       = azurerm_storage_container.this.name
}

output "primary_access_key" {
  description = "Clave primaria de acceso al Storage Account (sensible)."
  value       = azurerm_storage_account.this.primary_access_key
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Outputs de Federación OIDC listos para GitHub Actions (Variables / Secretos)
# -----------------------------------------------------------------------------
output "azure_client_id" {
  description = "Client ID para GitHub Actions secret/variable AZURE_CLIENT_ID."
  value       = module.azure_oidc_github.client_id
}

output "azure_tenant_id" {
  description = "Tenant ID para GitHub Actions secret/variable AZURE_TENANT_ID."
  value       = module.azure_oidc_github.tenant_id
}

output "azure_subscription_id" {
  description = "Subscription ID para GitHub Actions secret/variable AZURE_SUBSCRIPTION_ID."
  value       = var.subscription_id
}
