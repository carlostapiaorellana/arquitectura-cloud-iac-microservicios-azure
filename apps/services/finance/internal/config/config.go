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
	RedisAddr     string
	RedisPassword string
	RedisDB       int
	EventBusType  string
}

func LoadConfig() *Config {
	port := getEnv("PORT", "8085")
	env := getEnv("ENV", "local")

	mysqlHost := getEnv("MYSQL_HOST", "localhost")
	mysqlPortStr := getEnv("MYSQL_PORT", "3306")
	mysqlPort, err := strconv.Atoi(mysqlPortStr)
	if err != nil {
		mysqlPort = 3306
	}

	mysqlUser := getEnv("MYSQL_USER", "finance_user")
	mysqlPass := getEnv("MYSQL_PASSWORD", "finance_user_pass123")
	mysqlDB := getEnv("MYSQL_DATABASE", "finance_db")

	redisAddr := getEnv("REDIS_ADDR", "localhost:6380")
	redisPassword := getEnv("REDIS_PASSWORD", "")
	eventBusType := getEnv("EVENT_BUS_TYPE", "local_redis")

	return &Config{
		Port:          port,
		Env:           env,
		MySQLHost:     mysqlHost,
		MySQLPort:     mysqlPort,
		MySQLUser:     mysqlUser,
		MySQLPassword: mysqlPass,
		MySQLDatabase: mysqlDB,
		RedisAddr:     redisAddr,
		RedisPassword: redisPassword,
		RedisDB:       0,
		EventBusType:  eventBusType,
	}
}

func getEnv(key, defaultVal string) string {
	if val := os.Getenv(key); val != "" {
		return val
	}
	return defaultVal
}
