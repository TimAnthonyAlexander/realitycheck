package config

import (
	"os"
	"strconv"
	"time"
)

// Config holds all application configuration
type Config struct {
	// HTTP Server
	HTTPAddr string

	// Database
	DatabaseDSN string

	// OpenAI
	OpenAIAPIKey string
	OpenAIRPS    int
	OpenAIBurst  int

	// Cache
	CacheLRUSize int
	CacheTTL     time.Duration
	CacheDir     string

	// Analysis
	MaxEvidencePerQuery int
	MaxQueries          int
	AnalysisTimeout     time.Duration

	// Security
	BearerToken string

	// Telemetry
	LogLevel string
}

// Load reads configuration from environment variables with defaults
func Load() *Config {
	return &Config{
		HTTPAddr:            getEnv("HTTP_ADDR", ":8080"),
		DatabaseDSN:         getEnv("DB_DSN", "postgres://localhost/realitycheck?sslmode=disable"),
		OpenAIAPIKey:        getEnv("OPENAI_API_KEY", ""),
		OpenAIRPS:           getEnvInt("OPENAI_RPS", 2),
		OpenAIBurst:         getEnvInt("OPENAI_BURST", 4),
		CacheLRUSize:        getEnvInt("CACHE_LRU_SIZE", 4096),
		CacheTTL:            getEnvDuration("CACHE_TTL", 24*time.Hour),
		CacheDir:            getEnv("CACHE_DIR", "/var/lib/realitycheck/cache"),
		MaxEvidencePerQuery: getEnvInt("MAX_EVIDENCE_PER_QUERY", 10),
		MaxQueries:          getEnvInt("MAX_QUERIES", 20),
		AnalysisTimeout:     getEnvDuration("ANALYSIS_TIMEOUT", 60*time.Second),
		BearerToken:         getEnv("BEARER_TOKEN", ""),
		LogLevel:            getEnv("LOG_LEVEL", "info"),
	}
}

// Validate checks if required configuration is present
func (c *Config) Validate() error {
	if c.OpenAIAPIKey == "" {
		return ErrMissingOpenAIKey
	}
	return nil
}

func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

func getEnvInt(key string, defaultValue int) int {
	if value := os.Getenv(key); value != "" {
		if parsed, err := strconv.Atoi(value); err == nil {
			return parsed
		}
	}
	return defaultValue
}

func getEnvDuration(key string, defaultValue time.Duration) time.Duration {
	if value := os.Getenv(key); value != "" {
		if parsed, err := time.ParseDuration(value); err == nil {
			return parsed
		}
	}
	return defaultValue
}
