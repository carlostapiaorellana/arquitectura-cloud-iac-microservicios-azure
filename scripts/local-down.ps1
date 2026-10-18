# ============================================================
# Script de apagado y limpieza del entorno local Lab 03
# Universidad UNFPG - Plataforma Cloud-Native Azure
# ============================================================
$ErrorActionPreference = "Stop"

Write-Host "Deteniendo contenedores y eliminando volumenes temporales de Lab 03..." -ForegroundColor Yellow
docker compose -f docker/docker-compose.local.yml down -v

Write-Host "[OK] Entorno local detenido y limpiado exitosamente." -ForegroundColor Green
