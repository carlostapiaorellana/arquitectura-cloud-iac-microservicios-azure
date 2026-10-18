package proxy

import (
	"fmt"
	"log/slog"
	"net/http"
	"net/http/httputil"
	"net/url"
	"strings"

	apicontracts "github.com/universidad/platform/packages/api-contracts"
	errorhandling "github.com/universidad/platform/packages/error-handling"
	"github.com/universidad/platform/packages/observability"
	"github.com/universidad/platform/apps/gateway/internal/services"
)

type GatewayProxy struct {
	authURL         *url.URL
	personURL       *url.URL
	academicURL     *url.URL
	enrollmentURL   *url.URL
	financeURL      *url.URL
	libraryURL      *url.URL
	lmsURL          *url.URL
	authProxy       *httputil.ReverseProxy
	personProxy     *httputil.ReverseProxy
	academicProxy   *httputil.ReverseProxy
	enrollmentProxy *httputil.ReverseProxy
	financeProxy    *httputil.ReverseProxy
	libraryProxy    *httputil.ReverseProxy
	lmsProxy        *httputil.ReverseProxy
	jwksClient      *services.JWKSClient
	allowedOrigins  []string
	logger          *slog.Logger
}

func NewGatewayProxy(
	authTarget string,
	personTarget string,
	academicTarget string,
	enrollmentTarget string,
	financeTarget string,
	libraryTarget string,
	lmsTarget string,
	jwksClient *services.JWKSClient,
	allowedOrigins []string,
	logger *slog.Logger,
) (*GatewayProxy, error) {
	aURL, err := url.Parse(authTarget)
	if err != nil {
		return nil, fmt.Errorf("target auth inválido: %w", err)
	}

	pURL, err := url.Parse(personTarget)
	if err != nil {
		return nil, fmt.Errorf("target person inválido: %w", err)
	}

	acURL, err := url.Parse(academicTarget)
	if err != nil {
		return nil, fmt.Errorf("target academic inválido: %w", err)
	}

	eURL, err := url.Parse(enrollmentTarget)
	if err != nil {
		return nil, fmt.Errorf("target enrollment inválido: %w", err)
	}

	fURL, err := url.Parse(financeTarget)
	if err != nil {
		return nil, fmt.Errorf("target finance inválido: %w", err)
	}

	lURL, err := url.Parse(libraryTarget)
	if err != nil {
		return nil, fmt.Errorf("target library inválido: %w", err)
	}

	lmsURL, err := url.Parse(lmsTarget)
	if err != nil {
		return nil, fmt.Errorf("target lms inválido: %w", err)
	}

	return &GatewayProxy{
		authURL:         aURL,
		personURL:       pURL,
		academicURL:     acURL,
		enrollmentURL:   eURL,
		financeURL:      fURL,
		libraryURL:      lURL,
		lmsURL:          lmsURL,
		authProxy:       newServiceReverseProxy(aURL, "auth-service", logger),
		personProxy:     newServiceReverseProxy(pURL, "person-service", logger),
		academicProxy:   newServiceReverseProxy(acURL, "academic-service", logger),
		enrollmentProxy: newServiceReverseProxy(eURL, "enrollment-service", logger),
		financeProxy:    newServiceReverseProxy(fURL, "finance-service", logger),
		libraryProxy:    newServiceReverseProxy(lURL, "library-service", logger),
		lmsProxy:        newServiceReverseProxy(lmsURL, "lms-service", logger),
		jwksClient:      jwksClient,
		allowedOrigins:  allowedOrigins,
		logger:          logger,
	}, nil
}

// newServiceReverseProxy inicializa un ReverseProxy con ErrorHandler canónico JSON para upstreams caídos (REV-E2E-02)
func newServiceReverseProxy(target *url.URL, serviceName string, logger *slog.Logger) *httputil.ReverseProxy {
	proxy := httputil.NewSingleHostReverseProxy(target)
	originalDirector := proxy.Director
	proxy.Director = func(req *http.Request) {
		originalDirector(req)
		req.Host = target.Host
	}
	proxy.ErrorHandler = func(w http.ResponseWriter, r *http.Request, err error) {
		corrID := observability.ExtractOrGenerateCorrelationID(r)

		logger.Error("Fallo de conexión hacia microservicio upstream",
			"service", serviceName,
			"target", target.String(),
			"path", r.URL.Path,
			"error", err,
			"correlationId", corrID,
		)

		errorhandling.WriteEnvelope(
			w,
			http.StatusServiceUnavailable,
			errorhandling.CodeServiceUnavailable,
			"servicio temporalmente no disponible",
			corrID,
		)
	}
	return proxy
}

