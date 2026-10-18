locals {
  effective_name              = coalesce(var.endpoint_name, var.name)
  effective_psc_name          = coalesce(var.private_service_connection_name, "psc-${local.effective_name}")
  effective_ip_configurations = var.ip_configuration != null ? concat([var.ip_configuration], var.ip_configurations) : var.ip_configurations
}

resource "azurerm_private_endpoint" "this" {
  name                = local.effective_name
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = local.effective_psc_name
    private_connection_resource_id = var.private_connection_resource_id
    is_manual_connection           = var.is_manual_connection
    subresource_names              = var.subresource_names
  }

  dynamic "private_dns_zone_group" {
    for_each = length(var.private_dns_zone_ids) > 0 ? [1] : []
    content {
      name                 = var.private_dns_zone_group_name
      private_dns_zone_ids = var.private_dns_zone_ids
    }
  }

  dynamic "ip_configuration" {
    for_each = local.effective_ip_configurations
    content {
      name               = ip_configuration.value.name
      private_ip_address = ip_configuration.value.private_ip_address
      subresource_name   = ip_configuration.value.subresource_name
      member_name        = ip_configuration.value.member_name
    }
  }

  lifecycle {
    precondition {
      condition     = var.endpoint_name != null || var.name != null
      error_message = "Debe especificar 'endpoint_name' o 'name' para el Private Endpoint."
    }
  }
}
