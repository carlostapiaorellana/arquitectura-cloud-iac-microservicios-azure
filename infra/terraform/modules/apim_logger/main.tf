resource "azurerm_api_management_logger" "this" {
  name                = coalesce(var.logger_name, var.name)
  api_management_name = var.api_management_name
  resource_group_name = var.resource_group_name
  buffered            = var.buffered
  description         = var.description

  application_insights {
    instrumentation_key = var.instrumentation_key
    connection_string   = var.connection_string
  }

  lifecycle {
    precondition {
      condition     = var.logger_name != null || var.name != null
      error_message = "Debe especificar 'logger_name' o 'name' para el logger de APIM."
    }
  }
}
