<#
.SYNOPSIS
    Despliegue integral de los 6 microservicios restantes y actualizacion del API Gateway y Web Portal en Azure Container Apps.
#>

[CmdletBinding()]
param(
    [string]$ResourceGroupName = "rg-univ-dev-mxc",
    [string]$AcrName = "crunivdevmxc",
    [string]$EnvironmentName = "cae-univ-dev-mxc"
)

$ErrorActionPreference = "Stop"

Write-Host "=====================================================================" -ForegroundColor Cyan
Write-Host "  DESPLIEGUE CLOUD DE MICROSERVICIOS Y CONEXION DE PLATAFORMA        " -ForegroundColor Cyan
Write-Host "  Resource Group: $ResourceGroupName                                  " -ForegroundColor Cyan
Write-Host "=====================================================================" -ForegroundColor Cyan

# 1. Obtener User-Assigned Identity
Write-Host "`n--- 1. Resolviendo Managed Identity ---" -ForegroundColor Yellow
$identityId = az identity show -n id-gateway-dev-mxc -g $ResourceGroupName --query "id" -o tsv
if (-not $identityId) {
    Write-Host "ERROR: No se pudo resolver la identidad id-gateway-dev-mxc" -ForegroundColor Red
    exit 1
}
Write-Host "Identity ID: $identityId" -ForegroundColor Green

# 2. Definir lista de servicios backend
$services = @(
    @{
        Name = "ca-person"
        Port = 8082
        Image = "$AcrName.azurecr.io/ca-person:latest"
        Env = @(
            "PORT=8082",
            "ENV=production",
            "MYSQL_HOST=mysql-univ-dev-mxc.privatelink.mysql.database.azure.com",
            "MYSQL_PORT=3306",
            "MYSQL_USER=univadmin",
            "MYSQL_PASSWORD=DevSecurePass2026!NCUS",
            "MYSQL_DATABASE=person_db",
            "REDIS_ADDR="
        )
    },
    @{
        Name = "ca-academic"
        Port = 8083
        Image = "$AcrName.azurecr.io/ca-academic:latest"
        Env = @(
            "PORT=8083",
            "ENV=production",
            "MYSQL_HOST=mysql-univ-dev-mxc.privatelink.mysql.database.azure.com",
            "MYSQL_PORT=3306",
            "MYSQL_USER=univadmin",
            "MYSQL_PASSWORD=DevSecurePass2026!NCUS",
            "MYSQL_DATABASE=academic_db"
        )
    },
    @{
        Name = "ca-enrollment"
        Port = 8084
        Image = "$AcrName.azurecr.io/ca-enrollment:latest"
        Env = @(
            "PORT=8084",
            "ENV=production",
            "MYSQL_HOST=mysql-univ-dev-mxc.privatelink.mysql.database.azure.com",
            "MYSQL_PORT=3306",
            "MYSQL_USER=univadmin",
            "MYSQL_PASSWORD=DevSecurePass2026!NCUS",
            "MYSQL_DATABASE=enrollment_db"
        )
    },
    @{
        Name = "ca-finance"
        Port = 8085
        Image = "$AcrName.azurecr.io/ca-finance:latest"
        Env = @(
            "PORT=8085",
            "ENV=production",
            "MYSQL_HOST=mysql-univ-dev-mxc.privatelink.mysql.database.azure.com",
            "MYSQL_PORT=3306",
            "MYSQL_USER=univadmin",
            "MYSQL_PASSWORD=DevSecurePass2026!NCUS",
            "MYSQL_DATABASE=finance_db",
            "REDIS_ADDR="
        )
    },
    @{
        Name = "ca-library"
        Port = 8086
        Image = "$AcrName.azurecr.io/ca-library:latest"
        Env = @(
            "PORT=8086",
            "ENV=production",
            "NOSQL_PROVIDER=memory"
        )
    },
    @{
        Name = "ca-lms"
        Port = 8087
        Image = "$AcrName.azurecr.io/ca-lms:latest"
        Env = @(
            "PORT=8087",
            "ENV=production",
            "NOSQL_PROVIDER=memory"
        )
    }
)

