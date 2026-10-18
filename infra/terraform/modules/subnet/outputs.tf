output "id" {
  description = "ID del recurso de la subred en Azure."
  value       = azurerm_subnet.this.id
}

output "subnet_id" {
  description = "Alias del ID del recurso de la subred en Azure."
  value       = azurerm_subnet.this.id
}

output "name" {
  description = "Nombre de la subred aprovisionada."
  value       = azurerm_subnet.this.name
}

output "subnet_name" {
  description = "Alias del nombre de la subred aprovisionada."
  value       = azurerm_subnet.this.name
}

output "address_prefixes" {
  description = "Lista de prefijos de dirección CIDR asignados a la subred."
  value       = azurerm_subnet.this.address_prefixes
}
