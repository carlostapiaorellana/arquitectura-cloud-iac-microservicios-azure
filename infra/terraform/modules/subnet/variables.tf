variable "subnet_name" {
  type        = string
  description = "Nombre de la subred tipada siguiendo CAF (ej. snet-apim, snet-aca, snet-data, snet-pe)."
  default     = null

  validation {
    condition     = var.subnet_name == null ? true : (length(trimspace(var.subnet_name)) >= 1 && length(trimspace(var.subnet_name)) <= 80)
    error_message = "El nombre de la subred (subnet_name) debe tener entre 1 y 80 caracteres."
  }
}

variable "name" {
  type        = string
  description = "Alias opcional para el nombre de la subred cuando no se especifica subnet_name."
  default     = null

  validation {
    condition     = var.name == null ? true : (length(trimspace(var.name)) >= 1 && length(trimspace(var.name)) <= 80)
    error_message = "El nombre de la subred (name) debe tener entre 1 y 80 caracteres."
  }
}

variable "resource_group_name" {
  type        = string
  description = "Nombre del Resource Group donde reside la red virtual."

  validation {
    condition     = length(trimspace(var.resource_group_name)) >= 1 && length(trimspace(var.resource_group_name)) <= 90
    error_message = "El nombre del Resource Group no puede estar vacÃ­o."
  }
}

variable "virtual_network_name" {
  type        = string
  description = "Nombre de la Virtual Network padre a la que pertenece la subred."

  validation {
    condition     = length(trimspace(var.virtual_network_name)) >= 2
    error_message = "El nombre de la Virtual Network (virtual_network_name) es obligatorio."
  }
}

variable "address_prefixes" {
  type        = list(string)
  description = "Lista de prefijos CIDR asignados a la subred (ej. [\"10.0.0.0/23\"])."

  validation {
    condition     = length(var.address_prefixes) > 0 && alltrue([for cidr in var.address_prefixes : can(cidrhost(cidr, 0))])
    error_message = "Debe especificar al menos un prefijo CIDR vÃ¡lido en address_prefixes."
  }
}

variable "service_endpoints" {
  type        = list(string)
  description = "Lista opcional de Service Endpoints habilitados en la subred."
  default     = []
}

variable "private_endpoint_network_policies" {
  type        = string
  description = "PolÃ­tica de red para Private Endpoints en la subred (Enabled, Disabled, NetworkSecurityGroupEnabled, RouteTableEnabled)."
  default     = "Enabled"

  validation {
    condition     = contains(["Enabled", "Disabled", "NetworkSecurityGroupEnabled", "RouteTableEnabled"], var.private_endpoint_network_policies)
    error_message = "private_endpoint_network_policies debe ser uno de: Enabled, Disabled, NetworkSecurityGroupEnabled, RouteTableEnabled."
  }
}

variable "default_outbound_access_enabled" {
  type        = bool
  description = "Define si la subred permite salida a Internet por defecto sin NAT Gateway/Load Balancer. Por seguridad Zero-Trust es false."
  default     = false
}

variable "delegation" {
  type = object({
    name         = string
    service_name = string
    actions      = optional(list(string), ["Microsoft.Network/virtualNetworks/subnets/join/action"])
  })
  description = "ConfiguraciÃ³n opcional de delegaciÃ³n de subred (ej. Microsoft.App/environments o Microsoft.DBforMySQL/flexibleServers)."
  default     = null
}

variable "delegations" {
  type = list(object({
    name         = string
    service_name = string
    actions      = optional(list(string), ["Microsoft.Network/virtualNetworks/subnets/join/action"])
  }))
  description = "Lista opcional de bloques de delegaciÃ³n para la subred."
  default     = []
}
