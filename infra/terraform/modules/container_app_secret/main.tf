resource "azurerm_key_vault_secret" "this" {
  name            = coalesce(var.secret_name, var.name)
  value           = var.value
  key_vault_id    = var.key_vault_id
  content_type    = var.content_type
  expiration_date = var.expiration_date
  tags            = var.tags

  lifecycle {
    precondition {
      condition     = var.secret_name != null || var.name != null
      error_message = "Debe especificar 'secret_name' o 'name' para el secreto de Key Vault."
    }
  }
}
