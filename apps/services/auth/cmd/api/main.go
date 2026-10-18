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

	"github.com/universidad/platform/packages/messaging"
	"github.com/universidad/platform/packages/mysql"
	"github.com/universidad/platform/packages/observability"
	"github.com/universidad/platform/apps/services/auth/internal/config"
	"github.com/universidad/platform/apps/services/auth/internal/handlers"
	"github.com/universidad/platform/apps/services/auth/internal/repository"
	"github.com/universidad/platform/apps/services/auth/internal/services"
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

	logger := observability.InitLogger("auth-service", cfg.Env)
	logger.Info("Iniciando auth-service...", "port", cfg.Port, "env", cfg.Env)

	// 1. Inicializar conexión a MySQL
	db, err := mysql.NewClient(mysql.Config{
		Host:     cfg.MySQLHost,
		Port:     cfg.MySQLPort,
		User:     cfg.MySQLUser,
		Password: cfg.MySQLPassword,
		Database: cfg.MySQLDatabase,
	})
	if err != nil {
		logger.Error("Fallo crítico al inicializar pool MySQL", "error", err)
		os.Exit(1)
	}
	defer db.Close()

	// 2. Inicializar Event Bus (Redis Streams / Azure Service Bus)
	msgBus, err := messaging.NewMessageBus(messaging.Config{
		Type:           cfg.EventBusType,
		RedisAddr:      cfg.RedisAddr,
		RedisPassword:  cfg.RedisPassword,
		ServiceBusFQDN: cfg.ServiceBusFQDN,
	})
	if err != nil {
		logger.Warn("Event Bus no disponible, operando en modo degradado sin eventos", "error", err)
	} else {
		defer msgBus.Close()
		logger.Info("Event Bus inicializado exitosamente", "type", cfg.EventBusType)
	}

	// 3. Inicializar Servicios y Repositorios
	repo := repository.NewMySQLRepository(db)
	jwtSvc, err := services.NewJWTService(cfg.CertsDir, cfg.TokenExpiration)
	if err != nil {
		logger.Error("Fallo crítico al inicializar JWTService", "error", err)
		os.Exit(1)
	}

	authSvc := services.NewAuthService(repo, repo, jwtSvc, msgBus, cfg.RefreshTokenExpiration)

	// 4. Registrar Handlers
	authHandler := handlers.NewAuthHandler(authSvc)
	jwksHandler := handlers.NewJWKSHandler(jwtSvc)
	healthHandler := handlers.NewHealthHandler(db)

	mux := http.NewServeMux()
	mux.HandleFunc("/.well-known/jwks.json", jwksHandler.ServeHTTP)
	mux.HandleFunc("/api/v1/auth/login", authHandler.Login)
	mux.HandleFunc("/api/v1/auth/refresh", authHandler.Refresh)
	mux.HandleFunc("/api/v1/auth/register", authHandler.Register)
	mux.HandleFunc("/health", healthHandler.Live)
	mux.HandleFunc("/health/live", healthHandler.Live)
	mux.HandleFunc("/health/ready", healthHandler.Ready)

	// Envolver con Middlewares
	handler := observability.CorrelationMiddleware(observability.RequestLoggerMiddleware(logger)(mux))

	server := &http.Server{
		Addr:         fmt.Sprintf(":%s", cfg.Port),
		Handler:      handler,
		ReadTimeout:  10 * time.Second,
		WriteTimeout: 10 * time.Second,
		IdleTimeout:  60 * time.Second,
	}

	stopChan := make(chan os.Signal, 1)
	signal.Notify(stopChan, os.Interrupt, syscall.SIGTERM)

	go func() {
		logger.Info("auth-service escuchando peticiones", "addr", server.Addr)
		if err := server.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
			logger.Error("Error en servidor auth-service", "error", err)
			os.Exit(1)
		}
	}()

	<-stopChan
	logger.Info("Recibida señal de terminación, ejecutando shutdown graceful...")

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	if err := server.Shutdown(ctx); err != nil {
		logger.Error("Error durante shutdown graceful", "error", err)
	}
	logger.Info("auth-service finalizado correctamente")
}
