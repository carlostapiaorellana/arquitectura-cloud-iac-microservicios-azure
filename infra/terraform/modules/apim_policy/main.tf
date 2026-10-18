locals {
  is_global      = var.api_name == null
  origins_xml    = join("\n            ", [for o in var.allowed_origins : "<origin>${o}</origin>"])
  backend_xml    = var.backend_id != null ? "<set-backend-service backend-id=\"${var.backend_id}\" />" : ""
  base_inbound   = local.is_global ? "" : "<base />\n        "
  base_backend   = local.is_global ? "<forward-request />" : "<base />"
  base_outbound  = local.is_global ? "" : "<base />"
  base_error     = local.is_global ? "" : "<base />"
  rate_limit_xml = (!local.is_global && var.rate_limit_calls > 0) ? "<rate-limit-by-key calls=\"${var.rate_limit_calls}\" renewal-period=\"${var.rate_limit_period_seconds}\" counter-key=\"@(context.Request.IpAddress)\" />" : ""

  default_xml_content = <<XML
<policies>
    <inbound>
        ${local.base_inbound}<cors allow-credentials="true">
            <allowed-origins>
            ${local.origins_xml}
            </allowed-origins>
            <allowed-methods preflight-result-max-age="86400">
                <method>GET</method>
                <method>POST</method>
                <method>PUT</method>
                <method>PATCH</method>
                <method>DELETE</method>
                <method>OPTIONS</method>
            </allowed-methods>
            <allowed-headers>
                <header>Authorization</header>
                <header>Content-Type</header>
                <header>X-Correlation-Id</header>
                <header>Idempotency-Key</header>
                <header>Ocp-Apim-Subscription-Key</header>
            </allowed-headers>
            <expose-headers>
                <header>X-Correlation-Id</header>
                <header>X-Cache</header>
            </expose-headers>
        </cors>
        <set-header name="X-User-Id" exists-action="delete" />
        <set-header name="X-User-Role" exists-action="delete" />
        <set-header name="X-User-Scopes" exists-action="delete" />
        <choose>
            <when condition="@(!context.Request.Headers.ContainsKey(&quot;X-Correlation-Id&quot;))">
                <set-header name="X-Correlation-Id" exists-action="override">
                    <value>@(Guid.NewGuid().ToString(&quot;D&quot;))</value>
                </set-header>
            </when>
        </choose>
        ${local.rate_limit_xml}
        ${local.backend_xml}
    </inbound>
    <backend>
        ${local.base_backend}
    </backend>
    <outbound>
        ${local.base_outbound}
    </outbound>
    <on-error>
        ${local.base_error}
    </on-error>
</policies>
XML

  effective_xml_content = var.xml_link == null ? coalesce(var.xml_content, local.default_xml_content) : null
}

resource "azurerm_api_management_api_policy" "this" {
  count               = var.api_name != null ? 1 : 0
  api_name            = var.api_name
  api_management_name = var.api_management_name
  resource_group_name = var.resource_group_name
  xml_content         = local.effective_xml_content
  xml_link            = var.xml_link

  lifecycle {
    precondition {
      condition     = var.api_management_name != null && var.resource_group_name != null
      error_message = "Debe especificar 'api_management_name' y 'resource_group_name' para una política a nivel de API."
    }
  }
}

resource "azurerm_api_management_policy" "this" {
  count             = var.api_name == null ? 1 : 0
  api_management_id = var.api_management_id
  xml_content       = local.effective_xml_content
  xml_link          = var.xml_link

  lifecycle {
    precondition {
      condition     = var.api_management_id != null
      error_message = "Debe especificar 'api_management_id' para una política a nivel global de APIM."
    }
  }
}
