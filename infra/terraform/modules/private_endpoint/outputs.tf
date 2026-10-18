output "id" {
  description = "ID de recurso del Private Endpoint en Azure."
  value       = azurerm_private_endpoint.this.id
}

output "private_endpoint_id" {
  description = "Alias del ID de recurso del Private Endpoint en Azure."
  value       = azurerm_private_endpoint.this.id
}

output "name" {
  description = "Nombre del Private Endpoint aprovisionado."
  value       = azurerm_private_endpoint.this.name
}

output "private_ip_address" {
  description = "Dirección IPv4 privada asignada a la interfaz de red del Private Endpoint."
  value       = azurerm_private_endpoint.this.private_service_connection[0].private_ip_address
}
