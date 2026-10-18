locals {
  effective_identity_ids = distinct(compact(concat(var.identity_ids, var.user_assigned_identity_id != null ? [var.user_assigned_identity_id] : [])))
  effective_registries = length(var.registries) > 0 ? var.registries : (
    var.acr_login_server != null ? [{
      server               = var.acr_login_server
      identity             = coalesce(var.user_assigned_identity_id, length(local.effective_identity_ids) > 0 ? local.effective_identity_ids[0] : null)
      username             = null
      password_secret_name = null
    }] : []
  )
}

resource "azurerm_container_app" "this" {
  name                         = coalesce(var.app_name, var.name)
  container_app_environment_id = var.container_app_environment_id
  resource_group_name          = var.resource_group_name
  revision_mode                = var.revision_mode

  dynamic "identity" {
    for_each = length(local.effective_identity_ids) > 0 ? [1] : []
    content {
      type         = "UserAssigned"
      identity_ids = local.effective_identity_ids
    }
  }

  dynamic "registry" {
    for_each = local.effective_registries
    content {
      server               = registry.value.server
      identity             = registry.value.identity
      username             = registry.value.username
      password_secret_name = registry.value.password_secret_name
    }
  }

  dynamic "secret" {
    for_each = var.secrets
    content {
      name                = secret.value.name
      value               = secret.value.value
      key_vault_secret_id = secret.value.key_vault_secret_id
      identity            = secret.value.identity
    }
  }

  dynamic "ingress" {
    for_each = var.ingress_enabled ? [1] : []
    content {
      external_enabled           = var.external_enabled
      target_port                = var.target_port
      transport                  = var.transport
      allow_insecure_connections = var.allow_insecure_connections

      dynamic "traffic_weight" {
        for_each = var.traffic_weights
        content {
          percentage      = traffic_weight.value.percentage
          latest_revision = traffic_weight.value.latest_revision
          revision_suffix = traffic_weight.value.revision_suffix
          label           = traffic_weight.value.label
        }
      }

      dynamic "ip_security_restriction" {
        for_each = var.ip_security_restrictions
        content {
          name             = ip_security_restriction.value.name
          ip_address_range = ip_security_restriction.value.ip_address_range
          action           = ip_security_restriction.value.action
          description      = ip_security_restriction.value.description
        }
      }
    }
  }

  template {
    min_replicas = var.min_replicas
    max_replicas = var.max_replicas

    container {
      name    = coalesce(var.container_name, var.app_name, var.name)
      image   = var.image
      cpu     = var.cpu
      memory  = var.memory
      args    = var.container_args
      command = var.container_command

      dynamic "env" {
        for_each = var.environment_variables
        content {
          name        = env.value.name
          value       = env.value.value
          secret_name = env.value.secret_name
        }
      }

      dynamic "liveness_probe" {
        for_each = var.liveness_probe != null ? [var.liveness_probe] : []
        content {
          port                    = liveness_probe.value.port
          transport               = liveness_probe.value.transport
          path                    = liveness_probe.value.path
          initial_delay           = liveness_probe.value.initial_delay
          interval_seconds        = liveness_probe.value.interval_seconds
          timeout                 = liveness_probe.value.timeout
          failure_count_threshold = liveness_probe.value.failure_count_threshold
        }
      }

      dynamic "readiness_probe" {
        for_each = var.readiness_probe != null ? [var.readiness_probe] : []
        content {
          port                    = readiness_probe.value.port
          transport               = readiness_probe.value.transport
          path                    = readiness_probe.value.path
          interval_seconds        = readiness_probe.value.interval_seconds
          timeout                 = readiness_probe.value.timeout
          failure_count_threshold = readiness_probe.value.failure_count_threshold
          success_count_threshold = readiness_probe.value.success_count_threshold
        }
      }
    }
  }

  tags = var.tags

  lifecycle {
    precondition {
      condition     = var.app_name != null || var.name != null
      error_message = "Debe especificar 'app_name' o 'name' para la Container App."
    }
    precondition {
      condition     = !(var.external_enabled == true && var.service_role != "gateway")
      error_message = "Violación de Regla Dura de Seguridad Zero-Trust (@secops-guardian / AGENTS.md): external_enabled = true solo está permitido para el servicio con service_role = 'gateway'. Los microservicios de dominio y caché deben tener external_enabled = false."
    }
  }
}
