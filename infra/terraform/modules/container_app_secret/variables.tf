variable "secret_name" {
  type        = string
  description = "Nombre del secreto en Azure Key Vault (alfanumÃ©rico y guiones, ej. db-password-auth)."
  default     = null

  validation {
    condition     = var.secret_name == null ? true : (length(trimspace(var.secret_name)) >= 1 && length(trimspace(var.secret_name)) <= 127 && can(regex("^[a-zA-Z0-9-]+$", var.secret_name)))
    error_message = "secret_name debe tener entre 1 y 127 caracteres alfanumÃ©ricos o guiones."
  }
}

variable "name" {
  type        = string
  description = "Alias para el nombre del secreto en Azure Key Vault."
  default     = null

  validation {
    condition     = var.name == null ? true : (length(trimspace(var.name)) >= 1 && length(trimspace(var.name)) <= 127 && can(regex("^[a-zA-Z0-9-]+$", var.name)))
    error_message = "name debe tener entre 1 y 127 caracteres alfanumÃ©ricos o guiones."
  }
}

variable "value" {
  type        = string
  description = "Valor sensible del secreto a almacenar."
  sensitive   = true

  validation {
    condition     = length(var.value) > 0
    error_message = "value no puede estar vacÃ­o."
  }
}

variable "key_vault_id" {
  type        = string
  description = "ID del Azure Key Vault donde se almacenarÃ¡ el secreto."

  validation {
    condition     = length(trimspace(var.key_vault_id)) > 0
    error_message = "key_vault_id no puede estar vacÃ­o."
  }
}

variable "content_type" {
  type        = string
  description = "Tipo de contenido del secreto (ej. text/plain, application/json)."
  default     = "text/plain"
}

variable "expiration_date" {
  type        = string
  description = "Fecha de expiraciÃ³n del secreto en formato RFC3339 (opcional)."
  default     = null
}

variable "identity_id" {
  type        = string
  description = "ID de la Managed Identity que consumirÃ¡ este secreto en Container Apps (opcional para el objeto aca_secret_reference)."
  default     = null
}

variable "tags" {
  type        = map(string)
  description = "Etiquetas opcionales para el secreto en Key Vault."
  default     = {}
}
