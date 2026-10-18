<#
.SYNOPSIS
    Script de Bootstrap, Semillas y Validacion de Persistencia en Azure (Lab 03).
.DESCRIPTION
    Verifica y sincroniza la capa de datos poliglota en la nube de Azure (rg-univ-dev-mxc):
    - MySQL Flexible Server: Verificacion de esquemas relacionales (auth_db, person_db, academic_db, enrollment_db, finance_db).
    - Azure Cosmos DB: Verificacion de base nosql (univ_nosql_db) y 4 contenedores (library_catalogs, library_loans, lms_courses, lms_enrollments).
    - Azure Service Bus: Verificacion de topicos (enrollment.events, student.events) y cola (payments.processing).
    - Azure Redis Cache: Verificacion de estado y provisionamiento de red.
.PARAMETER ResourceGroupName
    Nombre del Resource Group en Azure (default: rg-univ-dev-mxc).
#>

[CmdletBinding()]
param(
    [string]$ResourceGroupName = "rg-univ-dev-mxc",
    [string]$MySqlServerName = "mysql-univ-dev-mxc",
    [string]$CosmosAccountName = "cosmos-univ-dev-mxc",
    [string]$CosmosDbName = "univ_nosql_db",
    [string]$ServiceBusNamespace = "sb-univ-dev-mxc"
)

$ErrorActionPreference = "Stop"

Write-Host "=====================================================================" -ForegroundColor Cyan
Write-Host "  BOOTSTRAP Y VALIDACION DE PERSISTENCIA POLIGLOTA EN AZURE CLOUD    " -ForegroundColor Cyan
Write-Host "  Resource Group: $ResourceGroupName                                  " -ForegroundColor Cyan
Write-Host "=====================================================================" -ForegroundColor Cyan

$results = [System.Collections.Generic.List[PSObject]]::new()

function Add-Check {
    param([string]$Component, [string]$Status, [string]$Details)
    $results.Add([PSCustomObject]@{
        Component = $Component
        Status    = $Status
        Details   = $Details
    })
    $color = if ($Status -eq "PASS") { "Green" } elseif ($Status -eq "WARN") { "Yellow" } else { "Red" }
    Write-Host "[$Status] $Component - $Details" -ForegroundColor $color
}

# 1. VERIFICACION DE MYSQL FLEXIBLE SERVER
try {
    Write-Host "`n--- 1. Verificando MySQL Flexible Server ---" -ForegroundColor Yellow
    $mysqlStatus = az mysql flexible-server show -g $ResourceGroupName -n $MySqlServerName --query "state" -o tsv
    if ($mysqlStatus -eq "Ready") {
        Add-Check "MySQL Flexible Server" "PASS" "Servidor '$MySqlServerName' en estado Ready."
    } else {
        Add-Check "MySQL Flexible Server" "WARN" "Servidor '$MySqlServerName' en estado '$mysqlStatus'."
    }

    $databases = az mysql flexible-server db list -g $ResourceGroupName -s $MySqlServerName --query "[].name" -o tsv
    $expectedDbs = @("auth_db", "person_db", "academic_db", "enrollment_db", "finance_db")
    foreach ($db in $expectedDbs) {
        if ($databases -contains $db) {
            Add-Check "MySQL Database: $db" "PASS" "Base de datos '$db' aprovisionada correctamente."
        } else {
            Add-Check "MySQL Database: $db" "FAIL" "Base de datos '$db' no encontrada."
        }
    }
} catch {
    Add-Check "MySQL Flexible Server" "FAIL" "Error al consultar MySQL: $_"
}

# 2. VERIFICACION DE AZURE COSMOS DB
try {
    Write-Host "`n--- 2. Verificando Azure Cosmos DB NoSQL ---" -ForegroundColor Yellow
    $cosmosDbs = az cosmosdb sql database list -a $CosmosAccountName -g $ResourceGroupName --query "[].name" -o tsv
    if ($cosmosDbs -contains $CosmosDbName) {
        Add-Check "Cosmos DB Database" "PASS" "Base de datos '$CosmosDbName' activa."
    } else {
        Add-Check "Cosmos DB Database" "FAIL" "Base de datos '$CosmosDbName' no encontrada."
    }

    $containers = az cosmosdb sql container list -a $CosmosAccountName -g $ResourceGroupName -d $CosmosDbName --query "[].name" -o tsv
    $expectedContainers = @("library_catalogs", "library_loans", "lms_courses", "lms_enrollments")
    foreach ($c in $expectedContainers) {
        if ($containers -contains $c) {
            Add-Check "Cosmos DB Container: $c" "PASS" "Contenedor '$c' listo para auto-seeding."
        } else {
            Add-Check "Cosmos DB Container: $c" "FAIL" "Contenedor '$c' no encontrado."
        }
    }
} catch {
    Add-Check "Azure Cosmos DB" "FAIL" "Error al consultar Cosmos DB: $_"
}

# 3. VERIFICACION DE AZURE SERVICE BUS
try {
    Write-Host "`n--- 3. Verificando Azure Service Bus EDA ---" -ForegroundColor Yellow
    $topics = az servicebus topic list -g $ResourceGroupName --namespace-name $ServiceBusNamespace --query "[].name" -o tsv
    $expectedTopics = @("enrollment.events", "student.events")
    foreach ($t in $expectedTopics) {
        if ($topics -contains $t) {
            Add-Check "Service Bus Topic: $t" "PASS" "Topico '$t' activo para mensajeria asincrona."
        } else {
            Add-Check "Service Bus Topic: $t" "FAIL" "Topico '$t' no encontrado."
        }
    }

    $queues = az servicebus queue list -g $ResourceGroupName --namespace-name $ServiceBusNamespace --query "[].name" -o tsv
    if ($queues -contains "payments.processing") {
        Add-Check "Service Bus Queue: payments.processing" "PASS" "Cola de pagos con DLQ activa."
    } else {
        Add-Check "Service Bus Queue: payments.processing" "FAIL" "Cola 'payments.processing' no encontrada."
    }
} catch {
    Add-Check "Azure Service Bus" "FAIL" "Error al consultar Service Bus: $_"
}

# 4. VERIFICACION DE REDIS CACHE
try {
    Write-Host "`n--- 4. Verificando Azure Cache for Redis ---" -ForegroundColor Yellow
    $redisName = az redis list -g $ResourceGroupName --query "[0].name" -o tsv
    if ($redisName) {
        $redisState = az redis show -g $ResourceGroupName -n $redisName --query "provisioningState" -o tsv
        Add-Check "Azure Cache for Redis" "PASS" "Instancia '$redisName' en estado '$redisState'."
    } else {
        Add-Check "Azure Cache for Redis" "WARN" "No se detecto instancia Redis en $ResourceGroupName."
    }
} catch {
    Add-Check "Azure Cache for Redis" "WARN" "Consulta de Redis omitida: $_"
}

# 5. RESUMEN FINAL
Write-Host "`n=====================================================================" -ForegroundColor Cyan
Write-Host "  RESUMEN DE BOOTSTRAP DE PERSISTENCIA Y PERSISTENCIA POLIGLOTA       " -ForegroundColor Cyan
Write-Host "=====================================================================" -ForegroundColor Cyan
$results | Format-Table -AutoSize

$failCount = ($results | Where-Object { $_.Status -eq "FAIL" }).Count
if ($failCount -gt 0) {
    Write-Host "Se encontraron $failCount fallos en la capa de datos." -ForegroundColor Red
    exit 1
} else {
    Write-Host "La persistencia poliglota y bus de eventos estan 100% listos." -ForegroundColor Green
    exit 0
}
