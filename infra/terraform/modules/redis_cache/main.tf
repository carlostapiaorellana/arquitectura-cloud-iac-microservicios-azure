resource "azurerm_redis_cache" "this" {
  name                          = coalesce(var.redis_name, var.name)
  location                      = var.location
  resource_group_name           = var.resource_group_name
  capacity                      = var.capacity
  family                        = var.family
  sku_name                      = var.sku_name
  non_ssl_port_enabled          = coalesce(var.non_ssl_port_enabled, var.enable_non_ssl_port)
  minimum_tls_version           = var.minimum_tls_version
  public_network_access_enabled = var.public_network_access_enabled

  redis_configuration {
    maxmemory_reserved              = var.redis_configuration.maxmemory_reserved
    maxmemory_delta                 = var.redis_configuration.maxmemory_delta
    maxfragmentationmemory_reserved = var.redis_configuration.maxfragmentationmemory_reserved
    maxmemory_policy                = var.redis_configuration.maxmemory_policy
    rdb_backup_enabled              = var.redis_configuration.rdb_backup_enabled
    rdb_backup_frequency            = var.redis_configuration.rdb_backup_frequency
    rdb_backup_max_snapshot_count   = var.redis_configuration.rdb_backup_max_snapshot_count
    rdb_storage_connection_string   = var.redis_configuration.rdb_storage_connection_string
  }

  tags = var.tags

  lifecycle {
    precondition {
      condition     = var.redis_name != null || var.name != null
      error_message = "Debe especificar 'redis_name' o 'name' para la instancia de Redis Cache."
    }
  }
}
