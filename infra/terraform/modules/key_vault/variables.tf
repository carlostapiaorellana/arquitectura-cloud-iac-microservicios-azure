variable "key_vault_name" {
  type        = string
  description = "Nombre globalmente Ãºnico del Azure Key Vault siguiendo CAF (3 a 24 caracteres alfanumÃ©ricos y guiones, ej. kv-univ-dev-ncus)."
  default     = null

  validation {
    condition     = var.key_vault_name == null ? true : (length(trimspace(var.key_vault_name)) >= 3 && length(trimspace(var.key_vault_name)) <= 24 && can(regex("^[a-zA-Z][a-zA-Z0-9-]*[a-zA-Z0-9]$", var.key_vault_name)))
    error_message = "key_vault_name debe tener entre 3 y 24 caracteres alfanumÃ©ricos o guiones, iniciando con una letra."
  }
}

variable "name" {
  type        = string
  description = "Alias opcional para el nombre del Key Vault cuando no se especifica key_vault_name."
  default     = null

  validation {
    condition     = var.name == null ? true : (length(trimspace(var.name)) >= 3 && length(trimspace(var.name)) <= 24 && can(regex("^[a-zA-Z][a-zA-Z0-9-]*[a-zA-Z0-9]$", var.name)))
    error_message = "El nombre del Key Vault (name) debe tener entre 3 y 24 caracteres alfanumÃ©ricos o guiones."
  }
}

variable "location" {
  type        = string
  description = "RegiÃ³n de Azure donde se aprovisionarÃ¡ el Key Vault."
  default     = "northcentralus"

  validation {
    condition     = length(trimspace(var.location)) > 0
    error_message = "La regiÃ³n (location) no puede estar vacÃ­a."
  }
}

variable "resource_group_name" {
  type        = string
  description = "Nombre del Resource Group contenedor del Key Vault."

  validation {
    condition     = length(trimspace(var.resource_group_name)) >= 1 && length(trimspace(var.resource_group_name)) <= 90
    error_message = "El nombre del Resource Group no puede estar vacÃ­o."
  }
}

variable "tenant_id" {
  type        = string
  description = "UUID del Tenant de Microsoft Entra ID asociado al Key Vault."

  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.tenant_id))
    error_message = "El tenant_id debe ser un UUID vÃ¡lido de Microsoft Entra ID."
  }
}

variable "sku_name" {
  type        = string
  description = "SKU del Key Vault ('standard' o 'premium')."
  default     = "standard"

  validation {
    condition     = contains(["standard", "premium"], lower(var.sku_name))
    error_message = "El sku_name del Key Vault debe ser 'standard' o 'premium'."
  }
}

variable "enable_rbac_authorization" {
  type        = bool
  description = "Habilita el modelo de autorizaciÃ³n basado en roles de Azure RBAC para el plano de datos del Key Vault."
  default     = true
}

variable "rbac_authorization_enabled" {
  type        = bool
  description = "Alias nativo de azurerm v4 para habilitar autorizaciÃ³n Azure RBAC en el Key Vault."
  default     = null
}

variable "purge_protection_enabled" {
  type        = bool
  description = "Habilita la protecciÃ³n contra purga permanente durante el periodo de retenciÃ³n de soft-delete."
  default     = true
}

variable "soft_delete_retention_days" {
  type        = number
  description = "DÃ­as de retenciÃ³n para objetos eliminados suavemente (entre 7 y 90 dÃ­as)."
  default     = 7

  validation {
    condition     = var.soft_delete_retention_days >= 7 && var.soft_delete_retention_days <= 90 && floor(var.soft_delete_retention_days) == var.soft_delete_retention_days
    error_message = "soft_delete_retention_days debe ser un nÃºmero entero entre 7 y 90 dÃ­as."
  }
}

variable "public_network_access_enabled" {
  type        = bool
  description = "Define si se permite el acceso desde redes pÃºblicas al Key Vault. Por defecto false (Zero-Trust)."
  default     = false
}

variable "network_acls" {
  type = object({
    default_action             = optional(string, "Deny")
    bypass                     = optional(string, "AzureServices")
    ip_rules                   = optional(list(string), [])
    virtual_network_subnet_ids = optional(list(string), [])
  })
  description = "Reglas de firewall de red (network_acls) del Key Vault."
  default = {
    default_action             = "Deny"
    bypass                     = "AzureServices"
    ip_rules                   = []
    virtual_network_subnet_ids = []
  }

  validation {
    condition     = contains(["Allow", "Deny"], var.network_acls.default_action) && contains(["AzureServices", "None"], var.network_acls.bypass)
    error_message = "network_acls.default_action debe ser 'Allow' o 'Deny', y bypass debe ser 'AzureServices' o 'None'."
  }
}

variable "ip_rules" {
  type        = list(string)
  description = "Lista opcional de IPs/CIDRs pÃºblicos permitidos en el firewall del Key Vault (si no se pasan dentro de network_acls)."
  default     = []
}

variable "virtual_network_subnet_ids" {
  type        = list(string)
  description = "Lista opcional de IDs de subredes permitidas en el firewall del Key Vault (si no se pasan dentro de network_acls)."
  default     = []
}

variable "tags" {
  type        = map(string)
  description = "Etiquetas obligatorias segÃºn cloud-standards (Project, Environment, Owner, CostCenter, ManagedBy, DataClassification)."

  validation {
    condition = alltrue([
      for k in ["Project", "Environment", "Owner", "CostCenter", "ManagedBy", "DataClassification"] :
      contains(keys(var.tags), k) && length(trimspace(var.tags[k])) > 0
    ])
    error_message = "El mapa tags debe incluir las 6 etiquetas obligatorias de cloud-standards: Project, Environment, Owner, CostCenter, ManagedBy y DataClassification."
  }
}
