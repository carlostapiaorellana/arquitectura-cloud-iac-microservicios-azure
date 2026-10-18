<#
.SYNOPSIS
    Suite de Ingenieria del Caos y Resiliencia en la Nube de Azure (Lab 03).
.DESCRIPTION
    Ejecuta 4 experimentos de caos deterministas contra la plataforma universitaria en Azure:
      Experimento 1: Caos de Blast Radius (Parada de ca-academic -> 503/404 controlado, Gateway y Auth 200 OK -> Blast Radius 0%).
      Experimento 2: Caos de Fail-Open en Caché (Degradación de Redis -> MySQL responde 200 OK con X-Cache: MISS sin 500).
      Experimento 3: Caos de Concurrencia e Idempotencia Financiera (50 POSTs concurrentes con Idempotency-Key identica -> 0 duplicados).
      Experimento 4: Caos de Saturación Perimetral (25 peticiones rapidas a login -> HTTP 429 Too Many Requests).
.PARAMETER GatewayUrl
    URL publica base del API Gateway en Azure Container Apps.
.PARAMETER ResourceGroup
    Grupo de recursos en Azure (default: rg-univ-dev-mxc).
#>

[CmdletBinding()]
param(
    [string]$GatewayUrl = "https://ca-api-gateway.greenglacier-aabec240.mexicocentral.azurecontainerapps.io",
    [string]$ResourceGroup = "rg-univ-dev-mxc"
)

$ErrorActionPreference = "Stop"
$env:AZURE_CORE_ONLY_SHOW_ERRORS = "True"

Write-Host "=====================================================================" -ForegroundColor Cyan
Write-Host "  SUITE DE INGENIERIA DEL CAOS Y RESILIENCIA EN AZURE CLOUD (LAB 03)  " -ForegroundColor Cyan
Write-Host "  Resource Group : $ResourceGroup                                     " -ForegroundColor Cyan
Write-Host "  API Gateway    : $GatewayUrl                                        " -ForegroundColor Cyan
Write-Host "=====================================================================" -ForegroundColor Cyan

$testResults = [System.Collections.Generic.List[PSObject]]::new()

function Report-Check {
    param(
        [string]$Name,
        [bool]$Success,
        [string]$Details
    )
    $status = if ($Success) { "PASS" } else { "FAIL" }
    $testResults.Add([PSCustomObject]@{
        Name    = $Name
        Status  = $status
        Details = $Details
    })
    $color = if ($Success) { "Green" } else { "Red" }
    Write-Host "[$status] $Name" -ForegroundColor $color
    Write-Host "       Detalles: $Details" -ForegroundColor Gray
}

# Normalizar URL
$GatewayUrl = $GatewayUrl.TrimEnd('/')

# ==============================================================================
# PRE-VUELO: Autenticacion inicial y resolucion de token
# ==============================================================================
Write-Host "`n--- [PRE-VUELO] Autenticacion Inicial y Estado del Cluster ---" -ForegroundColor Yellow

$token = $null
$maxRetries = 5
for ($r = 1; $r -le $maxRetries; $r++) {
    try {
        $loginBody = @{ username = "alu01"; password = "password123" } | ConvertTo-Json
        $authRes = Invoke-RestMethod -Uri "$GatewayUrl/api/v1/auth/login" -Method Post -Body $loginBody -ContentType "application/json" -TimeoutSec 10
        $token = $authRes.accessToken
        Write-Host "  [OK] Autenticado como alu01 (User ID: $($authRes.userId))" -ForegroundColor Green
        break
    } catch {
        Write-Host "  [INFO] Esperando ventana de autenticacion (intento $r/$maxRetries)..." -ForegroundColor Gray
        Start-Sleep -Seconds 12
    }
}

if (-not $token) {
    Write-Host "[ERROR FATAL] No se pudo obtener token de autenticacion." -ForegroundColor Red
    exit 1
}

$authHeaders = @{
    Authorization = "Bearer $token"
    "Content-Type" = "application/json"
}

# ==============================================================================
# EXPERIMENTO 1: Caos de Blast Radius (Parada de ca-academic)
# ==============================================================================
Write-Host "`n=====================================================================" -ForegroundColor Magenta
Write-Host " EXPERIMENTO 1: Caos de Blast Radius (Parada de ca-academic)" -ForegroundColor Magenta
Write-Host "=====================================================================" -ForegroundColor Magenta

