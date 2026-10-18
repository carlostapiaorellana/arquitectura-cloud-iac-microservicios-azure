variable "backend_name" {
  type        = string
  description = "Nombre del backend en Azure API Management (ej. backend-api-gateway, entre 1 y 80 caracteres)."
  default     = null

  validation {
    condition     = var.backend_name == null ? true : (length(trimspace(var.backend_name)) >= 1 && length(trimspace(var.backend_name)) <= 80 && can(regex("^[a-zA-Z0-9-]+$", var.backend_name)))
    error_message = "backend_name debe tener entre 1 y 80 caracteres alfanumÃ©ricos o guiones."
  }
}

variable "name" {
  type        = string
  description = "Alias para el nombre del backend en Azure API Management."
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

variable "protocol" {
  type        = string
  description = "Protocolo del backend ('http' o 'soap'). Default http."
  default     = "http"

  validation {
    condition     = contains(["http", "soap"], var.protocol)
    error_message = "protocol debe ser 'http' o 'soap'."
  }
}

variable "url" {
  type        = string
  description = "URL completa HTTPS del backend (ej. https://ca-api-gateway.<domain>)."

  validation {
    condition     = can(regex("^https?://", var.url))
    error_message = "url debe ser una URL vÃ¡lida iniciando con http:// o https://."
  }
}

variable "description" {
  type        = string
  description = "DescripciÃ³n del backend en APIM."
  default     = "Backend HTTP hacia el API Gateway perimetral en Azure Container Apps"
}

variable "title" {
  type        = string
  description = "TÃ­tulo o nombre para mostrar del backend en APIM."
  default     = null
}

variable "validate_certificate_chain" {
  type        = bool
  description = "Habilita la validaciÃ³n de la cadena de certificados TLS del backend (default true)."
  default     = true
}

variable "validate_certificate_name" {
  type        = bool
  description = "Habilita la validaciÃ³n del nombre en el certificado TLS del backend (default true)."
  default     = true
}
