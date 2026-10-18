output "id" {
  description = "ID de la asociación entre la subred y el Network Security Group."
  value       = azurerm_subnet_network_security_group_association.this.id
}

output "subnet_id" {
  description = "ID de la subred asociada."
  value       = azurerm_subnet_network_security_group_association.this.subnet_id
}

output "network_security_group_id" {
  description = "ID del Network Security Group asociado."
  value       = azurerm_subnet_network_security_group_association.this.network_security_group_id
}
