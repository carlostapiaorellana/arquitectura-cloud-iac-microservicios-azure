resource "azurerm_role_assignment" "this" {
  scope                            = var.scope
  principal_id                     = var.principal_id
  role_definition_name             = var.role_definition_name
  role_definition_id               = var.role_definition_id
  principal_type                   = var.principal_type
  skip_service_principal_aad_check = var.skip_service_principal_aad_check

  lifecycle {
    precondition {
      condition     = (var.role_definition_name != null && var.role_definition_id == null) || (var.role_definition_name == null && var.role_definition_id != null)
      error_message = "Debe especificar exactamente uno de 'role_definition_name' o 'role_definition_id' (no ambos ni ninguno)."
    }
  }
}
