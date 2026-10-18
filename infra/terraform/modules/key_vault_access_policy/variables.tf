variable "key_vault_id" {
  type        = string
  description = "ID de recurso del Azure Key Vault donde se aplicará la política de acceso."

  validation {
    condition     = length(trimspace(var.key_vault_id)) > 0
    error_message = "El ID del Key Vault (key_vault_id) no puede estar vacío."
  }
}

variable "tenant_id" {
  type        = string
  description = "UUID del Tenant de Microsoft Entra ID asociado al principal."

  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.tenant_id))
    error_message = "El tenant_id debe ser un UUID válido de Microsoft Entra ID."
  }
}

variable "object_id" {
  type        = string
  description = "Object ID (Principal ID) de la identidad en Microsoft Entra ID a la que se otorgan los permisos."

  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.object_id))
    error_message = "El object_id debe ser un UUID válido de Microsoft Entra ID."
  }
}

variable "key_permissions" {
  type        = list(string)
  description = "Lista de permisos sobre claves criptográficas (ej. [\"Get\", \"List\", \"Verify\"])."
  default     = []

  validation {
    condition     = !contains(var.key_permissions, "Purge")
    error_message = "Por seguridad Zero-Trust, no se permite otorgar el permiso 'Purge' sobre claves a identidades de carga de trabajo."
  }
}

variable "secret_permissions" {
  type        = list(string)
  description = "Lista de permisos sobre secretos de mínimo privilegio (por defecto [\"Get\", \"List\"])."
  default     = ["Get", "List"]

  validation {
    condition     = !contains(var.secret_permissions, "Purge")
    error_message = "Por seguridad Zero-Trust, no se permite otorgar el permiso 'Purge' sobre secretos a identidades de carga de trabajo."
  }
}

variable "certificate_permissions" {
  type        = list(string)
  description = "Lista de permisos sobre certificados (por defecto [])."
  default     = []

  validation {
    condition     = !contains(var.certificate_permissions, "Purge")
    error_message = "Por seguridad Zero-Trust, no se permite otorgar el permiso 'Purge' sobre certificados a identidades de carga de trabajo."
  }
}
