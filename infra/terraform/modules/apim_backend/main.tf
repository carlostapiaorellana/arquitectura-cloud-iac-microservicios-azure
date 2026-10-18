resource "azurerm_api_management_backend" "this" {
  name                = coalesce(var.backend_name, var.name)
  api_management_name = var.api_management_name
  resource_group_name = var.resource_group_name
  protocol            = var.protocol
  url                 = var.url
  description         = var.description
  title               = var.title

  tls {
    validate_certificate_chain = var.validate_certificate_chain
    validate_certificate_name  = var.validate_certificate_name
  }

  lifecycle {
    precondition {
      condition     = var.backend_name != null || var.name != null
      error_message = "Debe especificar 'backend_name' o 'name' para el backend de APIM."
    }
  }
}
