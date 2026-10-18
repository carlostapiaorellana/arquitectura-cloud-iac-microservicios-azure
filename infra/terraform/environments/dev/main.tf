# ==============================================================================
# ORQUESTADOR RAÍZ DE ENTORNO: dev (Azure for Students - Enterprise Tier-1 Efímero)
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. Resource Group
# ------------------------------------------------------------------------------
resource "azurerm_resource_group" "rg" {
  name     = "rg-${var.project_name}-${var.environment}-${var.region_code}"
  location = var.location
  tags     = var.tags
}

# ------------------------------------------------------------------------------
# 2. Red y Aislamiento Perimetral (Fase A)
# ------------------------------------------------------------------------------
module "vnet" {
  source              = "../../modules/vnet"
  vnet_name           = "vnet-${var.project_name}-${var.environment}-${var.region_code}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  address_space       = ["10.0.0.0/16"]
  tags                = var.tags
}

module "subnet_aca" {
  source                          = "../../modules/subnet"
  subnet_name                     = "snet-aca"
  resource_group_name             = azurerm_resource_group.rg.name
  virtual_network_name            = module.vnet.name
  address_prefixes                = ["10.0.0.0/23"]
  default_outbound_access_enabled = true
  delegation = {
    name         = "aca-delegation"
    service_name = "Microsoft.App/environments"
    actions      = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
  }
}

module "subnet_data" {
  source               = "../../modules/subnet"
  subnet_name          = "snet-data"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = module.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
  service_endpoints    = ["Microsoft.Storage"]
  delegation = {
    name         = "mysql-delegation"
    service_name = "Microsoft.DBforMySQL/flexibleServers"
    actions      = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
  }
}

module "subnet_pe" {
  source               = "../../modules/subnet"
  subnet_name          = "snet-pe"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = module.vnet.name
  address_prefixes     = ["10.0.3.0/24"]
}

module "nsg_aca" {
  source              = "../../modules/nsg"
  nsg_name            = "nsg-aca"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  tags                = var.tags
}

module "nsg_data" {
  source              = "../../modules/nsg"
  nsg_name            = "nsg-data"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  tags                = var.tags
}

module "nsg_pe" {
  source              = "../../modules/nsg"
  nsg_name            = "nsg-pe"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  tags                = var.tags
}

module "subnet_nsg_association_aca" {
  source                    = "../../modules/subnet_nsg_association"
  subnet_id                 = module.subnet_aca.id
  network_security_group_id = module.nsg_aca.id
}

module "subnet_nsg_association_data" {
  source                    = "../../modules/subnet_nsg_association"
  subnet_id                 = module.subnet_data.id
  network_security_group_id = module.nsg_data.id
}

module "subnet_nsg_association_pe" {
  source                    = "../../modules/subnet_nsg_association"
  subnet_id                 = module.subnet_pe.id
  network_security_group_id = module.nsg_pe.id
}

# ------------------------------------------------------------------------------
# 3. Zonas DNS Privadas y Enlaces (Fase A)
# ------------------------------------------------------------------------------
module "private_dns_mysql" {
  source              = "../../modules/private_dns_zone"
  dns_zone_name       = "privatelink.mysql.database.azure.com"
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags
}

module "private_dns_vnet_link_mysql" {
  source                = "../../modules/private_dns_vnet_link"
  link_name             = "vnetlink-mysql"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = module.private_dns_mysql.name
  virtual_network_id    = module.vnet.id
  tags                  = var.tags
}

module "private_dns_vault" {
  source              = "../../modules/private_dns_zone"
  dns_zone_name       = "privatelink.vaultcore.azure.net"
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags
}

module "private_dns_vnet_link_vault" {
  source                = "../../modules/private_dns_vnet_link"
  link_name             = "vnetlink-vault"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = module.private_dns_vault.name
  virtual_network_id    = module.vnet.id
  tags                  = var.tags
}

# ------------------------------------------------------------------------------
# 4. Seguridad, Secretos e Identidad Zero-Trust (Fase A)
# ------------------------------------------------------------------------------
data "azurerm_client_config" "current" {}

module "key_vault" {
  source                     = "../../modules/key_vault"
  key_vault_name             = "kv-${var.project_name}-${var.environment}-${var.region_code}"
  resource_group_name        = azurerm_resource_group.rg.name
  location                   = var.location
  tenant_id                  = try(length(data.azurerm_client_config.current.tenant_id) > 0 ? data.azurerm_client_config.current.tenant_id : var.tenant_id, var.tenant_id)
  sku_name                   = "standard"
  enable_rbac_authorization  = true
  purge_protection_enabled   = false
  soft_delete_retention_days = 7
  tags                       = var.tags
}

module "user_assigned_identity" {
  source              = "../../modules/user_assigned_identity"
  identity_name       = "id-gateway-${var.environment}-${var.region_code}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  tags                = var.tags
}

# ------------------------------------------------------------------------------
# 5. Observabilidad Centralizada (Fase B)
# ------------------------------------------------------------------------------
module "log_analytics" {
  source              = "../../modules/log_analytics_workspace"
  workspace_name      = "log-${var.project_name}-${var.environment}-${var.region_code}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
  daily_quota_gb      = 0.5
  tags                = var.tags
}

