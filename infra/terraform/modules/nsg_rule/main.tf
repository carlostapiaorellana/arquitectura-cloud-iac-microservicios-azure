resource "azurerm_network_security_rule" "this" {
  name                        = var.name
  priority                    = var.priority
  direction                   = var.direction
  access                      = var.access
  protocol                    = var.protocol
  source_port_range           = var.source_port_range
  destination_port_range      = var.destination_port_range
  source_address_prefix       = var.source_address_prefix
  destination_address_prefix  = var.destination_address_prefix
  resource_group_name         = var.resource_group_name
  network_security_group_name = var.network_security_group_name
  description                 = var.description

  lifecycle {
    precondition {
      condition = !(
        var.direction == "Inbound" &&
        var.access == "Allow" &&
        contains(["*", "0.0.0.0/0", "Internet", "Any"], var.source_address_prefix) &&
        contains(["22", "3389", "3306", "5432", "6379", "*"], var.destination_port_range)
      )
      error_message = "Violación de Regla Dura #4 (AGENTS.md / cloud-standards): Prohibido abrir puertos administrativos o de bases de datos (22, 3389, 3306, 5432, 6379, *) hacia 0.0.0.0/0 o Internet."
    }
  }
}
