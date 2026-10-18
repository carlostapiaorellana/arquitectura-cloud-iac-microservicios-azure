resource "azurerm_api_management" "this" {
  name                = coalesce(var.service_name, var.name)
  location            = var.location
  resource_group_name = var.resource_group_name
  publisher_name      = var.publisher_name
  publisher_email     = var.publisher_email
  sku_name            = var.sku_name

  min_api_version            = var.min_api_version
  virtual_network_type       = var.virtual_network_type
  client_certificate_enabled = var.client_certificate_enabled

  identity {
    type = var.identity_type
  }

  tags = var.tags

  lifecycle {
    precondition {
      condition     = var.service_name != null || var.name != null
      error_message = "Debe especificar 'service_name' o 'name' para la instancia de Azure API Management."
    }
    precondition {
      condition     = var.sku_name != "Consumption_0" || var.virtual_network_type == "None"
      error_message = "En el SKU 'Consumption_0', la integración de red virtual no está soportada; 'virtual_network_type' debe ser 'None'."
    }
  }
}
