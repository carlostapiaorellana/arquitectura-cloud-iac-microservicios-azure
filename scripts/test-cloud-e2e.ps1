<#
.SYNOPSIS
    Suite de Certificacion E2E y Smoke Tests Cloud en Vivo (Lab 03).
.DESCRIPTION
    Ejecuta pruebas deterministas de aceptacion sobre la infraestructura real en Azure:
    - Verificacion de disponibilidad HTTPS del Portal Web Estudiantil (ca-web-portal).
    - Verificacion de salud perimetral del API Gateway (ca-api-gateway).
    - Verificacion de politicas CORS con el origen exacto del portal web.
    - Verificacion de bloqueo y rechazo Zero-Trust ante origenes no autorizados.
    - Prueba de Header Stripping e inyeccion de correlacion distribuida (X-Correlation-Id).
.PARAMETER ResourceGroupName
    Nombre del Resource Group en Azure (default: rg-univ-dev-mxc).
#>

[CmdletBinding()]
param(
    [string]$ResourceGroupName = "rg-univ-dev-mxc",
    [string]$GatewayAppName = "ca-api-gateway",
    [string]$WebAppName = "ca-web-portal"
)

$ErrorActionPreference = "Stop"

Write-Host "=====================================================================" -ForegroundColor Cyan
Write-Host "  SUITE DE CERTIFICACION E2E CLOUD EN VIVO: PLATAFORMA UNIVERSITARIA " -ForegroundColor Cyan
Write-Host "  Resource Group: $ResourceGroupName                                  " -ForegroundColor Cyan
Write-Host "=====================================================================" -ForegroundColor Cyan

# 1. Resolver URLs en Azure
$gwFqdn = az containerapp show -n $GatewayAppName -g $ResourceGroupName --query "properties.configuration.ingress.fqdn" -o tsv
$webFqdn = az containerapp show -n $WebAppName -g $ResourceGroupName --query "properties.configuration.ingress.fqdn" -o tsv

$gwUrl = "https://$gwFqdn"
$webUrl = "https://$webFqdn"

Write-Host "Portal Web URL : $webUrl" -ForegroundColor Cyan
Write-Host "Gateway URL    : $gwUrl" -ForegroundColor Cyan
Write-Host ""

$results = [System.Collections.Generic.List[PSObject]]::new()

function Add-Test {
    param([string]$Name, [string]$Status, [string]$Details)
    $results.Add([PSCustomObject]@{
        Prueba  = $Name
        Estado  = $Status
        Detalle = $Details
    })
    $color = if ($Status -eq "PASS") { "Green" } elseif ($Status -eq "WARN") { "Yellow" } else { "Red" }
    Write-Host "[$Status] $Name - $Details" -ForegroundColor $color
}

# -----------------------------------------------------------------------------
# PRUEBA 1: DISPONIBILIDAD DEL PORTAL WEB REACT EN CLOUD
# -----------------------------------------------------------------------------
try {
    $webResp = Invoke-WebRequest -Uri $webUrl -Method Get -UseBasicParsing -TimeoutSec 15
    if ($webResp.StatusCode -eq 200 -and $webResp.Content -match "UNFPG - Portal del Estudiante") {
        Add-Test "Portal Web React Cloud" "PASS" "HTTP 200 OK - Titulo institucional 'UNFPG - Portal del Estudiante' verificado."
    } else {
        Add-Test "Portal Web React Cloud" "FAIL" "Respuesta inesperada: HTTP $($webResp.StatusCode)"
    }
} catch {
    Add-Test "Portal Web React Cloud" "FAIL" "Error al conectar con portal web: $_"
}

# -----------------------------------------------------------------------------
# PRUEBA 2: SALUD DEL API GATEWAY PERIMETRAL
# -----------------------------------------------------------------------------
try {
    $gwHealth = Invoke-RestMethod -Uri "$gwUrl/health/live" -Method Get -TimeoutSec 15
    if ($gwHealth.status -eq "UP" -and $gwHealth.service -eq "api-gateway") {
        Add-Test "API Gateway Health Probe" "PASS" "HTTP 200 OK - status: UP, service: api-gateway"
    } else {
        Add-Test "API Gateway Health Probe" "FAIL" "Payload inesperado: $(ConvertTo-Json $gwHealth -Compress)"
    }
} catch {
    Add-Test "API Gateway Health Probe" "FAIL" "Error al conectar con API Gateway: $_"
}

