package config

import (
	"os"
	"strings"
)

type Config struct {
	Port                 string
	Env                  string
	AuthServiceURL       string
	PersonServiceURL     string
	AcademicServiceURL   string
	EnrollmentServiceURL string
	FinanceServiceURL    string
	LibraryServiceURL    string
	LmsServiceURL        string
	JWKSURL              string
	AllowedOrigins       []string
}

func LoadConfig() *Config {
	port := getEnv("PORT", "8080")
	env := getEnv("ENV", "local")

	authURL := getEnv("AUTH_SERVICE_URL", "http://localhost:8081")
	personURL := getEnv("PERSON_SERVICE_URL", "http://localhost:8082")
	academicURL := getEnv("ACADEMIC_SERVICE_URL", "http://localhost:8083")
	enrollmentURL := getEnv("ENROLLMENT_SERVICE_URL", "http://localhost:8084")
	financeURL := getEnv("FINANCE_SERVICE_URL", "http://localhost:8085")
	libraryURL := getEnv("LIBRARY_SERVICE_URL", "http://localhost:8086")
	lmsURL := getEnv("LMS_SERVICE_URL", "http://localhost:8087")

	jwksURL := getEnv("JWKS_URL", authURL+"/.well-known/jwks.json")

	originsRaw := getEnv("ALLOWED_ORIGINS", getEnv("CORS_ALLOWED_ORIGINS", "http://localhost:3000,http://localhost:5173"))
	var allowedOrigins []string
	for _, o := range strings.Split(originsRaw, ",") {
		trimmed := strings.TrimSpace(o)
		if trimmed != "" && trimmed != "*" {
			allowedOrigins = append(allowedOrigins, trimmed)
		}
	}

	return &Config{
		Port:                 port,
		Env:                  env,
		AuthServiceURL:       authURL,
		PersonServiceURL:     personURL,
		AcademicServiceURL:   academicURL,
		EnrollmentServiceURL: enrollmentURL,
		FinanceServiceURL:    financeURL,
		LibraryServiceURL:    libraryURL,
		LmsServiceURL:        lmsURL,
		JWKSURL:              jwksURL,
		AllowedOrigins:       allowedOrigins,
	}
}

func getEnv(key, defaultVal string) string {
	if val := os.Getenv(key); val != "" {
		return val
	}
	return defaultVal
}
