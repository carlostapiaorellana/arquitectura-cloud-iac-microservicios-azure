output "id" {
  value       = azurerm_api_management_product.this.id
  description = "ID del producto en Azure API Management."
}

output "product_id" {
  value       = azurerm_api_management_product.this.product_id
  description = "Identificador único del producto."
}

output "display_name" {
  value       = azurerm_api_management_product.this.display_name
  description = "Nombre descriptivo del producto."
}

output "api_names" {
  value       = var.api_names
  description = "Lista de APIs vinculadas al producto."
}