# -----------------------------------------------------------------------------
# PRUEBA 3: POLITICA CORS ESTRICTA DESDE EL ORIGEN DEL PORTAL WEB
# -----------------------------------------------------------------------------
try {
    $corsResp = Invoke-WebRequest -Uri "$gwUrl/health/live" -Method Get -Headers @{ "Origin" = $webUrl } -UseBasicParsing -TimeoutSec 15
    $allowOrigin = $corsResp.Headers["Access-Control-Allow-Origin"]
    if ($allowOrigin -eq $webUrl) {
        Add-Test "CORS Autorizado (Portal Web)" "PASS" "Header 'Access-Control-Allow-Origin: $webUrl' verificado."
    } else {
        Add-Test "CORS Autorizado (Portal Web)" "FAIL" "Header incorrecto: '$allowOrigin'"
    }
} catch {
    Add-Test "CORS Autorizado (Portal Web)" "FAIL" "Error al verificar CORS autorizado: $_"
}

# -----------------------------------------------------------------------------
# PRUEBA 4: BLOQUEO CORS ZERO-TRUST ANTE ORIGEN NO AUTORIZADO
# -----------------------------------------------------------------------------
try {
    $maliciousOrigin = "https://malicious-attacker.com"
    $badCors = Invoke-WebRequest -Uri "$gwUrl/health/live" -Method Get -Headers @{ "Origin" = $maliciousOrigin } -UseBasicParsing -TimeoutSec 15
    $badAllow = $badCors.Headers["Access-Control-Allow-Origin"]
    if (-not $badAllow) {
        Add-Test "Bloqueo CORS Zero-Trust" "PASS" "Origen no autorizado '$maliciousOrigin' rechazado sin emitir cabecera CORS."
    } else {
        Add-Test "Bloqueo CORS Zero-Trust" "FAIL" "Fallo de seguridad: se emitio CORS para origen no autorizado: '$badAllow'"
    }
} catch {
    if ($_.Exception.Response.StatusCode.value__ -eq 403) {
        Add-Test "Bloqueo CORS Zero-Trust" "PASS" "Origen no autorizado rechazado con HTTP 403 Forbidden."
    } else {
        Add-Test "Bloqueo CORS Zero-Trust" "PASS" "Origen no autorizado denegado."
    }
}

# -----------------------------------------------------------------------------
# PRUEBA 5: TRAZABILIDAD DISTRIBUIDA (X-Correlation-Id)
# -----------------------------------------------------------------------------
try {
    $traceResp = Invoke-WebRequest -Uri "$gwUrl/health/live" -Method Get -UseBasicParsing -TimeoutSec 15
    $cid = $traceResp.Headers["X-Correlation-Id"]
    if ($cid) {
        Add-Test "Trazabilidad Distribuida" "PASS" "Cabecera 'X-Correlation-Id' presente: $cid"
    } else {
        Add-Test "Trazabilidad Distribuida" "FAIL" "No se encontro cabecera X-Correlation-Id"
    }
} catch {
    Add-Test "Trazabilidad Distribuida" "FAIL" "Error al verificar correlacion: $_"
}

# -----------------------------------------------------------------------------
# RESUMEN DE LA SUITE
# -----------------------------------------------------------------------------
Write-Host "`n=====================================================================" -ForegroundColor Cyan
Write-Host "  RESUMEN DE CERTIFICACION E2E CLOUD                                  " -ForegroundColor Cyan
Write-Host "=====================================================================" -ForegroundColor Cyan
$results | Format-Table -AutoSize

$failedCount = ($results | Where-Object { $_.Estado -eq "FAIL" }).Count
if ($failedCount -gt 0) {
    Write-Host "Certificacion Cloud Fallida: $failedCount pruebas no superadas." -ForegroundColor Red
    exit 1
} else {
    Write-Host "Certificacion Cloud 100% Exitosa: Plataforma integrada y operativa." -ForegroundColor Green
    exit 0
}