module "app_insights" {
  source              = "../../modules/app_insights"
  app_insights_name   = "appi-${var.project_name}-${var.environment}-${var.region_code}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  workspace_id        = module.log_analytics.id
  tags                = var.tags
}

# ------------------------------------------------------------------------------
# 6. Persistencia Relacional y NoSQL Políglota (Fase B)
# ------------------------------------------------------------------------------
module "mysql_server" {
  source                 = "../../modules/mysql_flexible_server"
  server_name            = "mysql-${var.project_name}-${var.environment}-${var.region_code}"
  resource_group_name    = azurerm_resource_group.rg.name
  location               = var.location
  administrator_login    = var.mysql_admin_username
  administrator_password = var.mysql_admin_password
  sku_name               = "B_Standard_B1ms"
  delegated_subnet_id    = module.subnet_data.id
  private_dns_zone_id    = module.private_dns_mysql.id
  storage_gb             = 20
  tags                   = var.tags
  depends_on             = [module.private_dns_vnet_link_mysql]
}

module "mysql_databases" {
  for_each            = toset(["auth_db", "person_db", "academic_db", "enrollment_db", "finance_db"])
  source              = "../../modules/mysql_flexible_database"
  database_name       = each.value
  server_name         = module.mysql_server.name
  resource_group_name = azurerm_resource_group.rg.name
}

module "mysql_config_transport" {
  source              = "../../modules/mysql_flexible_configuration"
  configuration_name  = "require_secure_transport"
  server_name         = module.mysql_server.name
  resource_group_name = azurerm_resource_group.rg.name
  value               = "ON"
}

module "nosql_cosmos" {
  source              = "../../modules/nosql_cosmos"
  account_name        = "cosmos-${var.project_name}-${var.environment}-${var.region_code}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  cosmos_location     = var.cosmos_location
  free_tier_enabled   = true
  tags                = var.tags
}

# ------------------------------------------------------------------------------
# 7. Bus de Eventos EDA con Azure Service Bus (Fase C)
# ------------------------------------------------------------------------------
module "service_bus" {
  source              = "../../modules/service_bus_namespace"
  namespace_name      = "sb-${var.project_name}-${var.environment}-${var.region_code}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  sku                 = "Standard"
  tags                = var.tags
}

module "sb_topic_student" {
  source       = "../../modules/service_bus_topic"
  topic_name   = "student.events"
  namespace_id = module.service_bus.id
}

module "sb_topic_enrollment" {
  source       = "../../modules/service_bus_topic"
  topic_name   = "enrollment.events"
  namespace_id = module.service_bus.id
}

module "sb_queue_payments" {
  source       = "../../modules/service_bus_queue"
  queue_name   = "payments.processing"
  namespace_id = module.service_bus.id
}

# ------------------------------------------------------------------------------
# 8. Cómputo Serverless ACA & ACR (Fase D)
# ------------------------------------------------------------------------------
module "container_registry" {
  source              = "../../modules/container_registry"
  registry_name       = "cr${var.project_name}${var.environment}${var.region_code}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  sku                 = "Basic"
  admin_enabled       = false
  tags                = var.tags
}

module "role_assignment_acr_pull" {
  source                           = "../../modules/role_assignment"
  scope                            = module.container_registry.id
  principal_id                     = module.user_assigned_identity.principal_id
  role_definition_name             = "AcrPull"
  skip_service_principal_aad_check = true
}

module "container_app_env" {
  source                     = "../../modules/container_app_env"
  environment_name           = "cae-${var.project_name}-${var.environment}-${var.region_code}"
  resource_group_name        = azurerm_resource_group.rg.name
  location                   = var.location
  infrastructure_subnet_id   = module.subnet_aca.id
  log_analytics_workspace_id = module.log_analytics.id
  tags                       = var.tags
}

module "ca_gateway" {
  source                       = "../../modules/container_app"
  app_name                     = "ca-api-gateway"
  resource_group_name          = azurerm_resource_group.rg.name
  container_app_environment_id = module.container_app_env.id
  identity_ids                 = [module.user_assigned_identity.id]
  user_assigned_identity_id    = module.user_assigned_identity.id
  acr_login_server             = module.container_registry.login_server
  service_role                 = "gateway"
  external_enabled             = true
  target_port                  = 8080
  min_replicas                 = 0
  max_replicas                 = 3
  image                        = "${module.container_registry.login_server}/ca-api-gateway:latest"
  cpu                          = 0.25
  memory                       = "0.5Gi"
  tags                         = var.tags
  depends_on                   = [module.role_assignment_acr_pull]
}

module "apim_backend" {
  source              = "../../modules/apim_backend"
  backend_name        = "backend-ca-gateway"
  api_management_name = module.apim_service.name
  resource_group_name = azurerm_resource_group.rg.name
  protocol            = "http"
  url                 = "https://${module.ca_gateway.ingress_fqdn}"
  title               = "Container Apps Gateway Backend"
}