# 3. Desplegar cada microservicio
foreach ($svc in $services) {
    Write-Host "`n--- Desplegando $($svc.Name) (: $($svc.Port)) ---" -ForegroundColor Yellow
    $exists = az containerapp show -n $svc.Name -g $ResourceGroupName --query "name" -o tsv 2>$null
    if ($exists) {
        Write-Host "Actualizando contenedor existente $($svc.Name)..." -ForegroundColor Cyan
        az containerapp update -n $svc.Name -g $ResourceGroupName `
            --image $svc.Image `
            --set-env-vars $svc.Env
    } else {
        Write-Host "Creando nuevo contenedor $($svc.Name)..." -ForegroundColor Cyan
        az containerapp create -n $svc.Name -g $ResourceGroupName `
            --environment $EnvironmentName `
            --image $svc.Image `
            --target-port $svc.Port `
            --ingress internal `
            --allow-insecure true `
            --user-assigned $identityId `
            --registry-server "$AcrName.azurecr.io" `
            --registry-identity $identityId `
            --cpu 0.25 --memory 0.5Gi `
            --min-replicas 1 --max-replicas 1 `
            --env-vars $svc.Env `
            --tags Project=plataforma-universitaria Environment=dev
    }
    Write-Host "Servicio $($svc.Name) desplegado exitosamente." -ForegroundColor Green
}

# 4. Actualizar API Gateway con URLs internas upstream
Write-Host "`n--- Actualizando ca-api-gateway con rutas internas ---" -ForegroundColor Yellow
$gatewayEnv = @(
    "AUTH_SERVICE_URL=http://ca-auth.internal.greenglacier-aabec240.mexicocentral.azurecontainerapps.io",
    "PERSON_SERVICE_URL=http://ca-person.internal.greenglacier-aabec240.mexicocentral.azurecontainerapps.io",
    "ACADEMIC_SERVICE_URL=http://ca-academic.internal.greenglacier-aabec240.mexicocentral.azurecontainerapps.io",
    "ENROLLMENT_SERVICE_URL=http://ca-enrollment.internal.greenglacier-aabec240.mexicocentral.azurecontainerapps.io",
    "FINANCE_SERVICE_URL=http://ca-finance.internal.greenglacier-aabec240.mexicocentral.azurecontainerapps.io",
    "LIBRARY_SERVICE_URL=http://ca-library.internal.greenglacier-aabec240.mexicocentral.azurecontainerapps.io",
    "LMS_SERVICE_URL=http://ca-lms.internal.greenglacier-aabec240.mexicocentral.azurecontainerapps.io",
    "ALLOWED_ORIGINS=http://localhost:3000,http://localhost:5173,https://ca-web-portal.greenglacier-aabec240.mexicocentral.azurecontainerapps.io,https://apim-univ-dev-mxc.azure-api.net",
    "ENV=production"
)

az containerapp update -n ca-api-gateway -g $ResourceGroupName --set-env-vars $gatewayEnv
Write-Host "API Gateway actualizado con las 7 rutas upstream." -ForegroundColor Green

# 5. Actualizar ca-web-portal con la ultima imagen
Write-Host "`n--- Actualizando ca-web-portal ---" -ForegroundColor Yellow
az containerapp update -n ca-web-portal -g $ResourceGroupName --image "$AcrName.azurecr.io/ca-web-portal:latest" --set-env-vars REVISION_TRIGGER="2"
Write-Host "Web Portal actualizado exitosamente." -ForegroundColor Green

Write-Host "`n=====================================================================" -ForegroundColor Cyan
Write-Host "  DESPLIEGUE Y ENLACE DE TODOS LOS SERVICIOS COMPLETADO                " -ForegroundColor Cyan
Write-Host "=====================================================================" -ForegroundColor Cyan
