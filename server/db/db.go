package db

import (
	"database/sql"
	"fmt"

	"youdu-server/config"

	_ "github.com/lib/pq"
)

var DB *sql.DB

// InitDB 初始化数据库连接
func InitDB() error {
	cfg := config.AppConfig

	// 调试输出
	fmt.Printf("数据库配置:\n")
	fmt.Printf("  Host: %s\n", cfg.DBHost)
	fmt.Printf("  Port: %s\n", cfg.DBPort)
	fmt.Printf("  User: %s\n", cfg.DBUser)
	fmt.Printf("  Password: %s (len=%d)\n", cfg.DBPassword, len(cfg.DBPassword))
	fmt.Printf("  DBName: %s\n", cfg.DBName)
	fmt.Printf("  SSLMode: %s\n", cfg.DBSSLMode)

	connStr := fmt.Sprintf(
		"host=%s port=%s user=%s password=%s dbname=%s sslmode=%s",
		cfg.DBHost,
		cfg.DBPort,
		cfg.DBUser,
		cfg.DBPassword,
		cfg.DBName,
		cfg.DBSSLMode,
	)
	fmt.Printf("连接字符串: %s\n", connStr)

	var err error
	DB, err = sql.Open("postgres", connStr)
	if err != nil {
		fmt.Printf("failed to open database: %w", err)
		return err
	}

	// 测试数据库连接
	if err = DB.Ping(); err != nil {
		fmt.Printf("failed to ping database: %w", err)
		return err
	}

	// 设置连接池参数
	DB.SetMaxOpenConns(25)
	DB.SetMaxIdleConns(5)

	fmt.Printf("Database connected successfully")
	return nil
}

// CloseDB 关闭数据库连接
func CloseDB() {
	if DB != nil {
		DB.Close()
		fmt.Printf("Database connection closed")
	}
}
