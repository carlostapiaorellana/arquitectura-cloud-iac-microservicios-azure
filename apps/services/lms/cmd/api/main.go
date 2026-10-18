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

	"github.com/universidad/platform/packages/nosql"
	"github.com/universidad/platform/packages/observability"
	"github.com/universidad/platform/apps/services/lms/internal/config"
	"github.com/universidad/platform/apps/services/lms/internal/handlers"
	"github.com/universidad/platform/apps/services/lms/internal/repository"
	"github.com/universidad/platform/apps/services/lms/internal/services"
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

	logger := observability.InitLogger("lms-service", cfg.Env)
	logger.Info("Iniciando lms-service...", "port", cfg.Port, "env", cfg.Env)

	// 1. Inicializar cliente documental NoSQL (DynamoDB Local o Fallback In-Memory)
	docStore, err := nosql.NewDocumentStore(nosql.Config{
		Provider:     cfg.NoSQLProvider,
		Endpoint:     cfg.NoSQLEndpoint,
		DatabaseName: cfg.DatabaseName,
	})
	if err != nil {
		logger.Error("Fallo al inicializar almacén NoSQL de LMS", "error", err)
		os.Exit(1)
	}
	defer docStore.Close()

	// 2. Repositorio y Servicio
	lmsRepo := repository.NewNoSQLLmsRepo(docStore)
	lmsSvc := services.NewLmsService(lmsRepo, logger)

	// 3. Sembrado inicial idempotente si los cursos están vacíos
	initCtx, cancelInit := context.WithTimeout(context.Background(), 5*time.Second)
	if err := lmsSvc.SeedIfEmpty(initCtx); err != nil {
		logger.Warn("Aviso durante sembrado de LMS", "error", err)
	}
	cancelInit()

	// 4. Handlers
	lmsHandler := handlers.NewLmsHandler(lmsSvc)

	mux := http.NewServeMux()
	mux.HandleFunc("/health", lmsHandler.Live)
	mux.HandleFunc("/health/live", lmsHandler.Live)
	mux.HandleFunc("/health/ready", lmsHandler.Ready)
	mux.HandleFunc("/api/v1/lms/my-courses", lmsHandler.GetMyCourses)
	mux.HandleFunc("/api/v1/lms/courses/", lmsHandler.HandleCoursesRoutes)

	// Middlewares
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
		logger.Info("lms-service escuchando peticiones", "addr", server.Addr)
		if err := server.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
			logger.Error("Error en servidor lms-service", "error", err)
			os.Exit(1)
		}
	}()

	<-stopChan
	logger.Info("Recibida señal de terminación, ejecutando shutdown graceful de lms-service...")

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	if err := server.Shutdown(ctx); err != nil {
		logger.Error("Error durante shutdown graceful de lms-service", "error", err)
	}
	logger.Info("lms-service finalizado correctamente")
}
