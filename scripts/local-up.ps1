# ============================================================
# Script de arranque del entorno local Lab 03 (Azure Architecture Local)
# Universidad UNFPG - Plataforma Cloud-Native Azure
# Sub-Fase E (Fase 3 Frontend): 12 Contenedores (7 Backend + 1 Gateway + 1 Web + 3 Datos)
# ============================================================
$ErrorActionPreference = "Stop"

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "Iniciando Plataforma Universitaria Cloud-Native (Lab 03)" -ForegroundColor Cyan
Write-Host "Sub-Fase E: 12 Contenedores (Microservicios, Gateway, Web SPA Nginx)" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

# 1. Levantar MySQL, Redis y DynamoDB Local en modo detached (-d)
Write-Host "`n[Paso 1/5] Levantando contenedores base (MySQL, Redis, DynamoDB Local)..." -ForegroundColor Yellow
docker compose -f docker/docker-compose.local.yml up -d mysql redis dynamodb-local
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Error al iniciar contenedores base (mysql, redis, dynamodb-local)." -ForegroundColor Red
    exit 1
}

# Esperar a que MySQL alcance estado 'healthy' (timeout estricto: 30 segundos)
Write-Host "Esperando validacion de socket TCP en MySQL (puerto 3307 host / 3306 interno, max 30s)..." -ForegroundColor Yellow
$healthy = $false
for ($i = 1; $i -le 15; $i++) {
    try {
        $rawInspect = docker inspect univ-local-mysql 2>&1
        if ($LASTEXITCODE -eq 0 -and $rawInspect) {
            $parsed = $rawInspect | ConvertFrom-Json
            $status = $parsed[0].State.Health.Status
            $running = $parsed[0].State.Running

            if ($status -eq "healthy") {
                $healthy = $true
                Write-Host "  [OK] MySQL reporta estado 'healthy' y esta listo para recibir conexiones TCP." -ForegroundColor Green
                break
            }

            if (-not $running) {
                Write-Host "  [ERROR] El contenedor univ-local-mysql se detuvo inesperadamente." -ForegroundColor Red
                docker logs --tail 25 univ-local-mysql
                exit 1
            }

            Write-Host "  Verificando MySQL: estado '$status' (intento $i/15)..." -ForegroundColor Gray
        } else {
            Write-Host "  Contenedor aun no disponible (intento $i/15)..." -ForegroundColor Gray
        }
    } catch {
        Write-Host "  Esperando inicio del contenedor (intento $i/15)..." -ForegroundColor Gray
    }
    Start-Sleep -Seconds 2
}

if (-not $healthy) {
    Write-Host "[ERROR] MySQL no alcanzo estado 'healthy' en el tiempo limite de 30 segundos." -ForegroundColor Red
    docker compose -f docker/docker-compose.local.yml ps
    exit 1
}

# 2. Inicializacion Idempotente de Bootstrap (Invariante DB-04)
Write-Host "`n[Paso 2/5] Sincronizando catalogo de bases de datos y usuarios segregados..." -ForegroundColor Yellow
try {
    Get-Content -Raw "database/mysql/bootstrap/01-init-databases-and-users.sql" | docker exec -i univ-local-mysql mysql -u root -proot_dev_password_123
    Write-Host "  [OK] Bootstrap aplicado exitosamente (auth_db, person_db, academic_db, enrollment_db, finance_db)." -ForegroundColor Green
} catch {
    Write-Host "  [ERROR] Error al aplicar bootstrap inicial: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# 3. Ejecutar migraciones DDL y Seeds con timeouts acotados
Write-Host "`n[Paso 3/5] Ejecutando migraciones DDL y seeds para los 5 dominios relacionales..." -ForegroundColor Yellow

Write-Host "  -> Aplicando migraciones y seeds en auth_db..." -ForegroundColor Gray
docker compose -f docker/docker-compose.local.yml --profile migrate run --rm migrate-auth-db
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Fallo la migracion de auth_db." -ForegroundColor Red
    exit 1
}

Write-Host "  -> Aplicando migraciones y seeds en person_db..." -ForegroundColor Gray
docker compose -f docker/docker-compose.local.yml --profile migrate run --rm migrate-person-db
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Fallo la migracion de person_db." -ForegroundColor Red
    exit 1
}

Write-Host "  -> Aplicando migraciones y seeds en academic_db..." -ForegroundColor Gray
docker compose -f docker/docker-compose.local.yml --profile migrate run --rm migrate-academic-db
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Fallo la migracion de academic_db." -ForegroundColor Red
    exit 1
}

Write-Host "  -> Aplicando migraciones y seeds en enrollment_db..." -ForegroundColor Gray
docker compose -f docker/docker-compose.local.yml --profile migrate run --rm migrate-enrollment-db
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Fallo la migracion de enrollment_db." -ForegroundColor Red
    exit 1
}

Write-Host "  -> Aplicando migraciones y seeds en finance_db..." -ForegroundColor Gray
docker compose -f docker/docker-compose.local.yml --profile migrate run --rm migrate-finance-db
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Fallo la migracion de finance_db." -ForegroundColor Red
    exit 1
}

# 4. Levantar microservicios y Gateway en segundo plano (-d) con compilacion
Write-Host "`n[Paso 4/5] Compilando e iniciando los 7 microservicios y api-gateway (-d)..." -ForegroundColor Yellow
docker compose -f docker/docker-compose.local.yml up -d --build auth-service person-service academic-service enrollment-service finance-service library-service lms-service gateway
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Fallo la compilacion o despliegue de los microservicios." -ForegroundColor Red
    exit 1
}

