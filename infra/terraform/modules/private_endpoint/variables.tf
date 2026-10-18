variable "endpoint_name" {
  type        = string
  description = "Nombre del Private Endpoint siguiendo CAF (ej. pe-kv-univ-dev-ncus)."
  default     = null

  validation {
    condition     = var.endpoint_name == null ? true : (length(trimspace(var.endpoint_name)) >= 1 && length(trimspace(var.endpoint_name)) <= 80)
    error_message = "El nombre del Private Endpoint (endpoint_name) debe tener entre 1 y 80 caracteres."
  }
}

variable "name" {
  type        = string
  description = "Alias opcional para el nombre del Private Endpoint cuando no se especifica endpoint_name."
  default     = null

  validation {
    condition     = var.name == null ? true : (length(trimspace(var.name)) >= 1 && length(trimspace(var.name)) <= 80)
    error_message = "El nombre del Private Endpoint (name) debe tener entre 1 y 80 caracteres."
  }
}

variable "location" {
  type        = string
  description = "RegiÃ³n de Azure donde se crearÃ¡ la interfaz del Private Endpoint."
  default     = "northcentralus"

  validation {
    condition     = length(trimspace(var.location)) > 0
    error_message = "La regiÃ³n (location) no puede estar vacÃ­a."
  }
}

variable "resource_group_name" {
  type        = string
  description = "Nombre del Resource Group donde se aprovisionarÃ¡ el Private Endpoint."

  validation {
    condition     = length(trimspace(var.resource_group_name)) >= 1 && length(trimspace(var.resource_group_name)) <= 90
    error_message = "El nombre del Resource Group no puede estar vacÃ­o."
  }
}

variable "subnet_id" {
  type        = string
  description = "ID de recurso de la subred dedicada a Private Endpoints (ej. snet-pe)."

  validation {
    condition     = length(trimspace(var.subnet_id)) > 0
    error_message = "El ID de la subred (subnet_id) no puede estar vacÃ­o."
  }
}

variable "private_connection_resource_id" {
  type        = string
  description = "ID de recurso del servicio PaaS de destino en Azure (Key Vault, Cosmos DB, Service Bus, ACR, etc.)."

  validation {
    condition     = length(trimspace(var.private_connection_resource_id)) > 0
    error_message = "private_connection_resource_id no puede estar vacÃ­o."
  }
}

variable "subresource_names" {
  type        = list(string)
  description = "Lista de subrecursos de destino para la conexiÃ³n privada (ej. [\"vault\"], [\"Sql\"], [\"namespace\"])."

  validation {
    condition     = length(var.subresource_names) > 0
    error_message = "Debe especificar al menos un nombre de subrecurso en subresource_names."
  }
}

variable "is_manual_connection" {
  type        = bool
  description = "Define si la conexiÃ³n del Private Endpoint requiere aprobaciÃ³n manual del propietario del recurso."
  default     = false
}

variable "private_service_connection_name" {
  type        = string
  description = "Nombre opcional para la conexiÃ³n de servicio privada. Si es null, se deriva del nombre del Private Endpoint."
  default     = null
}

variable "private_dns_zone_ids" {
  type        = list(string)
  description = "Lista opcional de IDs de Zonas DNS Privadas para registrar automÃ¡ticamente el registro A del Private Endpoint."
  default     = []
}

variable "private_dns_zone_group_name" {
  type        = string
  description = "Nombre del grupo de zona DNS privada."
  default     = "default"
}

variable "ip_configuration" {
  type = object({
    name               = string
    private_ip_address = string
    subresource_name   = optional(string)
    member_name        = optional(string)
  })
  description = "ConfiguraciÃ³n opcional de direcciÃ³n IP privada estÃ¡tica para el Private Endpoint."
  default     = null
}

variable "ip_configurations" {
  type = list(object({
    name               = string
    private_ip_address = string
    subresource_name   = optional(string)
    member_name        = optional(string)
  }))
  description = "Lista opcional de configuraciones de IP privada estÃ¡tica para el Private Endpoint."
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
