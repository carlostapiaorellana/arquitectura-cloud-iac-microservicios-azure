variable "app_insights_name" {
  type        = string
  description = "Nombre del Azure Application Insights siguiendo CAF (ej. appi-univ-dev-ncus, entre 1 y 260 caracteres)."
  default     = null

  validation {
    condition     = var.app_insights_name == null ? true : (length(trimspace(var.app_insights_name)) >= 1 && length(trimspace(var.app_insights_name)) <= 260 && can(regex("^[a-zA-Z0-9_.-]+$", var.app_insights_name)))
    error_message = "app_insights_name debe tener entre 1 y 260 caracteres vÃ¡lidos."
  }
}

variable "name" {
  type        = string
  description = "Alias para el nombre del Azure Application Insights."
  default     = null

  validation {
    condition     = var.name == null ? true : (length(trimspace(var.name)) >= 1 && length(trimspace(var.name)) <= 260 && can(regex("^[a-zA-Z0-9_.-]+$", var.name)))
    error_message = "name debe tener entre 1 y 260 caracteres vÃ¡lidos."
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
  description = "RegiÃ³n de Azure para Application Insights (default northcentralus)."
  default     = "northcentralus"

  validation {
    condition     = length(trimspace(var.location)) > 0
    error_message = "La regiÃ³n (location) no puede estar vacÃ­a."
  }
}

variable "workspace_id" {
  type        = string
  description = "ID del Log Analytics Workspace al cual se vincularÃ¡ Application Insights (modo Workspace-based)."

  validation {
    condition     = length(trimspace(var.workspace_id)) > 0
    error_message = "workspace_id es obligatorio para Application Insights Workspace-based en azurerm v4."
  }
}

variable "application_type" {
  type        = string
  description = "Tipo de aplicaciÃ³n para la instrumentaciÃ³n (web, other, java, Node.JS)."
  default     = "web"

  validation {
    condition     = contains(["web", "other", "java", "Node.JS"], var.application_type)
    error_message = "application_type debe ser web, other, java o Node.JS."
  }
}

variable "retention_in_days" {
  type        = number
  description = "DÃ­as de retenciÃ³n de telemetrÃ­a (default 30 dÃ­as)."
  default     = 30

  validation {
    condition     = var.retention_in_days >= 30 && var.retention_in_days <= 730
    error_message = "retention_in_days debe estar entre 30 y 730 dÃ­as."
  }
}

variable "daily_data_cap_in_gb" {
  type        = number
  description = "Tope diario de datos en GB para prevenir sobrecostos de ingesta."
  default     = null
}

variable "daily_data_cap_notifications_enabled" {
  type        = bool
  description = "Habilita las notificaciones al alcanzar el tope diario (default false)."
  default     = false
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
