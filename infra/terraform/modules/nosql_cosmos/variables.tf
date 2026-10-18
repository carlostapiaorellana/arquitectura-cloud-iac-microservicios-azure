variable "account_name" {
  type        = string
  description = "Nombre Ãºnico de la cuenta de Azure Cosmos DB siguiendo CAF (ej. cosmos-univ-dev-ncus, entre 3 y 44 caracteres alfanumÃ©ricos en minÃºscula)."
  default     = null

  validation {
    condition     = var.account_name == null ? true : (length(trimspace(var.account_name)) >= 3 && length(trimspace(var.account_name)) <= 44 && can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", var.account_name)))
    error_message = "account_name debe tener entre 3 y 44 caracteres alfanumÃ©ricos en minÃºscula o guiones."
  }
}

variable "name" {
  type        = string
  description = "Alias para el nombre de la cuenta de Azure Cosmos DB."
  default     = null

  validation {
    condition     = var.name == null ? true : (length(trimspace(var.name)) >= 3 && length(trimspace(var.name)) <= 44 && can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", var.name)))
    error_message = "name debe tener entre 3 y 44 caracteres alfanumÃ©ricos en minÃºscula o guiones."
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
  description = "Región de Azure para Cosmos DB (default northcentralus)."
  default     = "northcentralus"

  validation {
    condition     = length(trimspace(var.location)) > 0
    error_message = "La región (location) no puede estar vacía."
  }
}

variable "cosmos_location" {
  type        = string
  description = "Región de Azure para la cuenta y réplica de datos de Cosmos DB (default eastus por disponibilidad de capacidad en Azure for Students)."
  default     = "eastus"

  validation {
    condition     = length(trimspace(var.cosmos_location)) > 0
    error_message = "cosmos_location no puede estar vacío."
  }
}

variable "database_name" {
  type        = string
  description = "Nombre de la base de datos SQL/NoSQL en Cosmos DB (default univ_nosql_db)."
  default     = "univ_nosql_db"
}

variable "offer_type" {
  type        = string
  description = "Tipo de oferta de Cosmos DB (Standard)."
  default     = "Standard"
}

variable "kind" {
  type        = string
  description = "Tipo de API para Cosmos DB (GlobalDocumentDB para NoSQL)."
  default     = "GlobalDocumentDB"
}

variable "consistency_level" {
  type        = string
  description = "Nivel de consistencia de Cosmos DB (Session, Eventual, Strong, BoundedStaleness, ConsistentPrefix)."
  default     = "Session"

  validation {
    condition     = contains(["Session", "Eventual", "Strong", "BoundedStaleness", "ConsistentPrefix"], var.consistency_level)
    error_message = "consistency_level debe ser Session, Eventual, Strong, BoundedStaleness o ConsistentPrefix."
  }
}

variable "free_tier_enabled" {
  type        = bool
  description = "Habilita la asignaciÃ³n de Azure Cosmos DB Free Tier (1000 RU/s y 25 GB de almacenamiento sin costo)."
  default     = true
}

variable "throughput" {
  type        = number
  description = "Throughput compartido a nivel de base de datos en RU/s (default 1000 RU/s para Free Tier)."
  default     = 1000

  validation {
    condition     = var.throughput == null ? true : (var.throughput >= 400 && var.throughput <= 1000000)
    error_message = "throughput debe estar entre 400 y 1,000,000 RU/s o null si se gestiona por contenedor."
  }
}

variable "public_network_access_enabled" {
  type        = bool
  description = "Habilita o deshabilita el acceso desde redes pÃºblicas (default false para Zero-Trust)."
  default     = false
}

variable "containers" {
  type = map(object({
    partition_key_paths   = list(string)
    partition_key_version = optional(number, 1)
    default_ttl           = optional(number)
    throughput            = optional(number)
  }))
  description = "Mapa de contenedores NoSQL a aprovisionar en la base de datos de Cosmos DB."
  default = {
    "library_catalogs" = {
      partition_key_paths   = ["/category"]
      partition_key_version = 1
      default_ttl           = -1
    }
    "library_loans" = {
      partition_key_paths   = ["/studentId"]
      partition_key_version = 1
      default_ttl           = -1
    }
    "lms_courses" = {
      partition_key_paths   = ["/sectionId"]
      partition_key_version = 1
      default_ttl           = -1
    }
    "lms_enrollments" = {
      partition_key_paths   = ["/courseId"]
      partition_key_version = 1
      default_ttl           = -1
    }
  }
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
