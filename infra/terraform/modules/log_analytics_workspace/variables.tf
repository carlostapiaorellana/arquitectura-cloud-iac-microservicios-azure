variable "workspace_name" {
  type        = string
  description = "Nombre del Azure Log Analytics Workspace siguiendo CAF (ej. log-univ-dev-ncus, entre 4 y 63 caracteres alfanumÃ©ricos o guiones)."
  default     = null

  validation {
    condition     = var.workspace_name == null ? true : (length(trimspace(var.workspace_name)) >= 4 && length(trimspace(var.workspace_name)) <= 63 && can(regex("^[a-zA-Z0-9][a-zA-Z0-9-]*[a-zA-Z0-9]$", var.workspace_name)))
    error_message = "workspace_name debe tener entre 4 y 63 caracteres alfanumÃ©ricos o guiones."
  }
}

variable "name" {
  type        = string
  description = "Alias para el nombre del Azure Log Analytics Workspace."
  default     = null

  validation {
    condition     = var.name == null ? true : (length(trimspace(var.name)) >= 4 && length(trimspace(var.name)) <= 63 && can(regex("^[a-zA-Z0-9][a-zA-Z0-9-]*[a-zA-Z0-9]$", var.name)))
    error_message = "name debe tener entre 4 y 63 caracteres alfanumÃ©ricos o guiones."
  }
}

variable "resource_group_name" {
  type        = string
  description = "Nombre del Resource Group contenedor."

  validation {
    condition     = length(trimspace(var.resource_group_name)) >= 1 && length(trimspace(var.resource_group_name)) <= 90
    error_message = "El nombre del Resource Group no puede estar vacÃ­o."
  }
}

variable "location" {
  type        = string
  description = "RegiÃ³n de Azure para Log Analytics (default northcentralus)."
  default     = "northcentralus"

  validation {
    condition     = length(trimspace(var.location)) > 0
    error_message = "La regiÃ³n (location) no puede estar vacÃ­a."
  }
}

variable "sku" {
  type        = string
  description = "SKU de precios de Log Analytics (default PerGB2018)."
  default     = "PerGB2018"

  validation {
    condition     = contains(["PerGB2018", "Free", "Standalone", "PerNode"], var.sku)
    error_message = "sku debe ser PerGB2018, Free, Standalone o PerNode."
  }
}

variable "retention_in_days" {
  type        = number
  description = "DÃ­as de retenciÃ³n de telemetrÃ­a y logs (entre 30 y 730 dÃ­as)."
  default     = 30

  validation {
    condition     = var.retention_in_days >= 30 && var.retention_in_days <= 730
    error_message = "retention_in_days debe ser un nÃºmero entero entre 30 y 730 dÃ­as."
  }
}

variable "daily_quota_gb" {
  type        = number
  description = "LÃ­mite mÃ¡ximo diario de ingesta en GB para prevenir costos imprevistos (default 0.1 GB para Azure for Students, -1 para ilimitado)."
  default     = 0.1

  validation {
    condition     = var.daily_quota_gb == -1 || var.daily_quota_gb >= 0.023
    error_message = "daily_quota_gb debe ser mayor o igual a 0.023 GB o -1 para ilimitado."
  }
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
