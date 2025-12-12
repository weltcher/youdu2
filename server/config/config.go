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

	// HTTPS/TLS
	EnableHTTPS bool
	CertFile    string
	KeyFile     string

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

	// 获取应用环境
	appEnv := getEnvViper("APP_ENV", "development")
	
	// Debug模式（development）下默认使用HTTP，生产环境默认使用HTTPS
	// 可以通过ENABLE_HTTPS环境变量显式覆盖
	enableHTTPS := getEnvViper("ENABLE_HTTPS", "false") == "true"
	if appEnv == "development" || appEnv == "debug" {
		// Debug模式下，除非显式设置ENABLE_HTTPS=true，否则使用HTTP
		enableHTTPS = getEnvViper("ENABLE_HTTPS", "false") == "true"
	} else {
		// 生产环境下，除非显式设置ENABLE_HTTPS=false，否则使用HTTPS
		enableHTTPS = getEnvViper("ENABLE_HTTPS", "true") == "true"
	}

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
		EnableHTTPS:             enableHTTPS,
		CertFile:                getEnvViper("CERT_FILE", "certs/server.crt"),
		KeyFile:                 getEnvViper("KEY_FILE", "certs/server.key"),
		JWTSecret:               getEnvViper("JWT_SECRET", "your_jwt_secret_key"),
		VerifyCodeExpireMinutes: verifyExpire,
		AppEnv:                  appEnv,
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
