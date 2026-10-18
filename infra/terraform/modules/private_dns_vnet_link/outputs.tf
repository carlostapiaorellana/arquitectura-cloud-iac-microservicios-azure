output "id" {
  description = "ID de recurso del Virtual Network Link de la Zona DNS Privada."
  value       = azurerm_private_dns_zone_virtual_network_link.this.id
}

output "name" {
  description = "Nombre del Virtual Network Link creado."
  value       = azurerm_private_dns_zone_virtual_network_link.this.name
}
