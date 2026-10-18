package config

import (
	"os"
)

type Config struct {
	Port          string
	Env           string
	NoSQLProvider string
	NoSQLEndpoint string
	DatabaseName  string
}

func LoadConfig() *Config {
	return &Config{
		Port:          getEnv("PORT", "8086"),
		Env:           getEnv("ENV", "local"),
		NoSQLProvider: getEnv("NOSQL_PROVIDER", "dynamodb_local"),
		NoSQLEndpoint: getEnv("NOSQL_ENDPOINT", "http://dynamodb-local:8000"),
		DatabaseName:  getEnv("NOSQL_DATABASE", "library_db"),
	}
}

func getEnv(key, defaultVal string) string {
	if val := os.Getenv(key); val != "" {
		return val
	}
	return defaultVal
}