# Esperar estabilizacion de salud de los microservicios (maximo 30 segundos)
Write-Host "Esperando estabilizacion de salud de los microservicios (max 30s)..." -ForegroundColor Yellow
$servicesHealthy = $false
for ($i = 1; $i -le 15; $i++) {
    $gwInspect = docker inspect univ-api-gateway 2>&1
    if ($LASTEXITCODE -eq 0 -and $gwInspect) {
        $parsedGw = $gwInspect | ConvertFrom-Json
        if ($parsedGw[0].State.Health.Status -eq "healthy") {
            $servicesHealthy = $true
            Write-Host "  [OK] API Gateway reporta estado 'healthy'." -ForegroundColor Green
            break
        }
    }
    Write-Host "  Verificando estabilizacion de gateway (intento $i/15)..." -ForegroundColor Gray
    Start-Sleep -Seconds 2
}

# 5. Compilar y levantar Portal Web Estudiantil (web)
Write-Host "`n[Paso 5/5] Compilando e iniciando Portal Web Estudiantil Nginx (web)..." -ForegroundColor Yellow
docker compose -f docker/docker-compose.local.yml up -d --build web
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Fallo la compilacion o despliegue del portal web." -ForegroundColor Red
    exit 1
}

# Esperar estabilizacion de salud del portal web (maximo 30 segundos, DC-05 y PS-01)
Write-Host "Esperando validacion de salud de univ-web-portal (max 30s)..." -ForegroundColor Yellow
$webHealthy = $false
for ($i = 1; $i -le 15; $i++) {
    $webInspect = docker inspect univ-web-portal 2>&1
    if ($LASTEXITCODE -eq 0 -and $webInspect) {
        try {
            $parsedWeb = $webInspect | ConvertFrom-Json
            if ($parsedWeb[0].State.Health.Status -eq "healthy") {
                $webHealthy = $true
                Write-Host "  [OK] Portal web univ-web-portal reporta estado 'healthy'." -ForegroundColor Green
                break
            }
        } catch {
            # Continuar esperando
        }
    }
    Write-Host "  Verificando estabilizacion del portal web (intento $i/15)..." -ForegroundColor Gray
    Start-Sleep -Seconds 2
}

if (-not $webHealthy) {
    Write-Host "[WARNING] Portal web no reporto estado 'healthy' en 30s, pero continua el arranque." -ForegroundColor Yellow
}

Write-Host "`n============================================================" -ForegroundColor Green
Write-Host "Lab 03 (Sub-Fase E) iniciado exitosamente en entorno local" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host "Persistencia local disponible:" -ForegroundColor White
Write-Host "  MySQL 8.4:      127.0.0.1:3307 (red interna: mysql:3306)" -ForegroundColor Gray
Write-Host "  Redis 7:        127.0.0.1:6380 (red interna: redis:6379)" -ForegroundColor Gray
Write-Host "  DynamoDB Local: 127.0.0.1:8000 (red interna: dynamodb-local:8000)" -ForegroundColor Gray
Write-Host "API Gateway Perimetral Norte-Sur:" -ForegroundColor White
Write-Host "  URL Base:       http://localhost:8080" -ForegroundColor Cyan
Write-Host "Portal Web Estudiantil:" -ForegroundColor White
Write-Host "  Portal Web Estudiantil: http://localhost:3000 (red publica: 127.0.0.1:3000)" -ForegroundColor Cyan
Write-Host "Endpoints de Verificacion:" -ForegroundColor White
Write-Host "  Salud Gateway:      GET  http://localhost:8080/health/live" -ForegroundColor Gray
Write-Host "  Salud Portal Web:   GET  http://localhost:3000/healthz" -ForegroundColor Gray
Write-Host "  JWKS Publico:       GET  http://localhost:8080/.well-known/jwks.json" -ForegroundColor Gray
Write-Host "  Login Auth:         POST http://localhost:8080/api/v1/auth/login" -ForegroundColor Gray
Write-Host "  Perfil Alumno:      GET  http://localhost:8080/api/v1/person/profile/me (Bearer Token)" -ForegroundColor Gray
Write-Host "  Cursos Academicos:  GET  http://localhost:8080/api/v1/academic/courses" -ForegroundColor Gray
Write-Host "  Matriculas Alumno:  GET  http://localhost:8080/api/v1/enrollment/my-enrollments (Bearer Token)" -ForegroundColor Gray
Write-Host "  Notas Alumno:       GET  http://localhost:8080/api/v1/enrollment/grades (Bearer Token)" -ForegroundColor Gray
Write-Host "  Ordenes de Pago:    GET  http://localhost:8080/api/v1/finance/my-orders (Bearer Token)" -ForegroundColor Gray
Write-Host "  Procesar Pago:      POST http://localhost:8080/api/v1/finance/payments (Bearer Token + Idempotency-Key)" -ForegroundColor Gray
Write-Host "  Catalogo Libros:    GET  http://localhost:8080/api/v1/library/books" -ForegroundColor Gray
Write-Host "  Prestamos Alumno:   GET  http://localhost:8080/api/v1/library/my-loans (Bearer Token)" -ForegroundColor Gray
Write-Host "  Cursos LMS Alumno:  GET  http://localhost:8080/api/v1/lms/my-courses (Bearer Token)" -ForegroundColor Gray
Write-Host "============================================================" -ForegroundColor Green
