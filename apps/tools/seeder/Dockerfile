# ============================================================
# Dockerfile: dataset-v2-seeder (Multi-stage build)
# Inyector determinista de semillas en Azure MySQL Flexible Server
# Universidad UNFPG - Plataforma Cloud-Native Azure (Lab 03)
# ============================================================

FROM golang:1.22-alpine AS builder

WORKDIR /workspace

# Copiar archivos de go workspace y módulos
COPY go.work go.work.sum* ./
COPY packages/ ./packages/
COPY apps/ ./apps/

# Compilar binario estático optimizado
RUN go work sync || true
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -ldflags="-s -w" -o /workspace/seeder ./apps/tools/seeder/main.go

FROM alpine:3.20

RUN apk --no-cache add ca-certificates tzdata

WORKDIR /app

COPY --from=builder /workspace/seeder /app/seeder

ENTRYPOINT ["/app/seeder"]
