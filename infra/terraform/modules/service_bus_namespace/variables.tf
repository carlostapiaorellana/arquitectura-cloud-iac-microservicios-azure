variable "namespace_name" {
  type        = string
  description = "Nombre globalmente Ãºnico del Service Bus Namespace siguiendo CAF (ej. sb-univ-dev-ncus, entre 6 y 50 caracteres alfanumÃ©ricos y guiones)."
  default     = null

  validation {
    condition     = var.namespace_name == null ? true : (length(trimspace(var.namespace_name)) >= 6 && length(trimspace(var.namespace_name)) <= 50 && can(regex("^[a-zA-Z][a-zA-Z0-9-]*[a-zA-Z0-9]$", var.namespace_name)))
    error_message = "namespace_name debe tener entre 6 y 50 caracteres alfanumÃ©ricos o guiones, iniciando con una letra."
  }
}

variable "name" {
  type        = string
  description = "Alias para el nombre del Service Bus Namespace."
  default     = null

  validation {
    condition     = var.name == null ? true : (length(trimspace(var.name)) >= 6 && length(trimspace(var.name)) <= 50 && can(regex("^[a-zA-Z][a-zA-Z0-9-]*[a-zA-Z0-9]$", var.name)))
    error_message = "name debe tener entre 6 y 50 caracteres alfanumÃ©ricos o guiones, iniciando con una letra."
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
  description = "RegiÃ³n de Azure donde se aprovisionarÃ¡ el Service Bus Namespace (default northcentralus)."
  default     = "northcentralus"

  validation {
    condition     = length(trimspace(var.location)) > 0
    error_message = "La regiÃ³n (location) no puede estar vacÃ­a."
  }
}

variable "sku" {
  type        = string
  description = "SKU del Azure Service Bus Namespace ('Basic', 'Standard' o 'Premium'). Default Standard para soporte Pub/Sub."
  default     = "Standard"

  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.sku)
    error_message = "sku debe ser Basic, Standard o Premium."
  }
}

variable "capacity" {
  type        = number
  description = "Unidades de mensajerÃ­a para SKU Premium (1, 2, 4, 8, 16). Null para Basic o Standard."
  default     = null

  validation {
    condition     = var.capacity == null ? true : (contains([1, 2, 4, 8, 16], var.capacity))
    error_message = "capacity solo aplica a SKU Premium y debe ser 1, 2, 4, 8 o 16."
  }
}

variable "local_auth_enabled" {
  type        = bool
  description = "Habilita autenticaciÃ³n local basada en SAS (connection strings). Default false por seguridad Zero-Trust (100% Entra ID RBAC)."
  default     = false
}

variable "minimum_tls_version" {
  type        = string
  description = "VersiÃ³n mÃ­nima de TLS requerida para conexiones con el Service Bus Namespace (default 1.2)."
  default     = "1.2"

  validation {
    condition     = contains(["1.0", "1.1", "1.2"], var.minimum_tls_version)
    error_message = "minimum_tls_version debe ser 1.0, 1.1 o 1.2."
  }
}

variable "public_network_access_enabled" {
  type        = bool
  description = "Habilita o deshabilita el acceso desde redes pÃºblicas (default true para dev; parametrizable a false con Private Endpoint en prod)."
  default     = true
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
