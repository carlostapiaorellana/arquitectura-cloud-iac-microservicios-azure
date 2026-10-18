<#
.SYNOPSIS
    Script de Despliegue de la Plataforma Universitaria en Azure Cloud (Lab 03).
.DESCRIPTION
    Compila el Frontend React optimizado para produccion con la URL del Gateway Cloud,
    empaqueta en Nginx unprivileged (no-root), publica la imagen en Azure Container Registry
    y despliega la aplicacion web en Azure Container Apps con escalado automatico a cero ($0.00 USD).
.PARAMETER ResourceGroupName
    Nombre del Resource Group en Azure (default: rg-univ-dev-mxc).
.PARAMETER AcrName
    Nombre del Azure Container Registry (default: crunivdevmxc).
#>

[CmdletBinding()]
param(
    [string]$ResourceGroupName = "rg-univ-dev-mxc",
    [string]$AcrName = "crunivdevmxc",
    [string]$EnvironmentName = "cae-univ-dev-mxc",
    [string]$GatewayAppName = "ca-api-gateway",
    [string]$WebAppName = "ca-web-portal"
)

$ErrorActionPreference = "Stop"

Write-Host "=====================================================================" -ForegroundColor Cyan
Write-Host "  DESPLIEGUE CLOUD-NATIVE EN AZURE CONTAINER APPS                     " -ForegroundColor Cyan
Write-Host "  Resource Group: $ResourceGroupName                                  " -ForegroundColor Cyan
Write-Host "=====================================================================" -ForegroundColor Cyan

# 1. Obtener FQDN del Gateway
Write-Host "`n--- 1. Resolviendo Ingress del API Gateway Cloud ---" -ForegroundColor Yellow
$gatewayFqdn = az containerapp show -n $GatewayAppName -g $ResourceGroupName --query "properties.configuration.ingress.fqdn" -o tsv
if (-not $gatewayFqdn) {
    Write-Host "ERROR: No se pudo resolver el FQDN de $GatewayAppName" -ForegroundColor Red
    exit 1
}
$gatewayBaseUrl = "https://$gatewayFqdn/api/v1"
Write-Host "Gateway FQDN     : $gatewayFqdn" -ForegroundColor Green
Write-Host "Gateway API Base : $gatewayBaseUrl" -ForegroundColor Green

# 2. Login a Azure Container Registry
Write-Host "`n--- 2. Autenticando Docker en Azure Container Registry ---" -ForegroundColor Yellow
az acr login -n $AcrName
Write-Host "Docker autenticado exitosamente en $AcrName.azurecr.io" -ForegroundColor Green

# 3. Compilacion y Push de la Imagen Web
Write-Host "`n--- 3. Compilando y Publicando Imagen Web en ACR ---" -ForegroundColor Yellow
$imageTag = "$AcrName.azurecr.io/$WebAppName`:latest"
$labDir = Split-Path -Parent $PSScriptRoot

docker build --build-arg "VITE_API_BASE_URL=$gatewayBaseUrl" -t $imageTag -f "$labDir/apps/web/Dockerfile" "$labDir/apps/web"
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR al compilar imagen Docker de $WebAppName" -ForegroundColor Red
    exit 1
}

docker push $imageTag
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR al publicar imagen Docker en $AcrName" -ForegroundColor Red
    exit 1
}
Write-Host "Imagen publicada exitosamente: $imageTag" -ForegroundColor Green

# 4. Despliegue / Actualizacion de Container App
Write-Host "`n--- 4. Desplegando Container App $WebAppName ---" -ForegroundColor Yellow
$identityId = az identity show -n id-gateway-dev-mxc -g $ResourceGroupName --query "id" -o tsv

$appExists = az containerapp show -n $WebAppName -g $ResourceGroupName --query "name" -o tsv 2>$null
if ($appExists) {
    Write-Host "Actualizando contenedor existente $WebAppName..." -ForegroundColor Cyan
    az containerapp update -n $WebAppName -g $ResourceGroupName --image $imageTag
} else {
    Write-Host "Creando nuevo contenedor $WebAppName..." -ForegroundColor Cyan
    az containerapp create -n $WebAppName -g $ResourceGroupName `
        --environment $EnvironmentName `
        --image $imageTag `
        --target-port 8080 `
        --ingress external `
        --user-assigned $identityId `
        --registry-server "$AcrName.azurecr.io" `
        --registry-identity $identityId `
        --cpu 0.25 --memory 0.5Gi `
        --min-replicas 0 --max-replicas 1 `
        --tags Project=plataforma-universitaria Environment=dev Owner=StaffEngineer CostCenter=CC-101 ManagedBy=Terraform DataClassification=Internal
}

$webFqdn = az containerapp show -n $WebAppName -g $ResourceGroupName --query "properties.configuration.ingress.fqdn" -o tsv
Write-Host "Web Portal FQDN  : https://$webFqdn" -ForegroundColor Green

# 5. Configurar CORS en el Gateway
Write-Host "`n--- 5. Sincronizando Politicas CORS en API Gateway ---" -ForegroundColor Yellow
$allowedOrigins = "http://localhost:3000,http://localhost:5173,https://$webFqdn,https://apim-univ-dev-mxc.azure-api.net"
az containerapp update -n $GatewayAppName -g $ResourceGroupName --set-env-vars ALLOWED_ORIGINS="$allowedOrigins" ENV="production"
Write-Host "Politicas CORS sincronizadas para: $allowedOrigins" -ForegroundColor Green

Write-Host "`n=====================================================================" -ForegroundColor Cyan
Write-Host "  DESPLIEGUE FINALIZADO EXITOSAMENTE                                  " -ForegroundColor Cyan
Write-Host "  Portal Web : https://$webFqdn                                      " -ForegroundColor Green
Write-Host "  Gateway    : https://$gatewayFqdn                                  " -ForegroundColor Green
Write-Host "=====================================================================" -ForegroundColor Cyan
