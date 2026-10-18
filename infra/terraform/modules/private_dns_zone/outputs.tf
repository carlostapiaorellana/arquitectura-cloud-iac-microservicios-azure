output "id" {
  description = "ID de recurso de la Zona DNS Privada en Azure."
  value       = azurerm_private_dns_zone.this.id
}

output "dns_zone_id" {
  description = "Alias del ID de recurso de la Zona DNS Privada en Azure."
  value       = azurerm_private_dns_zone.this.id
}

output "name" {
  description = "Nombre FQDN de la Zona DNS Privada."
  value       = azurerm_private_dns_zone.this.name
}

output "dns_zone_name" {
  description = "Alias del nombre FQDN de la Zona DNS Privada."
  value       = azurerm_private_dns_zone.this.name
}
