package config

import (
	"os"
	"strconv"
	"time"
)

type Config struct {
	Port                   string
	Env                    string
	MySQLHost              string
	MySQLPort              int
	MySQLUser              string
	MySQLPassword          string
	MySQLDatabase          string
	CertsDir               string
	TokenExpiration        time.Duration
	RefreshTokenExpiration time.Duration
	EventBusType           string
	RedisAddr              string
	RedisPassword          string
	ServiceBusFQDN         string
}

func LoadConfig() *Config {
	port := getEnv("PORT", "8081")
	env := getEnv("ENV", "local")

	mysqlHost := getEnv("MYSQL_HOST", "localhost")
	mysqlPortStr := getEnv("MYSQL_PORT", "3306")
	mysqlPort, err := strconv.Atoi(mysqlPortStr)
	if err != nil {
		mysqlPort = 3306
	}
	mysqlUser := getEnv("MYSQL_USER", "auth_user")
	mysqlPass := getEnv("MYSQL_PASSWORD", "auth_user_pass123")
	mysqlDB := getEnv("MYSQL_DATABASE", "auth_db")

	certsDir := getEnv("CERTS_DIR", "./certs")

	tokenExpMinutesStr := getEnv("JWT_EXPIRATION_MINUTES", "60")
	tokenExpMinutes, err := strconv.Atoi(tokenExpMinutesStr)
	if err != nil {
		tokenExpMinutes = 60
	}

	refreshExpDaysStr := getEnv("REFRESH_TOKEN_EXPIRATION_DAYS", "7")
	refreshExpDays, err := strconv.Atoi(refreshExpDaysStr)
	if err != nil {
		refreshExpDays = 7
	}

	eventBusType := getEnv("EVENT_BUS_TYPE", "local_redis")
	redisAddr := getEnv("REDIS_ADDR", "localhost:6379")
	redisPassword := getEnv("REDIS_PASSWORD", "")
	serviceBusFQDN := getEnv("SERVICEBUS_FQDN", "")

	return &Config{
		Port:                   port,
		Env:                    env,
		MySQLHost:              mysqlHost,
		MySQLPort:              mysqlPort,
		MySQLUser:              mysqlUser,
		MySQLPassword:          mysqlPassword(mysqlPass),
		MySQLDatabase:          mysqlDB,
		CertsDir:               certsDir,
		TokenExpiration:        time.Duration(tokenExpMinutes) * time.Minute,
		RefreshTokenExpiration: time.Duration(refreshExpDays) * 24 * time.Hour,
		EventBusType:           eventBusType,
		RedisAddr:              redisAddr,
		RedisPassword:          redisPassword,
		ServiceBusFQDN:         serviceBusFQDN,
	}
}

func mysqlPassword(pass string) string {
	return pass
}

func getEnv(key, defaultVal string) string {
	if val := os.Getenv(key); val != "" {
		return val
	}
	return defaultVal
}
