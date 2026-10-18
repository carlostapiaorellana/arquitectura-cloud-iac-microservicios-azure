resource "azurerm_servicebus_namespace_authorization_rule" "this" {
  count        = var.enable_rule ? 1 : 0
  name         = coalesce(var.rule_name, var.name)
  namespace_id = var.namespace_id
  listen       = var.listen
  send         = var.send
  manage       = var.manage

  lifecycle {
    precondition {
      condition     = !(var.manage == true && (var.listen == false || var.send == false))
      error_message = "Regla de Azure Service Bus: Si 'manage' es true, 'listen' y 'send' deben ser ambos true obligatoriamente."
    }
    precondition {
      condition     = var.listen == true || var.send == true || var.manage == true
      error_message = "Debe especificarse al menos un permiso (listen, send o manage)."
    }
  }
}
