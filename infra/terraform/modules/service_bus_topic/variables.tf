variable "topic_name" {
  type        = string
  description = "Nombre del Service Bus Topic (ej. student.events, enrollment.events)."
  default     = null

  validation {
    condition     = var.topic_name == null ? true : (length(trimspace(var.topic_name)) >= 1 && length(trimspace(var.topic_name)) <= 260)
    error_message = "topic_name debe tener entre 1 y 260 caracteres."
  }
}

variable "name" {
  type        = string
  description = "Alias para el nombre del Service Bus Topic."
  default     = null

  validation {
    condition     = var.name == null ? true : (length(trimspace(var.name)) >= 1 && length(trimspace(var.name)) <= 260)
    error_message = "name debe tener entre 1 y 260 caracteres."
  }
}

variable "namespace_id" {
  type        = string
  description = "ID del Service Bus Namespace al cual pertenecerÃ¡ el Topic (requerido en azurerm v4)."

  validation {
    condition     = length(trimspace(var.namespace_id)) > 0
    error_message = "namespace_id no puede estar vacÃ­o."
  }
}

variable "support_ordering" {
  type        = bool
  description = "Define si el topic garantiza el ordenamiento de mensajes (default true)."
  default     = true
}

variable "requires_duplicate_detection" {
  type        = bool
  description = "Habilita la detecciÃ³n y descarte de mensajes duplicados (default true para idempotencia EDA)."
  default     = true
}

variable "duplicate_detection_history_time_window" {
  type        = string
  description = "Ventana de tiempo para detecciÃ³n de mensajes duplicados en formato ISO 8601 (default PT10M = 10 minutos)."
  default     = "PT10M"
}

variable "max_size_in_megabytes" {
  type        = number
  description = "TamaÃ±o mÃ¡ximo en megabytes para el Topic (1024, 2048, 5120, etc.). Default 1024."
  default     = 1024

  validation {
    condition     = contains([1024, 2048, 3072, 4096, 5120], var.max_size_in_megabytes)
    error_message = "max_size_in_megabytes debe ser un valor vÃ¡lido (ej. 1024, 2048, 3072, 4096, 5120)."
  }
}

variable "default_message_ttl" {
  type        = string
  description = "Tiempo de vida por defecto de los mensajes en formato ISO 8601 (default P14D = 14 dÃ­as)."
  default     = "P14D"
}

variable "auto_delete_on_idle" {
  type        = string
  description = "Tiempo de inactividad antes de auto-eliminar el topic en formato ISO 8601 (null para desactivar)."
  default     = null
}

variable "status" {
  type        = string
  description = "Estado operativo del Topic ('Active', 'Disabled', 'SendDisabled'). Default Active."
  default     = "Active"

  validation {
    condition     = contains(["Active", "Disabled", "SendDisabled"], var.status)
    error_message = "status debe ser Active, Disabled o SendDisabled."
  }
}
