resource "azurerm_cosmosdb_account" "this" {
  name                          = coalesce(var.account_name, var.name)
  location                      = coalesce(var.cosmos_location, var.location)
  resource_group_name           = var.resource_group_name
  offer_type                    = var.offer_type
  kind                          = var.kind
  free_tier_enabled             = var.free_tier_enabled
  public_network_access_enabled = var.public_network_access_enabled

  consistency_policy {
    consistency_level       = var.consistency_level
    max_interval_in_seconds = var.consistency_level == "BoundedStaleness" ? 300 : null
    max_staleness_prefix    = var.consistency_level == "BoundedStaleness" ? 100000 : null
  }

  geo_location {
    location          = coalesce(var.cosmos_location, var.location)
    failover_priority = 0
  }

  tags = var.tags

  lifecycle {
    precondition {
      condition     = var.account_name != null || var.name != null
      error_message = "Debe especificar 'account_name' o 'name' para la cuenta de Cosmos DB."
    }
  }
}

resource "azurerm_cosmosdb_sql_database" "this" {
  name                = var.database_name
  resource_group_name = var.resource_group_name
  account_name        = azurerm_cosmosdb_account.this.name
  throughput          = var.throughput
}

resource "azurerm_cosmosdb_sql_container" "this" {
  for_each              = var.containers
  name                  = each.key
  resource_group_name   = var.resource_group_name
  account_name          = azurerm_cosmosdb_account.this.name
  database_name         = azurerm_cosmosdb_sql_database.this.name
  partition_key_paths   = each.value.partition_key_paths
  partition_key_version = each.value.partition_key_version
  default_ttl           = each.value.default_ttl
  throughput            = each.value.throughput
}
