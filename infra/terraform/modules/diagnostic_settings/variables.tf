variable "name" {
  type        = string
  description = "Nombre de la configuración de diagnóstico (ej. diag-kv-univ-dev, diag-mysql-univ-dev)."

  validation {
    condition     = length(trimspace(var.name)) >= 1 && length(trimspace(var.name)) <= 260
    error_message = "name debe tener entre 1 y 260 caracteres."
  }
}

variable "target_resource_id" {
  type        = string
  description = "ID del recurso de Azure a monitorear (Key Vault, MySQL, Cosmos DB, Service Bus, etc.)."

  validation {
    condition     = length(trimspace(var.target_resource_id)) > 0
    error_message = "target_resource_id no puede estar vacío."
  }
}

variable "log_analytics_workspace_id" {
  type        = string
  description = "ID del Log Analytics Workspace destino de los logs y métricas."
  default     = null
}

variable "log_analytics_destination_type" {
  type        = string
  description = "Tipo de destino en Log Analytics ('Dedicated' o 'AzureDiagnostics')."
  default     = null
}

variable "storage_account_id" {
  type        = string
  description = "ID de la cuenta de almacenamiento de archivo destino (opcional)."
  default     = null
}

variable "eventhub_name" {
  type        = string
  description = "Nombre del Event Hub destino (opcional)."
  default     = null
}

variable "eventhub_authorization_rule_id" {
  type        = string
  description = "ID de la regla de autorización del Event Hub destino (opcional)."
  default     = null
}

variable "log_categories" {
  type        = list(string)
  description = "Lista explícita de categorías de logs a capturar (ej. ['AuditEvent', 'AppServiceAppLogs'])."
  default     = []
}

variable "log_category_groups" {
  type        = list(string)
  description = "Lista de grupos de categorías de logs (ej. ['allLogs', 'audit']). Si se especifica, toma precedencia sobre categorías individuales."
  default     = []
}

variable "metric_categories" {
  type        = list(string)
  description = "Lista de categorías de métricas a capturar (default ['AllMetrics'])."
  default     = ["AllMetrics"]
}
