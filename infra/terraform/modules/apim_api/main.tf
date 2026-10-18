resource "azurerm_api_management_api" "this" {
  name                  = coalesce(var.api_name, var.name)
  resource_group_name   = var.resource_group_name
  api_management_name   = var.api_management_name
  revision              = var.revision
  display_name          = var.display_name
  path                  = var.path
  protocols             = var.protocols
  service_url           = var.service_url
  subscription_required = var.subscription_required
  description           = var.description

  subscription_key_parameter_names {
    header = var.subscription_key_parameter_names_header
    query  = var.subscription_key_parameter_names_query
  }

  lifecycle {
    precondition {
      condition     = var.api_name != null || var.name != null
      error_message = "Debe especificar 'api_name' o 'name' para la API de Azure API Management."
    }
  }
}
