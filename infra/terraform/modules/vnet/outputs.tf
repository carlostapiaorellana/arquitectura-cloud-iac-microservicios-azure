output "id" {
  description = "ID del recurso de la red virtual (Azure Resource ID)."
  value       = azurerm_virtual_network.this.id
}

output "vnet_id" {
  description = "Alias del ID del recurso de la red virtual."
  value       = azurerm_virtual_network.this.id
}

output "name" {
  description = "Nombre de la red virtual aprovisionada."
  value       = azurerm_virtual_network.this.name
}

output "vnet_name" {
  description = "Alias del nombre de la red virtual aprovisionada."
  value       = azurerm_virtual_network.this.name
}

output "address_space" {
  description = "Espacio de direcciones CIDR asignado a la red virtual."
  value       = azurerm_virtual_network.this.address_space
}

output "location" {
  description = "Región de Azure donde reside la red virtual."
  value       = azurerm_virtual_network.this.location
}
