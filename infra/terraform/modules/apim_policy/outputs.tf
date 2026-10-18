output "id" {
  value       = try(azurerm_api_management_api_policy.this[0].id, azurerm_api_management_policy.this[0].id, null)
  description = "ID de la política de Azure API Management creada."
}

output "xml_content" {
  value       = local.effective_xml_content
  description = "Contenido XML aplicado en la política perimetral."
}
