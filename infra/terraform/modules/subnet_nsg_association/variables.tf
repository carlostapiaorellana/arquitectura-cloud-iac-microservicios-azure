variable "subnet_id" {
  type        = string
  description = "ID de recurso de la subred en Azure a la cual se asociará el Network Security Group."

  validation {
    condition     = length(trimspace(var.subnet_id)) > 0
    error_message = "El ID de la subred (subnet_id) no puede estar vacío."
  }
}

variable "network_security_group_id" {
  type        = string
  description = "ID de recurso del Network Security Group que protegerá la subred."

  validation {
    condition     = length(trimspace(var.network_security_group_id)) > 0
    error_message = "El ID del Network Security Group (network_security_group_id) no puede estar vacío."
  }
}
