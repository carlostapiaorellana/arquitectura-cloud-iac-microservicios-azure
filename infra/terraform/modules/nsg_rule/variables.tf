variable "name" {
  type        = string
  description = "Nombre descriptivo de la regla de seguridad de red (ej. allow-mysql-from-aca)."

  validation {
    condition     = length(trimspace(var.name)) >= 1 && length(trimspace(var.name)) <= 80
    error_message = "El nombre de la regla NSG debe tener entre 1 y 80 caracteres."
  }
}

variable "priority" {
  type        = number
  description = "Prioridad de evaluación de la regla NSG (entre 100 y 4096; menor número indica mayor prioridad)."

  validation {
    condition     = var.priority >= 100 && var.priority <= 4096 && floor(var.priority) == var.priority
    error_message = "La prioridad (priority) debe ser un número entero entre 100 y 4096."
  }
}

variable "direction" {
  type        = string
  description = "Dirección del tráfico evaluado por la regla (Inbound o Outbound)."

  validation {
    condition     = contains(["Inbound", "Outbound"], var.direction)
    error_message = "La dirección (direction) debe ser 'Inbound' o 'Outbound'."
  }
}

variable "access" {
  type        = string
  description = "Acción a aplicar sobre el tráfico coincidente (Allow o Deny)."

  validation {
    condition     = contains(["Allow", "Deny"], var.access)
    error_message = "El acceso (access) debe ser 'Allow' o 'Deny'."
  }
}

variable "protocol" {
  type        = string
  description = "Protocolo de red de capa 4 aplicable a la regla (Tcp, Udp, Icmp, Esp, Ah o *)."

  validation {
    condition     = contains(["Tcp", "Udp", "Icmp", "Esp", "Ah", "*"], var.protocol)
    error_message = "El protocolo (protocol) debe ser uno de: 'Tcp', 'Udp', 'Icmp', 'Esp', 'Ah' o '*'."
  }
}

variable "source_port_range" {
  type        = string
  description = "Puerto o rango de puertos de origen (ej. '*' o '1024-65535')."
  default     = "*"
}

variable "destination_port_range" {
  type        = string
  description = "Puerto o rango de puertos de destino (ej. '3306', '443', '*')."
}

variable "source_address_prefix" {
  type        = string
  description = "Prefijo CIDR o Service Tag de origen (ej. '10.0.0.0/23', 'VirtualNetwork')."
}

variable "destination_address_prefix" {
  type        = string
  description = "Prefijo CIDR o Service Tag de destino (ej. '10.0.2.0/24', '*')."
}

variable "resource_group_name" {
  type        = string
  description = "Nombre del Resource Group donde reside el Network Security Group."

  validation {
    condition     = length(trimspace(var.resource_group_name)) >= 1
    error_message = "El nombre del Resource Group no puede estar vacío."
  }
}

variable "network_security_group_name" {
  type        = string
  description = "Nombre del Network Security Group al que se adjuntará la regla."

  validation {
    condition     = length(trimspace(var.network_security_group_name)) >= 1
    error_message = "El nombre del Network Security Group (network_security_group_name) no puede estar vacío."
  }
}

variable "description" {
  type        = string
  description = "Descripción opcional del propósito de la regla de seguridad (máximo 140 caracteres)."
  default     = null
}
