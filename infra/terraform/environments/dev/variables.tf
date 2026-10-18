variable "subscription_id" {
  type        = string
  description = "ID de la suscripción de Azure for Students."
  default     = "94846a8b-9491-4312-82bb-3082c340b45f"
}

variable "tenant_id" {
  type        = string
  description = "Tenant ID de Microsoft Entra ID."
  default     = "6418e6e8-7843-4ffb-8c18-154e7f3fedd8"
}

variable "environment" {
  type        = string
  description = "Entorno de despliegue (dev, staging, prod)."
  default     = "dev"
}

variable "location" {
  type        = string
  description = "Región de Azure para el entorno."
  default     = "mexicocentral"

  validation {
    condition     = contains(["mexicocentral", "northcentralus", "chilecentral"], var.location)
    error_message = "La región debe ser una de las admitidas por las políticas y cuotas de Azure for Students (mexicocentral, northcentralus, chilecentral)."
  }
}

variable "region_code" {
  type        = string
  description = "Código abreviado de región para nomenclatura de recursos CAF."
  default     = "mxc"
}

variable "project_name" {
  type        = string
  description = "Prefijo institucional del proyecto para nomenclatura CAF."
  default     = "univ"
}

variable "mysql_admin_username" {
  type        = string
  description = "Usuario administrador del servidor MySQL Flexible."
  default     = "univadmin"
}

variable "mysql_admin_password" {
  type        = string
  description = "Contraseña administradora para el servidor MySQL Flexible (sensible, suministrada vía TF_VAR o Key Vault)."
  sensitive   = true
}

variable "publisher_name" {
  type        = string
  description = "Nombre de la organización publicado en Azure API Management."
  default     = "Universidad Nacional Frontend Platform Group"
}

variable "publisher_email" {
  type        = string
  description = "Correo de contacto del administrador en Azure API Management."
  default     = "admin@universidad.edu.pe"
}

variable "tags" {
  type        = map(string)
  description = "Mapa de etiquetas obligatorias según cloud-standards."
  default = {
    Project            = "plataforma-universitaria"
    Environment        = "dev"
    Owner              = "cloud-architecture-team"
    CostCenter         = "academic-engineering"
    ManagedBy          = "terraform"
    DataClassification = "confidential"
  }

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

variable "cosmos_location" {
  type        = string
  description = "Región de Azure para la réplica de datos de Cosmos DB (default mexicocentral por política de regiones permitidas)."
  default     = "mexicocentral"
}