module "apim_logger" {
  source              = "../../modules/apim_logger"
  logger_name         = "logger-appinsights"
  api_management_name = module.apim_service.name
  resource_group_name = azurerm_resource_group.rg.name
  instrumentation_key = module.app_insights.instrumentation_key
}

# ------------------------------------------------------------------------------
# 9. API Management Perimetral y Políticas (Fase E)
# ------------------------------------------------------------------------------
module "apim_service" {
  source               = "../../modules/apim_service"
  service_name         = "apim-${var.project_name}-${var.environment}-${var.region_code}"
  resource_group_name  = azurerm_resource_group.rg.name
  location             = var.location
  publisher_name       = var.publisher_name
  publisher_email      = var.publisher_email
  sku_name             = "Consumption_0"
  virtual_network_type = "None"
  tags                 = var.tags
}

module "apim_api_auth" {
  source              = "../../modules/apim_api"
  api_name            = "auth-api"
  api_management_name = module.apim_service.name
  resource_group_name = azurerm_resource_group.rg.name
  display_name        = "Authentication API"
  path                = "api/v1/auth"
  service_url         = "https://${module.ca_gateway.ingress_fqdn}/api/v1/auth"
}

module "apim_api_person" {
  source                = "../../modules/apim_api"
  api_name              = "person-api"
  api_management_name   = module.apim_service.name
  resource_group_name   = azurerm_resource_group.rg.name
  display_name          = "Person & Profile API"
  path                  = "api/v1/person"
  service_url           = "https://${module.ca_gateway.ingress_fqdn}/api/v1/person"
  subscription_required = true
}

module "apim_api_academic" {
  source              = "../../modules/apim_api"
  api_name            = "academic-api"
  api_management_name = module.apim_service.name
  resource_group_name = azurerm_resource_group.rg.name
  display_name        = "Academic Management API"
  path                = "api/v1/academic"
  service_url         = "https://${module.ca_gateway.ingress_fqdn}/api/v1/academic"
}

module "apim_api_enrollment" {
  source                = "../../modules/apim_api"
  api_name              = "enrollment-api"
  api_management_name   = module.apim_service.name
  resource_group_name   = azurerm_resource_group.rg.name
  display_name          = "Enrollment & Grades API"
  path                  = "api/v1/enrollment"
  service_url           = "https://${module.ca_gateway.ingress_fqdn}/api/v1/enrollment"
  subscription_required = true
}

module "apim_api_finance" {
  source                = "../../modules/apim_api"
  api_name              = "finance-api"
  api_management_name   = module.apim_service.name
  resource_group_name   = azurerm_resource_group.rg.name
  display_name          = "Finance & Payments API"
  path                  = "api/v1/finance"
  service_url           = "https://${module.ca_gateway.ingress_fqdn}/api/v1/finance"
  subscription_required = true
}

module "apim_api_library" {
  source              = "../../modules/apim_api"
  api_name            = "library-api"
  api_management_name = module.apim_service.name
  resource_group_name = azurerm_resource_group.rg.name
  display_name        = "Library Catalog & Loans API"
  path                = "api/v1/library"
  service_url         = "https://${module.ca_gateway.ingress_fqdn}/api/v1/library"
}

module "apim_api_lms" {
  source                = "../../modules/apim_api"
  api_name              = "lms-api"
  api_management_name   = module.apim_service.name
  resource_group_name   = azurerm_resource_group.rg.name
  display_name          = "LMS Virtual Classroom API"
  path                  = "api/v1/lms"
  service_url           = "https://${module.ca_gateway.ingress_fqdn}/api/v1/lms"
  subscription_required = true
}

module "apim_policy_global" {
  source            = "../../modules/apim_policy"
  api_management_id = module.apim_service.id
  backend_id        = module.apim_backend.backend_name
  allowed_origins   = ["http://localhost:3000", "http://localhost:5173"]
  rate_limit_calls  = 100
}

module "apim_product_core" {
  source              = "../../modules/apim_product"
  product_id          = "university-core-apis"
  api_management_name = module.apim_service.name
  resource_group_name = azurerm_resource_group.rg.name
  display_name        = "University Core APIs"
  description         = "APIs de autenticación, perfiles de estudiantes y gestión académica."
  api_names           = [module.apim_api_auth.name, module.apim_api_person.name, module.apim_api_academic.name]
}

module "apim_product_financial" {
  source              = "../../modules/apim_product"
  product_id          = "university-financial-apis"
  api_management_name = module.apim_service.name
  resource_group_name = azurerm_resource_group.rg.name
  display_name        = "University Financial APIs"
  description         = "APIs de tesorería, pasarela de pagos e historial de matrículas."
  api_names           = [module.apim_api_enrollment.name, module.apim_api_finance.name]
}

module "apim_subscription_web" {
  source              = "../../modules/apim_subscription"
  api_management_name = module.apim_service.name
  resource_group_name = azurerm_resource_group.rg.name
  display_name        = "Portal Web Estudiantil Subscription"
  product_id          = module.apim_product_core.id
}
