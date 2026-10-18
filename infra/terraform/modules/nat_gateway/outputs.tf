output "id" {
  description = "ID de recurso del Azure NAT Gateway."
  value       = azurerm_nat_gateway.this.id
}

output "nat_gateway_id" {
  description = "Alias del ID de recurso del Azure NAT Gateway."
  value       = azurerm_nat_gateway.this.id
}

output "name" {
  description = "Nombre del Azure NAT Gateway aprovisionado."
  value       = azurerm_nat_gateway.this.name
}

output "public_ip_id" {
  description = "ID de recurso de la IP pública estática asociada al NAT Gateway."
  value       = azurerm_public_ip.this.id
}

output "public_ip_address" {
  description = "Dirección IPv4 pública estática de salida SNAT asignada al NAT Gateway."
  value       = azurerm_public_ip.this.ip_address
}
