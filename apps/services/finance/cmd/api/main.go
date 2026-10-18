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
	"github.com/universidad/platform/apps/services/finance/internal/config"
	"github.com/universidad/platform/apps/services/finance/internal/handlers"
	"github.com/universidad/platform/apps/services/finance/internal/repository"
	"github.com/universidad/platform/apps/services/finance/internal/services"
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

	logger := observability.InitLogger("finance-service", cfg.Env)
	logger.Info("Iniciando finance-service...", "port", cfg.Port, "env", cfg.Env)

	// 1. Inicializar pool MySQL (finance_db)
	db, err := mysql.NewClient(mysql.Config{
		Host:     cfg.MySQLHost,
		Port:     cfg.MySQLPort,
		User:     cfg.MySQLUser,
		Password: cfg.MySQLPassword,
		Database: cfg.MySQLDatabase,
	})
	if err != nil {
		logger.Error("Fallo crítico al inicializar pool MySQL en finance_db", "error", err)
		os.Exit(1)
	}
	defer db.Close()

	// 2. Inicializar repositorio de Idempotencia en Redis
	idempotencyRepo := repository.NewRedisIdempotencyRepo(cfg.RedisAddr, cfg.RedisPassword, cfg.RedisDB)

	// 3. Inicializar Message Bus (Redis Streams local)
	msgBus, err := messaging.NewMessageBus(messaging.Config{
		Type:      cfg.EventBusType,
		RedisAddr: cfg.RedisAddr,
	})
	if err != nil {
		logger.Warn("Aviso: no se pudo inicializar message bus asíncrono", "error", err)
	} else {
		defer msgBus.Close()
	}

	// 4. Repositorios y Servicios
	mysqlRepo := repository.NewMySQLFinanceRepo(db)
	financeSvc := services.NewFinanceService(mysqlRepo, idempotencyRepo, msgBus, logger)

	// 5. Handlers
	financeHandler := handlers.NewFinanceHandler(financeSvc)
	healthHandler := handlers.NewHealthHandler(db, idempotencyRepo)

	mux := http.NewServeMux()
	mux.HandleFunc("/health", healthHandler.Live)
	mux.HandleFunc("/health/live", healthHandler.Live)
	mux.HandleFunc("/health/ready", healthHandler.Ready)
	mux.HandleFunc("/api/v1/finance/my-orders", financeHandler.GetMyOrders)
	mux.HandleFunc("/api/v1/finance/payments", financeHandler.ProcessPayment)

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
		logger.Info("finance-service escuchando peticiones", "addr", server.Addr)
		if err := server.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
			logger.Error("Error en servidor finance-service", "error", err)
			os.Exit(1)
		}
	}()

	<-stopChan
	logger.Info("Recibida señal de terminación, ejecutando shutdown graceful de finance-service...")

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	if err := server.Shutdown(ctx); err != nil {
		logger.Error("Error durante shutdown graceful de finance-service", "error", err)
	}
	logger.Info("finance-service finalizado correctamente")
}
