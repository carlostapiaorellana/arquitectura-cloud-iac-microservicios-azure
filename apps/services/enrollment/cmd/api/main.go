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
	"github.com/universidad/platform/apps/services/enrollment/internal/config"
	"github.com/universidad/platform/apps/services/enrollment/internal/handlers"
	"github.com/universidad/platform/apps/services/enrollment/internal/repository"
	"github.com/universidad/platform/apps/services/enrollment/internal/services"
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

	logger := observability.InitLogger("enrollment-service", cfg.Env)
	logger.Info("Iniciando enrollment-service...", "port", cfg.Port, "env", cfg.Env)

	// 1. Inicializar conexión a MySQL (enrollment_db)
	db, err := mysql.NewClient(mysql.Config{
		Host:     cfg.MySQLHost,
		Port:     cfg.MySQLPort,
		User:     cfg.MySQLUser,
		Password: cfg.MySQLPassword,
		Database: cfg.MySQLDatabase,
	})
	if err != nil {
		logger.Error("Fallo crítico al inicializar pool MySQL en enrollment_db", "error", err)
		os.Exit(1)
	}
	defer db.Close()

	// 2. Inicializar Bus de Mensajería (EDA / Redis Streams o Azure Service Bus)
	messageBus, err := messaging.NewMessageBus(messaging.Config{
		Type:          cfg.EventBusType,
		RedisAddr:     cfg.RedisAddr,
		RedisPassword: cfg.RedisPassword,
		RedisDB:       cfg.RedisDB,
	})
	if err != nil {
		logger.Warn("Fallo al inicializar message bus; operando en modo degradado sin eventos", "error", err)
	} else {
		defer messageBus.Close()
		if err := messageBus.Ping(context.Background()); err != nil {
			logger.Warn("Ping inicial a message bus falló, se reintentará en segundo plano", "error", err)
		} else {
			logger.Info("Conectado exitosamente al message bus", "type", cfg.EventBusType)
		}
	}

	// 3. Inicializar Repositorio y Servicio
	enrollmentRepo := repository.NewMySQLEnrollmentRepo(db)
	enrollmentSvc := services.NewEnrollmentService(enrollmentRepo, messageBus, logger)

	// 4. Handlers
	enrollmentHandler := handlers.NewEnrollmentHandler(enrollmentSvc)
	healthHandler := handlers.NewHealthHandler(db, messageBus)

	mux := http.NewServeMux()
	mux.HandleFunc("/health", healthHandler.Live)
	mux.HandleFunc("/health/live", healthHandler.Live)
	mux.HandleFunc("/health/ready", healthHandler.Ready)
	mux.HandleFunc("/api/v1/enrollment/my-enrollments", enrollmentHandler.GetMyEnrollments)
	mux.HandleFunc("/api/v1/enrollment/grades", enrollmentHandler.GetMyGrades)
	mux.HandleFunc("/api/v1/enrollment/register", enrollmentHandler.RegisterEnrollment)

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
		logger.Info("enrollment-service escuchando peticiones", "addr", server.Addr)
		if err := server.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
			logger.Error("Error en servidor enrollment-service", "error", err)
			os.Exit(1)
		}
	}()

	<-stopChan
	logger.Info("Recibida señal de terminación, ejecutando shutdown graceful de enrollment-service...")

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	if err := server.Shutdown(ctx); err != nil {
		logger.Error("Error durante shutdown graceful de enrollment-service", "error", err)
	}
	logger.Info("enrollment-service finalizado correctamente")
}
