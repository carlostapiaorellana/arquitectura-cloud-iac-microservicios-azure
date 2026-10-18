output "id" {
  description = "ID del recurso del Network Security Group."
  value       = azurerm_network_security_group.this.id
}

output "nsg_id" {
  description = "Alias del ID del recurso del Network Security Group."
  value       = azurerm_network_security_group.this.id
}

output "name" {
  description = "Nombre del Network Security Group aprovisionado."
  value       = azurerm_network_security_group.this.name
}

output "nsg_name" {
  description = "Alias del nombre del Network Security Group aprovisionado."
  value       = azurerm_network_security_group.this.name
}
