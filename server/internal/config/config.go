package config

import (
	"os"
)

type Config struct {
	Server   ServerConfig   `json:"server"`
	Database DatabaseConfig `json:"database"`
	Security SecurityConfig `json:"security"`
}

type ServerConfig struct {
	Host         string `json:"host"`
	Port         string `json:"port"`
	WebSocketPath string `json:"websocket_path"`
}

type DatabaseConfig struct {
	Type string `json:"type"`
	Path string `json:"path"`
}

type SecurityConfig struct {
	EnableAuth  bool `json:"enable_auth"`
	TokenExpiry int  `json:"token_expiry"`
}

func Load() *Config {
	cfg := &Config{
		Server: ServerConfig{
			Host:         getEnv("HOST", "0.0.0.0"),
			Port:         getEnv("PORT", "8080"),
			WebSocketPath: "/ws",
		},
		Database: DatabaseConfig{
			Type: getEnv("DB_TYPE", "sqlite"),
			Path: getEnv("DB_PATH", "./data.db"),
		},
		Security: SecurityConfig{
			EnableAuth:  false, // 开发阶段先关闭
			TokenExpiry: 3600,
		},
	}
	return cfg
}

func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

