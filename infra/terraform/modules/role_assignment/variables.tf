variable "scope" {
  type        = string
  description = "Alcance (Azure Resource ID) estricto donde aplica el permiso (ej. Topic, Subscription, Queue, Key Vault o ACR)."

  validation {
    condition     = length(trimspace(var.scope)) > 0
    error_message = "El alcance (scope) no puede estar vacÃ­o."
  }
}

variable "principal_id" {
  type        = string
  description = "Object ID (Principal ID) de la identidad en Microsoft Entra ID que recibirÃ¡ el rol."

  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.principal_id))
    error_message = "El principal_id debe ser un UUID vÃ¡lido de Microsoft Entra ID."
  }
}

variable "role_definition_name" {
  type        = string
  description = "Nombre del rol integrado en Azure RBAC (ej. 'Azure Service Bus Data Sender', 'Azure Service Bus Data Receiver', 'Key Vault Secrets User', 'AcrPull'). Mutuamente excluyente con role_definition_id."
  default     = null

  validation {
    condition     = var.role_definition_name == null ? true : (!contains(["Owner", "Contributor", "User Access Administrator"], var.role_definition_name))
    error_message = "ViolaciÃ³n de Regla Dura #5 (AGENTS.md / cloud-standards): Prohibido otorgar roles privilegiados ('Owner', 'Contributor', 'User Access Administrator') a identidades de carga de trabajo."
  }
}

variable "role_definition_id" {
  type        = string
  description = "ID de definiciÃ³n del rol en Azure RBAC. Mutuamente excluyente con role_definition_name."
  default     = null
}

variable "principal_type" {
  type        = string
  description = "Tipo opcional de entidad principal ('User', 'Group', 'ServicePrincipal', 'ForeignGroup', 'Device')."
  default     = null

  validation {
    condition     = var.principal_type == null ? true : (contains(["User", "Group", "ServicePrincipal", "ForeignGroup", "Device"], var.principal_type))
    error_message = "principal_type debe ser null o uno de: 'User', 'Group', 'ServicePrincipal', 'ForeignGroup', 'Device'."
  }
}

variable "skip_service_principal_aad_check" {
  type        = bool
  description = "Omite la verificaciÃ³n de propagaciÃ³n en Entra ID para Service Principals reciÃ©n creados."
  default     = false
}
