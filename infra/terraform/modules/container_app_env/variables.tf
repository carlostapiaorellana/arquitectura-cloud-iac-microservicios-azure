variable "environment_name" {
  type        = string
  description = "Nombre del Azure Container App Environment siguiendo CAF (ej. cae-univ-dev-ncus, entre 1 y 60 caracteres)."
  default     = null

  validation {
    condition     = var.environment_name == null ? true : (length(trimspace(var.environment_name)) >= 1 && length(trimspace(var.environment_name)) <= 60 && can(regex("^[a-zA-Z0-9][a-zA-Z0-9-]*[a-zA-Z0-9]$", var.environment_name)))
    error_message = "environment_name debe tener entre 1 y 60 caracteres alfanumÃ©ricos o guiones."
  }
}

variable "name" {
  type        = string
  description = "Alias para el nombre del Azure Container App Environment."
  default     = null

  validation {
    condition     = var.name == null ? true : (length(trimspace(var.name)) >= 1 && length(trimspace(var.name)) <= 60 && can(regex("^[a-zA-Z0-9][a-zA-Z0-9-]*[a-zA-Z0-9]$", var.name)))
    error_message = "name debe tener entre 1 y 60 caracteres alfanumÃ©ricos o guiones."
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
  description = "RegiÃ³n de Azure donde se aprovisionarÃ¡ el Container App Environment (default northcentralus)."
  default     = "northcentralus"

  validation {
    condition     = length(trimspace(var.location)) > 0
    error_message = "La regiÃ³n (location) no puede estar vacÃ­a."
  }
}

variable "log_analytics_workspace_id" {
  type        = string
  description = "ID del Log Analytics Workspace para ingesta de logs y telemetrÃ­a de los contenedores."

  validation {
    condition     = length(trimspace(var.log_analytics_workspace_id)) > 0
    error_message = "log_analytics_workspace_id no puede estar vacÃ­o."
  }
}

variable "infrastructure_subnet_id" {
  type        = string
  description = "ID de la subred delegada a Microsoft.App/environments (snet-aca /23) para inyecciÃ³n VNet de contenedores."
  default     = null
}

variable "internal_load_balancer_enabled" {
  type        = bool
  description = "Indica si el entorno debe exponerse exclusivamente vÃ­a balanceador interno (ILB). Default false."
  default     = false
}

variable "zone_redundancy_enabled" {
  type        = bool
  description = "Habilita la redundancia de zona para el entorno ACA. Default false para entornos dev/efÃ­meros."
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
