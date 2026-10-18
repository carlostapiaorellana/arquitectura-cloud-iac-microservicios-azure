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

	"github.com/universidad/platform/packages/mysql"
	"github.com/universidad/platform/packages/observability"
	"github.com/universidad/platform/apps/services/person/internal/config"
	"github.com/universidad/platform/apps/services/person/internal/handlers"
	"github.com/universidad/platform/apps/services/person/internal/repository"
	"github.com/universidad/platform/apps/services/person/internal/services"
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

	logger := observability.InitLogger("person-service", cfg.Env)
	logger.Info("Iniciando person-service...", "port", cfg.Port, "env", cfg.Env)

	// 1. Inicializar conexión a MySQL (person_db)
	db, err := mysql.NewClient(mysql.Config{
		Host:     cfg.MySQLHost,
		Port:     cfg.MySQLPort,
		User:     cfg.MySQLUser,
		Password: cfg.MySQLPassword,
		Database: cfg.MySQLDatabase,
	})
	if err != nil {
		logger.Error("Fallo crítico al inicializar pool MySQL en person_db", "error", err)
		os.Exit(1)
	}
	defer db.Close()

	// 2. Inicializar Caché Redis
	cacheRepo := repository.NewRedisCacheRepo(cfg.RedisAddr, cfg.RedisPassword, cfg.RedisDB)
	if err := cacheRepo.Ping(context.Background()); err != nil {
		logger.Warn("Redis no disponible para person-service, operando sin caché distribuida", "error", err)
	} else {
		logger.Info("Conexión con Redis establecida para Cache-Aside", "addr", cfg.RedisAddr)
	}

	// 3. Inicializar Repositorio y Servicio
	personRepo := repository.NewMySQLPersonRepo(db)
	initCtx, cancelInit := context.WithTimeout(context.Background(), 10*time.Second)
	if err := personRepo.EnsureSchema(initCtx); err != nil {
		logger.Warn("Aviso durante ensure schema de person", "error", err)
	} else {
		logger.Info("Esquema y datos semilla de person verificados exitosamente")
	}
	cancelInit()

	personSvc := services.NewPersonService(personRepo, cacheRepo, cfg.CacheTTL)

	// 4. Handlers
	profileHandler := handlers.NewProfileHandler(personSvc)
	healthHandler := handlers.NewHealthHandler(db, cacheRepo)

	mux := http.NewServeMux()
	mux.HandleFunc("/api/v1/person/profile/me", profileHandler.HandleProfileMe)
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
		logger.Info("person-service escuchando peticiones", "addr", server.Addr)
		if err := server.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
			logger.Error("Error en servidor person-service", "error", err)
			os.Exit(1)
		}
	}()

	<-stopChan
	logger.Info("Recibida señal de terminación, ejecutando shutdown graceful de person-service...")

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	if err := server.Shutdown(ctx); err != nil {
		logger.Error("Error durante shutdown graceful de person-service", "error", err)
	}
	logger.Info("person-service finalizado correctamente")
}
