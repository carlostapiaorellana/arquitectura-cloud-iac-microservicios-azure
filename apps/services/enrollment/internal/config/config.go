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
	port := getEnv("PORT", "8084")
	env := getEnv("ENV", "local")

	mysqlHost := getEnv("MYSQL_HOST", "localhost")
	mysqlPortStr := getEnv("MYSQL_PORT", "3306")
	mysqlPort, err := strconv.Atoi(mysqlPortStr)
	if err != nil {
		mysqlPort = 3306
	}
	mysqlUser := getEnv("MYSQL_USER", "enrollment_user")
	mysqlPass := getEnv("MYSQL_PASSWORD", "enrollment_user_pass123")
	mysqlDB := getEnv("MYSQL_DATABASE", "enrollment_db")

	redisAddr := getEnv("REDIS_ADDR", "localhost:6379")
	redisPass := getEnv("REDIS_PASSWORD", "")
	redisDBStr := getEnv("REDIS_DB", "0")
	redisDB, _ := strconv.Atoi(redisDBStr)
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
		RedisPassword: redisPass,
		RedisDB:       redisDB,
		EventBusType:  eventBusType,
	}
}

func getEnv(key, defaultVal string) string {
	if val := os.Getenv(key); val != "" {
		return val
	}
	return defaultVal
}
