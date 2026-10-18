variable "logger_name" {
  type        = string
  description = "Nombre del logger en Azure API Management (ej. apim-logger-appinsights, entre 1 y 80 caracteres)."
  default     = null

  validation {
    condition     = var.logger_name == null ? true : (length(trimspace(var.logger_name)) >= 1 && length(trimspace(var.logger_name)) <= 80 && can(regex("^[a-zA-Z0-9-]+$", var.logger_name)))
    error_message = "logger_name debe tener entre 1 y 80 caracteres alfanumÃ©ricos o guiones."
  }
}

variable "name" {
  type        = string
  description = "Alias para el nombre del logger en Azure API Management."
  default     = null

  validation {
    condition     = var.name == null ? true : (length(trimspace(var.name)) >= 1 && length(trimspace(var.name)) <= 80 && can(regex("^[a-zA-Z0-9-]+$", var.name)))
    error_message = "name debe tener entre 1 y 80 caracteres alfanumÃ©ricos o guiones."
  }
}

variable "api_management_name" {
  type        = string
  description = "Nombre de la instancia de Azure API Management."

  validation {
    condition     = length(trimspace(var.api_management_name)) >= 1 && length(trimspace(var.api_management_name)) <= 50
    error_message = "api_management_name no puede estar vacÃ­o."
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

variable "instrumentation_key" {
  type        = string
  description = "Instrumentation Key de Application Insights sensible."
  sensitive   = true

  validation {
    condition     = length(var.instrumentation_key) > 0
    error_message = "instrumentation_key no puede estar vacÃ­o."
  }
}

variable "connection_string" {
  type        = string
  description = "Connection string de Application Insights sensible (opcional)."
  sensitive   = true
  default     = null
}

variable "buffered" {
  type        = bool
  description = "Habilita el almacenamiento en buffer de eventos antes de su envÃ­o a Application Insights (default true)."
  default     = true
}

variable "description" {
  type        = string
  description = "DescripciÃ³n del logger en APIM."
  default     = "Logger de Application Insights para telemetrÃ­a distribuida de APIM"
}
