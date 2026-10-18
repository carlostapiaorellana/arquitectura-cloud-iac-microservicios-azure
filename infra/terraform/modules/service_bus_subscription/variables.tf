variable "subscription_name" {
  type        = string
  description = "Nombre de la suscripciÃ³n al Service Bus Topic (ej. sub-enrollment-student, sub-library-student)."
  default     = null

  validation {
    condition     = var.subscription_name == null ? true : (length(trimspace(var.subscription_name)) >= 1 && length(trimspace(var.subscription_name)) <= 50)
    error_message = "subscription_name debe tener entre 1 y 50 caracteres."
  }
}

variable "name" {
  type        = string
  description = "Alias para el nombre de la suscripciÃ³n."
  default     = null

  validation {
    condition     = var.name == null ? true : (length(trimspace(var.name)) >= 1 && length(trimspace(var.name)) <= 50)
    error_message = "name debe tener entre 1 y 50 caracteres."
  }
}

variable "topic_id" {
  type        = string
  description = "ID del Service Bus Topic al cual se suscribe (requerido en azurerm v4)."

  validation {
    condition     = length(trimspace(var.topic_id)) > 0
    error_message = "topic_id no puede estar vacÃ­o."
  }
}

variable "max_delivery_count" {
  type        = number
  description = "NÃºmero mÃ¡ximo de entregas antes de mover el mensaje a la Dead-Letter Queue (default 5)."
  default     = 5

  validation {
    condition     = var.max_delivery_count >= 1 && var.max_delivery_count <= 2000
    error_message = "max_delivery_count debe estar entre 1 y 2000."
  }
}

variable "lock_duration" {
  type        = string
  description = "DuraciÃ³n del bloqueo de mensaje en modo Peek-Lock en formato ISO 8601 (default PT1M = 1 minuto)."
  default     = "PT1M"
}

variable "dead_lettering_on_message_expiration" {
  type        = bool
  description = "Indica si los mensajes expirados deben enviarse a la Dead-Letter Queue (default true)."
  default     = true
}

variable "dead_lettering_on_filter_evaluation_error" {
  type        = bool
  description = "Indica si los mensajes con errores de evaluaciÃ³n de filtro deben enviarse a la Dead-Letter Queue (default true)."
  default     = true
}

variable "default_message_ttl" {
  type        = string
  description = "Tiempo de vida por defecto de los mensajes en la suscripciÃ³n en formato ISO 8601 (default P14D = 14 dÃ­as)."
  default     = "P14D"
}

variable "auto_delete_on_idle" {
  type        = string
  description = "Tiempo de inactividad antes de auto-eliminar la suscripciÃ³n (null para desactivar)."
  default     = null
}

variable "status" {
  type        = string
  description = "Estado operativo de la suscripciÃ³n ('Active', 'Disabled', 'ReceiveDisabled'). Default Active."
  default     = "Active"

  validation {
    condition     = contains(["Active", "Disabled", "ReceiveDisabled"], var.status)
    error_message = "status debe ser Active, Disabled o ReceiveDisabled."
  }
}