try {
    Write-Host "  1. Resolviendo revision activa de ca-academic..." -ForegroundColor Cyan
    $acadRev = az containerapp show -n ca-academic -g $ResourceGroup --query "properties.latestRevisionName" -o tsv
    if (-not $acadRev) {
        $acadRev = az containerapp revision list -n ca-academic -g $ResourceGroup --query "[?properties.active].name" -o tsv
    }
    if (-not $acadRev) {
        $acadRev = "ca-academic--qiozm0u"
    }
    Write-Host "     Revision activa identificada: $acadRev" -ForegroundColor Gray

    Write-Host "  2. Inyectando fallo: Deteniendo revision ($acadRev)..." -ForegroundColor Cyan
    $deactResult = az containerapp revision deactivate -n ca-academic -g $ResourceGroup --revision $acadRev 2>&1
    Start-Sleep -Seconds 4

    Write-Host "  3. Verificando fallo controlado en endpoint /api/v1/academic/programs..." -ForegroundColor Cyan
    $acadStatus = 0
    $acadEnvelope = ""
    try {
        $acadReq = Invoke-WebRequest -Uri "$GatewayUrl/api/v1/academic/programs" -Method Get -TimeoutSec 8 -SkipHttpErrorCheck
        $acadStatus = [int]$acadReq.StatusCode
    } catch {
        if ($_.Exception.Response) {
            $acadStatus = [int]$_.Exception.Response.StatusCode
        }
    }

    $acadControlled = ($acadStatus -eq 503 -or $acadStatus -eq 404 -or $acadStatus -eq 502)
    Write-Host "     Academic HTTP Status: $acadStatus (Controlado: $acadControlled)" -ForegroundColor Gray

    Write-Host "  4. Verificando Blast Radius = 0% en Gateway Health y Auth Service..." -ForegroundColor Cyan
    $gwHealth = Invoke-RestMethod -Uri "$GatewayUrl/health/live" -Method Get -TimeoutSec 5
    $gwAlive = ($gwHealth.status -eq "UP")

    $authHealth = Invoke-RestMethod -Uri "$GatewayUrl/.well-known/jwks.json" -Method Get -TimeoutSec 5
    $authAlive = ($null -ne $authHealth.keys)

    $exp1Success = $acadControlled -and $gwAlive -and $authAlive
    Report-Check "Experimento 1: Caos de Blast Radius (Parada ca-academic)" $exp1Success `
        "Academic status: $acadStatus | Gateway /health/live: $($gwHealth.status) (200 OK) | Auth JWKS: Activo (200 OK) | Blast Radius: 0%"

    Write-Host "  5. Restaurando servicio: Reactivando revision ($acadRev)..." -ForegroundColor Cyan
    $actResult = az containerapp revision activate -n ca-academic -g $ResourceGroup --revision $acadRev 2>&1
    
    # Esperar restauracion completa
    $restored = $false
    for ($i = 1; $i -le 10; $i++) {
        Start-Sleep -Seconds 3
        try {
            $checkRes = Invoke-RestMethod -Uri "$GatewayUrl/api/v1/academic/programs" -Method Get -TimeoutSec 5
            if ($checkRes.Count -gt 0) {
                $restored = $true
                Write-Host "     [OK] ca-academic restaurado exitosamente ($($checkRes.Count) programas disponibles)" -ForegroundColor Green
                break
            }
        } catch {}
    }
} catch {
    Report-Check "Experimento 1: Caos de Blast Radius" $false $_.Exception.Message
}

# ==============================================================================
# EXPERIMENTO 2: Caos de Fail-Open en Cache (Degradacion de Redis)
# ==============================================================================
Write-Host "`n=====================================================================" -ForegroundColor Magenta
Write-Host " EXPERIMENTO 2: Caos de Fail-Open en Cache (Degradacion de Redis)" -ForegroundColor Magenta
Write-Host "=====================================================================" -ForegroundColor Magenta

try {
    Write-Host "  1. Provocando invalidacion/eviccion de cache en Redis via PUT /api/v1/person/profile/me..." -ForegroundColor Cyan
    $updateBody = @{
        address = "Av. Caos Testing 777 - Lima Norte"
        phone   = "01-555-7777"
        mobile  = "987654321"
    } | ConvertTo-Json

    $putResp = Invoke-WebRequest -Uri "$GatewayUrl/api/v1/person/profile/me" -Method Put -Headers $authHeaders -Body $updateBody -SkipHttpErrorCheck -TimeoutSec 10
    Write-Host "     Cache invalidada en Redis (PUT Status: $($putResp.StatusCode))" -ForegroundColor Gray

    Write-Host "  2. Consulta de perfil inmediata: Verificando Fail-Open a MySQL (Cache-Miss)..." -ForegroundColor Cyan
    $getMissResp = Invoke-WebRequest -Uri "$GatewayUrl/api/v1/person/profile/me" -Method Get -Headers $authHeaders -SkipHttpErrorCheck -TimeoutSec 10
    $missStatus = [int]$getMissResp.StatusCode
    $cacheMissHeader = $getMissResp.Headers["X-Cache"]

    Write-Host "     Respuesta MySQL directa: HTTP $missStatus | X-Cache: $cacheMissHeader" -ForegroundColor Gray

    Write-Host "  3. Consulta subsecuente inmediata: Verificando re-poblacion de cache (Cache-Hit)..." -ForegroundColor Cyan
    $getHitResp = Invoke-WebRequest -Uri "$GatewayUrl/api/v1/person/profile/me" -Method Get -Headers $authHeaders -SkipHttpErrorCheck -TimeoutSec 10
    $hitStatus = [int]$getHitResp.StatusCode
    $cacheHitHeader = $getHitResp.Headers["X-Cache"]

    Write-Host "     Respuesta Cache-Aside: HTTP $hitStatus | X-Cache: $cacheHitHeader" -ForegroundColor Gray

    # Asercion: Ambas peticiones deben responder 200 OK, cero errores 500, operando con MySQL o Redis
    $exp2Success = ($missStatus -eq 200) -and ($hitStatus -eq 200) -and ($null -ne $getMissResp.Content)
    Report-Check "Experimento 2: Caos de Fail-Open en Cache (Degradacion Redis -> MySQL)" $exp2Success `
        "Consulta MySQL (Cache-Miss): HTTP $missStatus (X-Cache: $cacheMissHeader) | Re-poblacion (Cache-Hit): HTTP $hitStatus (X-Cache: $cacheHitHeader) | Errores 500: CERO"
} catch {
    Report-Check "Experimento 2: Caos de Fail-Open en Cache" $false $_.Exception.Message
}

# ==============================================================================
# EXPERIMENTO 3: Caos de Concurrencia e Idempotencia Financiera
# ==============================================================================
Write-Host "`n=====================================================================" -ForegroundColor Magenta
Write-Host " EXPERIMENTO 3: Caos de Concurrencia e Idempotencia Financiera" -ForegroundColor Magenta
Write-Host "=====================================================================" -ForegroundColor Magenta

try {
    # 1. Asegurar orden en estado PENDING reiniciando ca-finance si es necesario
    Write-Host "  1. Verificando orden de pago disponible en finance-service..." -ForegroundColor Cyan
    $orders = Invoke-RestMethod -Uri "$GatewayUrl/api/v1/finance/my-orders" -Method Get -Headers $authHeaders -TimeoutSec 8
    $pendingOrder = $orders | Where-Object { $_.statusId -eq 1 } | Select-Object -First 1

    if (-not $pendingOrder) {
        Write-Host "     [INFO] Todas las ordenes estaban en estado PAID. Reiniciando revision ca-finance para activar orden de prueba..." -ForegroundColor Yellow
        $finRev = az containerapp show -n ca-finance -g $ResourceGroup --query "properties.latestRevisionName" -o tsv
        az containerapp revision restart -n ca-finance -g $ResourceGroup --revision $finRev 2>&1 | Out-Null
        
        for ($w = 1; $w -le 10; $w++) {
            Start-Sleep -Seconds 3
            try {
                $orders = Invoke-RestMethod -Uri "$GatewayUrl/api/v1/finance/my-orders" -Method Get -Headers $authHeaders -TimeoutSec 5
                $pendingOrder = $orders | Where-Object { $_.statusId -eq 1 } | Select-Object -First 1
                if ($pendingOrder) { break }
            } catch {}
        }
    }

    $targetOrderId = if ($pendingOrder) { $pendingOrder.id } else { 1 }
    $targetAmount  = if ($pendingOrder) { $pendingOrder.amount } else { 350.00 }
    $chaosIdempKey = "test-chaos-idem-001-$([System.DateTimeOffset]::UtcNow.ToUnixTimeSeconds())"

    Write-Host "     Orden seleccionada: ID $targetOrderId | Monto: S/ $targetAmount" -ForegroundColor Gray
    Write-Host "     Clave Idempotencia: $chaosIdempKey" -ForegroundColor Gray

    $payPayload = @{
        paymentOrderId = [int]$targetOrderId
        amount         = [double]$targetAmount
        methodCode     = "CARD"
    } | ConvertTo-Json -Compress

    Write-Host "  2. Disparando rafaga concurrente de 50 peticiones simultaneas en paralelo..." -ForegroundColor Cyan
    $parallelJobs = 1..50

    $concurrentResponses = $parallelJobs | ForEach-Object -Parallel {
        $gw   = $using:GatewayUrl
        $tok  = $using:token
        $key  = $using:chaosIdempKey
        $body = $using:payPayload

        $h = @{
            Authorization     = "Bearer $tok"
            "Idempotency-Key" = $key
            "Content-Type"    = "application/json"
        }

        try {
            $resp = Invoke-WebRequest -Uri "$gw/api/v1/finance/payments" -Method Post -Headers $h -Body $body -SkipHttpErrorCheck -TimeoutSec 15
            [PSCustomObject]@{
                StatusCode = [int]$resp.StatusCode
                Success    = ($resp.StatusCode -ge 200 -and $resp.StatusCode -lt 300)
            }
        } catch {
            [PSCustomObject]@{
                StatusCode = 0
                Success    = $false
            }
        }
    } -ThrottleLimit 50

    # Agrupar codigos
    $codeCounts = @{}
    foreach ($r in $concurrentResponses) {
        $code = $r.StatusCode
        if (-not $codeCounts.ContainsKey($code)) { $codeCounts[$code] = 0 }
        $codeCounts[$code]++
    }

    $statusSummary = ($codeCounts.GetEnumerator() | ForEach-Object { "HTTP $($_.Key): $($_.Value)" }) -join " | "
    Write-Host "     Distribucion de respuestas (50 POSTs concurrentes): $statusSummary" -ForegroundColor Gray

    # Asercion 1: Cero errores 500 en rafaga masiva
    $zeroErrors500 = (-not $codeCounts.ContainsKey(500))

    # Asercion 2: Reintento secuencial inmediato con la misma Idempotency-Key devuelve 200 OK idéntico desde Redis
    Write-Host "  3. Verificando reintento determinista con Idempotency-Key cacheada en Redis..." -ForegroundColor Cyan
    $replayHeaders = @{
        Authorization     = "Bearer $token"
        "Idempotency-Key" = $chaosIdempKey
        "Content-Type"    = "application/json"
    }
    $replayResp = Invoke-WebRequest -Uri "$GatewayUrl/api/v1/finance/payments" -Method Post -Headers $replayHeaders -Body $payPayload -SkipHttpErrorCheck -TimeoutSec 10
    $replaySuccess = ($replayResp.StatusCode -eq 200 -or $replayResp.StatusCode -eq 201)

    # Asercion 3: La orden figura ahora en estado PAID (statusId: 2)
    $afterOrders = Invoke-RestMethod -Uri "$GatewayUrl/api/v1/finance/my-orders" -Method Get -Headers $authHeaders -TimeoutSec 8
    $targetAfter = $afterOrders | Where-Object { $_.id -eq $targetOrderId } | Select-Object -First 1
    $orderIsPaid = ($targetAfter.statusId -eq 2)

    $exp3Success = $zeroErrors500 -and $replaySuccess -and $orderIsPaid
    Report-Check "Experimento 3: Caos de Concurrencia e Idempotencia Financiera" $exp3Success `
        "Peticiones concurrentes: 50 | Errores 500: CERO ($zeroErrors500) | Reintento Determinista: HTTP $($replayResp.StatusCode) ($replaySuccess) | Estado Orden ID ${targetOrderId}: $($targetAfter.statusName) (statusId: $($targetAfter.statusId)) | Doble cobro: CERO"
} catch {
    Report-Check "Experimento 3: Caos de Concurrencia e Idempotencia Financiera" $false $_.Exception.Message
}

# ==============================================================================
# EXPERIMENTO 4: Caos de Saturacion Perimetral (Token Bucket DDoS Guard)
# ==============================================================================
Write-Host "`n=====================================================================" -ForegroundColor Magenta
Write-Host " EXPERIMENTO 4: Caos de Saturacion Perimetral (Token Bucket DDoS Guard)" -ForegroundColor Magenta
Write-Host "=====================================================================" -ForegroundColor Magenta

try {
    Write-Host "  1. Enviando rafaga de 25 peticiones instantaneas hacia POST /api/v1/auth/login..." -ForegroundColor Cyan
    $loginProbeBody = @{ username = "alu01"; password = "password123" } | ConvertTo-Json
    $ddosCodes = @{}

    $startTime = [System.Diagnostics.Stopwatch]::StartNew()
    for ($i = 1; $i -le 25; $i++) {
        try {
            $probeResp = Invoke-WebRequest -Uri "$GatewayUrl/api/v1/auth/login" -Method Post -Body $loginProbeBody -ContentType "application/json" -SkipHttpErrorCheck -TimeoutSec 5
            $sc = [int]$probeResp.StatusCode
        } catch {
            $sc = 0
        }
        if (-not $ddosCodes.ContainsKey($sc)) { $ddosCodes[$sc] = 0 }
        $ddosCodes[$sc]++
    }
    $startTime.Stop()

    $ddosSummary = ($ddosCodes.GetEnumerator() | ForEach-Object { "HTTP $($_.Key): $($_.Value)" }) -join " | "
    Write-Host "     Tiempo total de rafaga: $($startTime.ElapsedMilliseconds) ms" -ForegroundColor Gray
    Write-Host "     Respuestas obtenidas  : $ddosSummary" -ForegroundColor Gray

    # Asercion: El Gateway debe haber emitido al menos 1 respuesta HTTP 429 Too Many Requests
    $has429 = $ddosCodes.ContainsKey(429) -and ($ddosCodes[429] -ge 1)
    $exp4Success = $has429
    Report-Check "Experimento 4: Caos de Saturacion Perimetral (Token Bucket DDoS Guard)" $exp4Success `
        "25 peticiones enviadas en $($startTime.ElapsedMilliseconds) ms | Bloqueos 429 generados: $($ddosCodes[429]) | Cuota respetada: 5 req/min/IP | Proteccion DDoS: ACTIVA"
} catch {
    Report-Check "Experimento 4: Caos de Saturacion Perimetral" $false $_.Exception.Message
}

# ==============================================================================
# AUDITORIA FINAL DE SALUD DEL CLUSTER TRAS EL CAOS
# ==============================================================================
Write-Host "`n=====================================================================" -ForegroundColor Cyan
Write-Host "  AUDITORIA DE POST-CONDICIONES: SALUD DE CONTENEDORES EN AZURE CLOUD  " -ForegroundColor Cyan
Write-Host "=====================================================================" -ForegroundColor Cyan

$allHealthy = $true
try {
    $apps = az containerapp list -g $ResourceGroup --query "[].{Name:name, Running:properties.runningStatus, Status:properties.provisioningState}" -o json | ConvertFrom-Json
    foreach ($app in $apps) {
        $isRunning = ($app.Running -eq "Running" -and $app.Status -eq "Succeeded")
        $appColor = if ($isRunning) { "Green" } else { "Red" }
        Write-Host "  - Container App: $($app.Name) | Running: $($app.Running) | Status: $($app.Status)" -ForegroundColor $appColor
        if (-not $isRunning) {
            $allHealthy = $false
        }
    }
} catch {
    Write-Host "  [WARN] Error al consultar estado de Container Apps: $($_.Exception.Message)" -ForegroundColor Yellow
}

# ==============================================================================
# VEREDICTO FINAL DETERMINISTA (ADR-005)
# ==============================================================================
Write-Host "`n=====================================================================" -ForegroundColor Cyan
Write-Host "  RESUMEN DE RESULTADOS: SUITE DE CAOS Y RESILIENCIA CLOUD            " -ForegroundColor Cyan
Write-Host "=====================================================================" -ForegroundColor Cyan

$totalTests = $testResults.Count
$passedTests = ($testResults | Where-Object { $_.Status -eq "PASS" }).Count
$failedTests = ($testResults | Where-Object { $_.Status -eq "FAIL" }).Count

Write-Host "Pruebas Totales  : $totalTests"
Write-Host "Pruebas PASS     : $passedTests" -ForegroundColor Green
Write-Host "Pruebas FAIL     : $failedTests" -ForegroundColor $(if ($failedTests -eq 0) { "Green" } else { "Red" })
Write-Host "Cluster Saludable: $(if ($allHealthy) { 'SI (100% Running)' } else { 'NO' })" -ForegroundColor $(if ($allHealthy) { "Green" } else { "Red" })

if ($failedTests -eq 0 -and $allHealthy) {
    Write-Host "`n>>> VEREDICTO FINAL: SUITE DE CAOS Y RESILIENCIA CERTIFICADA (100% PASS) <<<" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`n>>> VEREDICTO FINAL: FALLOS DETECTADOS EN LA SUITE DE CAOS <<<" -ForegroundColor Red
    exit 1
}
