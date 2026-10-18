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
	"github.com/universidad/platform/apps/services/library/internal/config"
	"github.com/universidad/platform/apps/services/library/internal/handlers"
	"github.com/universidad/platform/apps/services/library/internal/repository"
	"github.com/universidad/platform/apps/services/library/internal/services"
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

	logger := observability.InitLogger("library-service", cfg.Env)
	logger.Info("Iniciando library-service...", "port", cfg.Port, "env", cfg.Env)

	// 1. Inicializar cliente documental NoSQL (DynamoDB Local o Fallback In-Memory)
	docStore, err := nosql.NewDocumentStore(nosql.Config{
		Provider:     cfg.NoSQLProvider,
		Endpoint:     cfg.NoSQLEndpoint,
		DatabaseName: cfg.DatabaseName,
	})
	if err != nil {
		logger.Error("Fallo al inicializar almacén NoSQL de library", "error", err)
		os.Exit(1)
	}
	defer docStore.Close()

	// 2. Repositorio y Servicio
	libraryRepo := repository.NewNoSQLLibraryRepo(docStore)
	librarySvc := services.NewLibraryService(libraryRepo, logger)

	// 3. Sembrado inicial idempotente si el catálogo está vacío
	initCtx, cancelInit := context.WithTimeout(context.Background(), 5*time.Second)
	if err := librarySvc.SeedBooksIfEmpty(initCtx); err != nil {
		logger.Warn("Aviso durante sembrado de library", "error", err)
	}
	cancelInit()

	// 4. Handlers
	libraryHandler := handlers.NewLibraryHandler(librarySvc)

	mux := http.NewServeMux()
	mux.HandleFunc("/health", libraryHandler.Live)
	mux.HandleFunc("/health/live", libraryHandler.Live)
	mux.HandleFunc("/health/ready", libraryHandler.Ready)
	mux.HandleFunc("/api/v1/library/books", libraryHandler.GetBooks)
	mux.HandleFunc("/api/v1/library/loans", libraryHandler.CreateLoan)
	mux.HandleFunc("/api/v1/library/my-loans", libraryHandler.GetMyLoans)

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
		logger.Info("library-service escuchando peticiones", "addr", server.Addr)
		if err := server.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
			logger.Error("Error en servidor library-service", "error", err)
			os.Exit(1)
		}
	}()

	<-stopChan
	logger.Info("Recibida señal de terminación, ejecutando shutdown graceful de library-service...")

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	if err := server.Shutdown(ctx); err != nil {
		logger.Error("Error durante shutdown graceful de library-service", "error", err)
	}
	logger.Info("library-service finalizado correctamente")
}
