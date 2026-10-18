variable "service_name" {
  type        = string
  description = "Nombre de la instancia de Azure API Management."
  default     = null
}

variable "name" {
  type        = string
  description = "Alias para service_name."
  default     = null
}

variable "resource_group_name" {
  type        = string
  description = "Nombre del Resource Group donde reside el servicio de APIM."
}

variable "location" {
  type        = string
  description = "Región de Azure para el servicio de APIM."
  default     = "mexicocentral"

  validation {
    condition     = length(trimspace(var.location)) > 0
    error_message = "La región no puede estar vacía."
  }
}

variable "publisher_name" {
  type        = string
  description = "Nombre de la organización publicadora para el portal de APIs."
  default     = "Universidad Nacional Frontend Platform Group"
}

variable "publisher_email" {
  type        = string
  description = "Correo del administrador de la plataforma APIM."
  default     = "admin@universidad.edu.pe"
}

variable "sku_name" {
  type        = string
  description = "SKU y capacidad de Azure API Management. Default: Consumption_0 para Azure for Students ($0.00 hasta 1M llamadas)."
  default     = "Consumption_0"

  validation {
    condition     = can(regex("^(Consumption_0|Developer_1|Standard_1|Premium_1)$", var.sku_name))
    error_message = "El SKU debe ser uno de: Consumption_0, Developer_1, Standard_1, Premium_1."
  }
}

variable "identity_type" {
  type        = string
  description = "Tipo de Managed Identity asignada al servicio APIM."
  default     = "SystemAssigned"
}

variable "min_api_version" {
  type        = string
  description = "Versión mínima de la API REST soportada por el plano de control."
  default     = "2021-08-01"
}

variable "virtual_network_type" {
  type        = string
  description = "Tipo de integración en red virtual (None, External, Internal). En SKU Consumption debe ser 'None'."
  default     = "None"

  validation {
    condition     = contains(["None", "External", "Internal"], var.virtual_network_type)
    error_message = "El tipo de red virtual debe ser 'None', 'External' o 'Internal'."
  }
}

variable "client_certificate_enabled" {
  type        = bool
  description = "Habilita la negociación TLS de certificados de cliente."
  default     = false
}

variable "tags" {
  type        = map(string)
  description = "Mapa de etiquetas obligatorias según cloud-standards."
  default     = {}

  validation {
    condition = (
      length(var.tags) == 0 ||
      (
        contains(keys(var.tags), "Project") &&
        contains(keys(var.tags), "Environment") &&
        contains(keys(var.tags), "Owner") &&
        contains(keys(var.tags), "CostCenter") &&
        contains(keys(var.tags), "ManagedBy") &&
        contains(keys(var.tags), "DataClassification")
      )
    )
    error_message = "Las tags deben incluir: Project, Environment, Owner, CostCenter, ManagedBy, DataClassification."
  }
}