func (gw *GatewayProxy) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	corrID := observability.ExtractOrGenerateCorrelationID(r)

	// 1. Manejo estricto de CORS por Lista Blanca (Zero-Wildcard - REV-FE-04)
	origin := r.Header.Get("Origin")
	if origin != "" {
		allowed := false
		for _, o := range gw.allowedOrigins {
			if o == origin {
				allowed = true
				break
			}
		}
		if allowed {
			w.Header().Set("Access-Control-Allow-Origin", origin)
			w.Header().Set("Vary", "Origin")
			w.Header().Set("Access-Control-Allow-Credentials", "true")
			w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, PATCH, DELETE, OPTIONS")
			w.Header().Set("Access-Control-Allow-Headers", "Authorization, Content-Type, X-Correlation-Id, Idempotency-Key")
			w.Header().Set("Access-Control-Expose-Headers", "X-Correlation-Id, X-Cache")
			w.Header().Set("Access-Control-Max-Age", "86400")
		} else {
			gw.logger.Warn("Solicitud CORS bloqueada: origen no autorizado", "origin", origin, "method", r.Method, "correlationId", corrID)
			w.WriteHeader(http.StatusForbidden)
			return
		}
	}

	if r.Method == http.MethodOptions {
		w.WriteHeader(http.StatusNoContent)
		return
	}

	// 2. SEGURIDAD PERIMETRAL: Stripping forzoso de cabeceras X-User-*
	r.Header.Del(apicontracts.HeaderUserID)
	r.Header.Del(apicontracts.HeaderUserRole)
	r.Header.Del(apicontracts.HeaderUserScopes)
	r.Header.Del(apicontracts.HeaderUserEmail)

	// Propagar Correlation ID hacia upstreams
	r.Header.Set(observability.HeaderCorrelationID, corrID)

	path := r.URL.Path
	if strings.HasPrefix(path, "/api/v1/api/v1/") {
		path = strings.TrimPrefix(path, "/api/v1")
		r.URL.Path = path
	}

	// 3. Endpoints de salud del API Gateway
	if path == "/health" || path == "/health/live" {
		w.Header().Set("Content-Type", "application/json; charset=utf-8")
		w.WriteHeader(http.StatusOK)
		_, _ = w.Write([]byte(`{"status":"UP","service":"api-gateway"}`))
		return
	}
	if path == "/health/ready" {
		w.Header().Set("Content-Type", "application/json; charset=utf-8")
		w.WriteHeader(http.StatusOK)
		_, _ = w.Write([]byte(`{"status":"READY","service":"api-gateway"}`))
		return
	}

	// 4. Rutas Públicas (auth-service)
	if strings.HasPrefix(path, "/api/v1/auth/") || strings.HasPrefix(path, "/.well-known/") {
		gw.logger.Debug("Enrutando hacia auth-service", "path", path, "correlationId", corrID)
		gw.authProxy.ServeHTTP(w, r)
		return
	}

	// 5. Rutas Protegidas (person-service)
	if strings.HasPrefix(path, "/api/v1/person/") {
		authHeader := r.Header.Get("Authorization")
		if authHeader == "" || !strings.HasPrefix(authHeader, "Bearer ") {
			errorhandling.WriteError(w, r, errorhandling.NewUnauthenticatedError("token Bearer requerido", nil))
			return
		}

		tokenStr := strings.TrimPrefix(authHeader, "Bearer ")
		claims, err := gw.jwksClient.VerifyToken(tokenStr)
		if err != nil {
			gw.logger.Warn("Token JWT inválido o expirado", "error", err, "correlationId", corrID)
			errorhandling.WriteError(w, r, errorhandling.NewUnauthenticatedError("token inválido: "+err.Error(), nil))
			return
		}

		// INYECCIÓN DE IDENTIDAD AUTENTICADA (Los microservicios internos confían plenamente en estas cabeceras)
		r.Header.Set(apicontracts.HeaderUserID, claims.Sub)
		if claims.Role != "" {
			r.Header.Set(apicontracts.HeaderUserRole, claims.Role)
		} else if len(claims.Roles) > 0 {
			r.Header.Set(apicontracts.HeaderUserRole, claims.Roles[0])
		}
		if len(claims.Scopes) > 0 {
			r.Header.Set(apicontracts.HeaderUserScopes, strings.Join(claims.Scopes, ","))
		}

		gw.logger.Debug("Enrutando hacia person-service", "path", path, "user", claims.Sub, "correlationId", corrID)
		gw.personProxy.ServeHTTP(w, r)
		return
	}

	// 6. Rutas de Dominio Académico (academic-service - Acceso público o autenticado)
	if strings.HasPrefix(path, "/api/v1/academic/") {
		authHeader := r.Header.Get("Authorization")
		if authHeader != "" && strings.HasPrefix(authHeader, "Bearer ") {
			tokenStr := strings.TrimPrefix(authHeader, "Bearer ")
			if claims, err := gw.jwksClient.VerifyToken(tokenStr); err == nil {
				r.Header.Set(apicontracts.HeaderUserID, claims.Sub)
				if claims.Role != "" {
					r.Header.Set(apicontracts.HeaderUserRole, claims.Role)
				} else if len(claims.Roles) > 0 {
					r.Header.Set(apicontracts.HeaderUserRole, claims.Roles[0])
				}
				if len(claims.Scopes) > 0 {
					r.Header.Set(apicontracts.HeaderUserScopes, strings.Join(claims.Scopes, ","))
				}
			}
		}

		gw.logger.Debug("Enrutando hacia academic-service", "path", path, "correlationId", corrID)
		gw.academicProxy.ServeHTTP(w, r)
		return
	}

	// 7. Rutas Protegidas de Matrículas (enrollment-service)
	if strings.HasPrefix(path, "/api/v1/enrollment/") {
		authHeader := r.Header.Get("Authorization")
		if authHeader == "" || !strings.HasPrefix(authHeader, "Bearer ") {
			errorhandling.WriteError(w, r, errorhandling.NewUnauthenticatedError("token Bearer requerido", nil))
			return
		}

		tokenStr := strings.TrimPrefix(authHeader, "Bearer ")
		claims, err := gw.jwksClient.VerifyToken(tokenStr)
		if err != nil {
			gw.logger.Warn("Token JWT inválido o expirado", "error", err, "correlationId", corrID)
			errorhandling.WriteError(w, r, errorhandling.NewUnauthenticatedError("token inválido: "+err.Error(), nil))
			return
		}

		// INYECCIÓN DE IDENTIDAD AUTENTICADA (Los microservicios internos confían plenamente en estas cabeceras)
		r.Header.Set(apicontracts.HeaderUserID, claims.Sub)
		if claims.Role != "" {
			r.Header.Set(apicontracts.HeaderUserRole, claims.Role)
		} else if len(claims.Roles) > 0 {
			r.Header.Set(apicontracts.HeaderUserRole, claims.Roles[0])
		}
		if len(claims.Scopes) > 0 {
			r.Header.Set(apicontracts.HeaderUserScopes, strings.Join(claims.Scopes, ","))
		}

		gw.logger.Debug("Enrutando hacia enrollment-service", "path", path, "user", claims.Sub, "correlationId", corrID)
		gw.enrollmentProxy.ServeHTTP(w, r)
		return
	}

	// 8. Rutas Protegidas Financieras (finance-service)
	if strings.HasPrefix(path, "/api/v1/finance/") {
		authHeader := r.Header.Get("Authorization")
		if authHeader == "" || !strings.HasPrefix(authHeader, "Bearer ") {
			errorhandling.WriteError(w, r, errorhandling.NewUnauthenticatedError("token Bearer requerido", nil))
			return
		}

		tokenStr := strings.TrimPrefix(authHeader, "Bearer ")
		claims, err := gw.jwksClient.VerifyToken(tokenStr)
		if err != nil {
			gw.logger.Warn("Token JWT inválido o expirado", "error", err, "correlationId", corrID)
			errorhandling.WriteError(w, r, errorhandling.NewUnauthenticatedError("token inválido: "+err.Error(), nil))
			return
		}

		r.Header.Set(apicontracts.HeaderUserID, claims.Sub)
		if claims.Role != "" {
			r.Header.Set(apicontracts.HeaderUserRole, claims.Role)
		} else if len(claims.Roles) > 0 {
			r.Header.Set(apicontracts.HeaderUserRole, claims.Roles[0])
		}
		if len(claims.Scopes) > 0 {
			r.Header.Set(apicontracts.HeaderUserScopes, strings.Join(claims.Scopes, ","))
		}

		// Propagar Idempotency-Key si fue provista
		if ik := r.Header.Get("Idempotency-Key"); ik != "" {
			r.Header.Set("Idempotency-Key", ik)
		}

		gw.logger.Debug("Enrutando hacia finance-service", "path", path, "user", claims.Sub, "correlationId", corrID)
		gw.financeProxy.ServeHTTP(w, r)
		return
	}

	// 9. Rutas de Biblioteca Documental NoSQL (library-service)
	if strings.HasPrefix(path, "/api/v1/library/") {
		authHeader := r.Header.Get("Authorization")
		hasToken := authHeader != "" && strings.HasPrefix(authHeader, "Bearer ")

		// /api/v1/library/books es público; préstamos requieren token
		isLoansRoute := strings.HasPrefix(path, "/api/v1/library/loans") || strings.HasPrefix(path, "/api/v1/library/my-loans")

		if isLoansRoute && !hasToken {
			errorhandling.WriteError(w, r, errorhandling.NewUnauthenticatedError("token Bearer requerido", nil))
			return
		}

		if hasToken {
			tokenStr := strings.TrimPrefix(authHeader, "Bearer ")
			claims, err := gw.jwksClient.VerifyToken(tokenStr)
			if err != nil {
				if isLoansRoute {
					gw.logger.Warn("Token JWT inválido o expirado", "error", err, "correlationId", corrID)
					errorhandling.WriteError(w, r, errorhandling.NewUnauthenticatedError("token inválido: "+err.Error(), nil))
					return
				}
			} else {
				r.Header.Set(apicontracts.HeaderUserID, claims.Sub)
				if claims.Role != "" {
					r.Header.Set(apicontracts.HeaderUserRole, claims.Role)
				} else if len(claims.Roles) > 0 {
					r.Header.Set(apicontracts.HeaderUserRole, claims.Roles[0])
				}
				if len(claims.Scopes) > 0 {
					r.Header.Set(apicontracts.HeaderUserScopes, strings.Join(claims.Scopes, ","))
				}
			}
		}

		gw.logger.Debug("Enrutando hacia library-service", "path", path, "correlationId", corrID)
		gw.libraryProxy.ServeHTTP(w, r)
		return
	}

	// 10. Rutas de Aula Virtual LMS Documental NoSQL (lms-service)
	if strings.HasPrefix(path, "/api/v1/lms/") {
		authHeader := r.Header.Get("Authorization")
		if authHeader == "" || !strings.HasPrefix(authHeader, "Bearer ") {
			errorhandling.WriteError(w, r, errorhandling.NewUnauthenticatedError("token Bearer requerido", nil))
			return
		}

		tokenStr := strings.TrimPrefix(authHeader, "Bearer ")
		claims, err := gw.jwksClient.VerifyToken(tokenStr)
		if err != nil {
			gw.logger.Warn("Token JWT inválido o expirado", "error", err, "correlationId", corrID)
			errorhandling.WriteError(w, r, errorhandling.NewUnauthenticatedError("token inválido: "+err.Error(), nil))
			return
		}

		r.Header.Set(apicontracts.HeaderUserID, claims.Sub)
		if claims.Role != "" {
			r.Header.Set(apicontracts.HeaderUserRole, claims.Role)
		} else if len(claims.Roles) > 0 {
			r.Header.Set(apicontracts.HeaderUserRole, claims.Roles[0])
		}
		if len(claims.Scopes) > 0 {
			r.Header.Set(apicontracts.HeaderUserScopes, strings.Join(claims.Scopes, ","))
		}

		gw.logger.Debug("Enrutando hacia lms-service", "path", path, "user", claims.Sub, "correlationId", corrID)
		gw.lmsProxy.ServeHTTP(w, r)
		return
	}

	// 11. Ruta no encontrada en el Gateway
	errorhandling.WriteError(w, r, errorhandling.NewNotFoundError("la ruta solicitada no existe en el gateway", nil))
}
