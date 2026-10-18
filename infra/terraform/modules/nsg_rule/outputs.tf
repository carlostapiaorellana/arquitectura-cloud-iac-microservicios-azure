output "id" {
  description = "ID del recurso de la regla de seguridad de red en Azure."
  value       = azurerm_network_security_rule.this.id
}

output "name" {
  description = "Nombre de la regla de seguridad de red."
  value       = azurerm_network_security_rule.this.name
}

output "priority" {
  description = "Prioridad numérica asignada a la regla NSG."
  value       = azurerm_network_security_rule.this.priority
}
