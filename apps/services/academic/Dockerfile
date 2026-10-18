# ============================================================
# Dockerfile: academic-service (Multi-stage build)
# Contexto de construcción: Raíz del Monorepo (context: ..)
# Universidad UNFPG - Plataforma Cloud-Native Azure (Lab 03)
# ============================================================

# Etapa 1: Compilación
FROM golang:1.22-alpine AS builder

WORKDIR /workspace

# Copiar archivos de workspace, paquetes y servicios (Invariante GO-01)
COPY go.work go.work.sum* ./
COPY packages/ ./packages/
COPY apps/ ./apps/

# Sincronizar y compilar binario estático optimizado
RUN go work sync || true
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o /workspace/academic-service ./apps/services/academic/cmd/api/main.go

# Etapa 2: Imagen mínima de ejecución
FROM alpine:3.20

RUN apk --no-cache add ca-certificates tzdata curl && \
    addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /app

COPY --from=builder /workspace/academic-service /app/academic-service
RUN chown -R appuser:appgroup /app

USER appuser

EXPOSE 8083

ENV PORT=8083

HEALTHCHECK --interval=10s --timeout=3s --start-period=5s --retries=3 \
    CMD ["/app/academic-service", "-healthcheck"]

ENTRYPOINT ["/app/academic-service"]
