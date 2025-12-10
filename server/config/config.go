package config

import (
	"fmt"
	"os"
	"strconv"

	"github.com/spf13/viper"
)

type Config struct {
	// Database
	DBHost     string
	DBPort     string
	DBUser     string
	DBPassword string
	DBName     string
	DBSSLMode  string

	// Server
	ServerPort string
	ServerHost string

	// WebSocket
	WSPort string
	WSHost string

	// JWT
	JWTSecret string

	// Verification Code
	VerifyCodeExpireMinutes int

	// Application
	AppEnv string

	// Agora
	AgoraAppID          string
	AgoraAppCertificate string

	// Redis
	RedisHost     string
	RedisPort     string
	RedisPassword string
	RedisDB       int
}

var AppConfig *Config

// LoadConfig 加载配置
func LoadConfig() {
	// 设置配置文件
	viper.SetConfigFile(".env")
	viper.SetConfigType("env")

	// 自动读取环境变量
	viper.AutomaticEnv()

	// 读取配置文件（如果存在）
	if err := viper.ReadInConfig(); err != nil {
		fmt.Println("Warning: .env file not found, using environment variables")
	}

	verifyExpire, _ := strconv.Atoi(getEnvViper("VERIFY_CODE_EXPIRE_MINUTES", "5"))
	redisDB, _ := strconv.Atoi(getEnvViper("REDIS_DB", "0"))

	AppConfig = &Config{
		DBHost:                  getEnvViper("DB_HOST", "127.0.0.1"),
		DBPort:                  getEnvViper("DB_PORT", "5432"),
		DBUser:                  getEnvViper("DB_USER", "postgres"),
		DBPassword:              getEnvViper("PASSWORD2", "postgres"),
		DBName:                  getEnvViper("DB_NAME", "youdu_db"),
		DBSSLMode:               getEnvViper("DB_SSLMODE", "disable"),
		ServerPort:              getEnvViper("SERVER_PORT", "8080"),
		ServerHost:              getEnvViper("SERVER_HOST", "0.0.0.0"),
		WSPort:                  getEnvViper("WS_PORT", "8081"),
		WSHost:                  getEnvViper("WS_HOST", "0.0.0.0"),
		JWTSecret:               getEnvViper("JWT_SECRET", "your_jwt_secret_key"),
		VerifyCodeExpireMinutes: verifyExpire,
		AppEnv:                  getEnvViper("APP_ENV", "development"),
		AgoraAppID:              getEnvViper("AGORA_APP_ID", ""),
		AgoraAppCertificate:     getEnvViper("AGORA_APP_CERTIFICATE", ""),
		RedisHost:               getEnvViper("REDIS_HOST", "127.0.0.1"),
		RedisPort:               getEnvViper("REDIS_PORT", "6379"),
		RedisPassword:           getEnvViper("REDIS_PASSWORD", ""),
		RedisDB:                 redisDB,
	}
}

// getEnvViper 使用 Viper 获取环境变量，如果不存在则返回默认值
func getEnvViper(key, defaultValue string) string {
	viper.SetDefault(key, defaultValue)
	return viper.GetString(key)
}

// getEnv 获取环境变量，如果不存在则返回默认值（保持向后兼容）
func getEnv(key, defaultValue string) string {
	value := os.Getenv(key)
	if value == "" {
		return defaultValue
	}
	return value
}
