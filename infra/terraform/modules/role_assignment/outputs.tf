output "id" {
  description = "ID de recurso de la asignación de rol en Azure RBAC."
  value       = azurerm_role_assignment.this.id
}

output "role_definition_name" {
  description = "Nombre de la definición de rol asignada."
  value       = azurerm_role_assignment.this.role_definition_name
}

output "principal_id" {
  description = "Object ID (Principal ID) del sujeto al que se asignó el rol."
  value       = azurerm_role_assignment.this.principal_id
}

output "scope" {
  description = "Alcance (Resource ID) sobre el cual se otorgó el rol."
  value       = azurerm_role_assignment.this.scope
}
