package config

import (
	"os"
	"strconv"
)

type Config struct {
	Port          string
	Env           string
	MySQLHost     string
	MySQLPort     int
	MySQLUser     string
	MySQLPassword string
	MySQLDatabase string
}

func LoadConfig() *Config {
	port := getEnv("PORT", "8083")
	env := getEnv("ENV", "local")

	mysqlHost := getEnv("MYSQL_HOST", "localhost")
	mysqlPortStr := getEnv("MYSQL_PORT", "3306")
	mysqlPort, err := strconv.Atoi(mysqlPortStr)
	if err != nil {
		mysqlPort = 3306
	}
	mysqlUser := getEnv("MYSQL_USER", "academic_user")
	mysqlPass := getEnv("MYSQL_PASSWORD", "academic_user_pass123")
	mysqlDB := getEnv("MYSQL_DATABASE", "academic_db")

	return &Config{
		Port:          port,
		Env:           env,
		MySQLHost:     mysqlHost,
		MySQLPort:     mysqlPort,
		MySQLUser:     mysqlUser,
		MySQLPassword: mysqlPass,
		MySQLDatabase: mysqlDB,
	}
}

func getEnv(key, defaultVal string) string {
	if val := os.Getenv(key); val != "" {
		return val
	}
	return defaultVal
}
