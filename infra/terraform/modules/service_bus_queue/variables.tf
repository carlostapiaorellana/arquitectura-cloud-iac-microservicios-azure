variable "queue_name" {
  type        = string
  description = "Nombre de la cola de Service Bus (ej. payments.processing)."
  default     = null

  validation {
    condition     = var.queue_name == null ? true : (length(trimspace(var.queue_name)) >= 1 && length(trimspace(var.queue_name)) <= 260)
    error_message = "queue_name debe tener entre 1 y 260 caracteres."
  }
}

variable "name" {
  type        = string
  description = "Alias para el nombre de la cola."
  default     = null

  validation {
    condition     = var.name == null ? true : (length(trimspace(var.name)) >= 1 && length(trimspace(var.name)) <= 260)
    error_message = "name debe tener entre 1 y 260 caracteres."
  }
}

variable "namespace_id" {
  type        = string
  description = "ID del Service Bus Namespace al cual pertenecerÃ¡ la cola (requerido en azurerm v4)."

  validation {
    condition     = length(trimspace(var.namespace_id)) > 0
    error_message = "namespace_id no puede estar vacÃ­o."
  }
}

variable "lock_duration" {
  type        = string
  description = "DuraciÃ³n del bloqueo en modo Peek-Lock en formato ISO 8601 (default PT1M = 1 minuto)."
  default     = "PT1M"
}

variable "max_delivery_count" {
  type        = number
  description = "NÃºmero mÃ¡ximo de intentos de entrega antes de enviar a la Dead-Letter Queue (default 5)."
  default     = 5

  validation {
    condition     = var.max_delivery_count >= 1 && var.max_delivery_count <= 2000
    error_message = "max_delivery_count debe estar entre 1 y 2000."
  }
}

variable "max_size_in_megabytes" {
  type        = number
  description = "TamaÃ±o mÃ¡ximo en megabytes para la cola (default 1024)."
  default     = 1024

  validation {
    condition     = contains([1024, 2048, 3072, 4096, 5120], var.max_size_in_megabytes)
    error_message = "max_size_in_megabytes debe ser 1024, 2048, 3072, 4096 o 5120."
  }
}

variable "requires_duplicate_detection" {
  type        = bool
  description = "Habilita la detecciÃ³n de mensajes duplicados en la cola (default true)."
  default     = true
}

variable "duplicate_detection_history_time_window" {
  type        = string
  description = "Ventana de tiempo para deduplicaciÃ³n en formato ISO 8601 (default PT10M = 10 minutos)."
  default     = "PT10M"
}

variable "dead_lettering_on_message_expiration" {
  type        = bool
  description = "Indica si los mensajes expirados deben moverse a la sub-cola DLQ (default true)."
  default     = true
}

variable "default_message_ttl" {
  type        = string
  description = "Tiempo de vida por defecto de los mensajes en la cola en formato ISO 8601 (default P14D = 14 dÃ­as)."
  default     = "P14D"
}

variable "auto_delete_on_idle" {
  type        = string
  description = "Tiempo de inactividad antes de auto-eliminar la cola (null para desactivar)."
  default     = null
}

variable "status" {
  type        = string
  description = "Estado operativo de la cola ('Active', 'Disabled', 'ReceiveDisabled', 'SendDisabled'). Default Active."
  default     = "Active"

  validation {
    condition     = contains(["Active", "Disabled", "ReceiveDisabled", "SendDisabled"], var.status)
    error_message = "status debe ser Active, Disabled, ReceiveDisabled o SendDisabled."
  }
}
