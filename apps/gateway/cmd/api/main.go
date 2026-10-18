package main

import (
	"context"
	"errors"
	"flag"
	"fmt"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/universidad/platform/packages/observability"
	"github.com/universidad/platform/apps/gateway/internal/config"
	"github.com/universidad/platform/apps/gateway/internal/middleware"
	"github.com/universidad/platform/apps/gateway/internal/proxy"
	"github.com/universidad/platform/apps/gateway/internal/services"
)

func main() {
	healthCheckFlag := flag.Bool("healthcheck", false, "Ejecuta healthcheck HTTP local")
	flag.Parse()

	cfg := config.LoadConfig()

	// Si se invocó con -healthcheck (modo contenedor Docker)
	if *healthCheckFlag {
		client := &http.Client{Timeout: 3 * time.Second}
		resp, err := client.Get(fmt.Sprintf("http://127.0.0.1:%s/health/live", cfg.Port))
		if err != nil || resp.StatusCode != http.StatusOK {
			os.Exit(1)
		}
		os.Exit(0)
	}

	logger := observability.InitLogger("api-gateway", cfg.Env)
	logger.Info("Iniciando api-gateway perimetral...", "port", cfg.Port, "env", cfg.Env)

	// 1. Inicializar cliente JWKS
	jwksClient := services.NewJWKSClient(cfg.JWKSURL)

	// 2. Inicializar Reverse Proxy Router
	gatewayProxy, err := proxy.NewGatewayProxy(
		cfg.AuthServiceURL,
		cfg.PersonServiceURL,
		cfg.AcademicServiceURL,
		cfg.EnrollmentServiceURL,
		cfg.FinanceServiceURL,
		cfg.LibraryServiceURL,
		cfg.LmsServiceURL,
		jwksClient,
		cfg.AllowedOrigins,
		logger,
	)
	if err != nil {
		logger.Error("Fallo crítico al inicializar API Gateway", "error", err)
		os.Exit(1)
	}

	// 3. Middlewares y Rate Limiting (REV-E2E-01)
	rateLimiter := middleware.NewRateLimiter(5, 1*time.Minute)

	handler := observability.CorrelationMiddleware(
		observability.RequestLoggerMiddleware(logger)(
			middleware.RateLimitMiddleware(rateLimiter)(gatewayProxy),
		),
	)

	server := &http.Server{
		Addr:         fmt.Sprintf(":%s", cfg.Port),
		Handler:      handler,
		ReadTimeout:  15 * time.Second,
		WriteTimeout: 15 * time.Second,
		IdleTimeout:  60 * time.Second,
	}

	stopChan := make(chan os.Signal, 1)
	signal.Notify(stopChan, os.Interrupt, syscall.SIGTERM)

	go func() {
		logger.Info("api-gateway escuchando peticiones", "addr", server.Addr)
		if err := server.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
			logger.Error("Error en servidor api-gateway", "error", err)
			os.Exit(1)
		}
	}()

	<-stopChan
	logger.Info("Recibida señal de terminación, ejecutando shutdown graceful de api-gateway...")

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	if err := server.Shutdown(ctx); err != nil {
		logger.Error("Error durante shutdown graceful de api-gateway", "error", err)
	}
	logger.Info("api-gateway finalizado correctamente")
}
