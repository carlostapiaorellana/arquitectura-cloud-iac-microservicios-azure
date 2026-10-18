variable "rule_name" {
  type        = string
  description = "Nombre de la regla de autorizaciÃ³n SAS (ej. auth-rule-legacy-sender)."
  default     = null

  validation {
    condition     = var.rule_name == null ? true : (length(trimspace(var.rule_name)) >= 1 && length(trimspace(var.rule_name)) <= 50)
    error_message = "rule_name debe tener entre 1 y 50 caracteres."
  }
}

variable "name" {
  type        = string
  description = "Alias para el nombre de la regla de autorizaciÃ³n SAS."
  default     = null

  validation {
    condition     = var.name == null ? true : (length(trimspace(var.name)) >= 1 && length(trimspace(var.name)) <= 50)
    error_message = "name debe tener entre 1 y 50 caracteres."
  }
}

variable "namespace_id" {
  type        = string
  description = "ID del Service Bus Namespace al cual pertenecerÃ¡ la regla de autorizaciÃ³n (requerido en azurerm v4)."

  validation {
    condition     = length(trimspace(var.namespace_id)) > 0
    error_message = "namespace_id no puede estar vacÃ­o."
  }
}

variable "listen" {
  type        = bool
  description = "Permite permisos de escucha/consumo (listen) sobre el namespace."
  default     = false
}

variable "send" {
  type        = bool
  description = "Permite permisos de envÃ­o/publicaciÃ³n (send) sobre el namespace."
  default     = false
}

variable "manage" {
  type        = bool
  description = "Permite permisos de administraciÃ³n (manage). Si es true, exige que listen y send sean tambiÃ©n true."
  default     = false
}

variable "enable_rule" {
  type        = bool
  description = "Habilita la creaciÃ³n de la regla de autorizaciÃ³n (default true). Permite desacoplar y crear la regla condicionalmente."
  default     = true
}
