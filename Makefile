# RealityCheck Makefile

.PHONY: help build run-api run-cli test clean deps migrate

# Default target
help:
	@echo "RealityCheck - Startup Idea Analysis Tool"
	@echo ""
	@echo "Available targets:"
	@echo "  build      - Build API and CLI binaries"
	@echo "  run-api    - Run the API server"
	@echo "  run-cli    - Run CLI with example (requires TITLE and ONELINER env vars)"
	@echo "  test       - Run tests"
	@echo "  clean      - Clean build artifacts"
	@echo "  deps       - Download dependencies"
	@echo "  migrate    - Run database migrations manually"
	@echo "  setup-db   - Create database and run migrations"
	@echo ""
	@echo "Environment variables:"
	@echo "  OPENAI_API_KEY - Required for analysis"
	@echo "  DB_DSN         - Database connection string"
	@echo ""
	@echo "Example usage:"
	@echo "  make build"
	@echo "  TITLE='MyStartup' ONELINER='AI-powered solution' make run-cli"

# Build targets
build: deps
	@echo "Building RealityCheck..."
	@mkdir -p bin
	go build -o bin/api cmd/api/main.go
	go build -o bin/cli cmd/cli/main.go
	@echo "Binaries built in ./bin/"

# Download dependencies
deps:
	@echo "Downloading dependencies..."
	go mod download
	go mod tidy

# Run API server
run-api: deps
	@echo "Starting RealityCheck API server..."
	go run cmd/api/main.go

# Run CLI (requires TITLE and ONELINER environment variables)
run-cli: deps
	@if [ -z "$(TITLE)" ] || [ -z "$(ONELINER)" ]; then \
		echo "Error: Set TITLE and ONELINER environment variables"; \
		echo "Example: TITLE='MyStartup' ONELINER='AI solution' make run-cli"; \
		exit 1; \
	fi
	@echo "Running analysis for: $(TITLE)"
	go run cmd/cli/main.go --title "$(TITLE)" --one-liner "$(ONELINER)" $(CLI_ARGS)

# Test targets
test: deps
	@echo "Running tests..."
	go test ./...

test-coverage: deps
	@echo "Running tests with coverage..."
	go test -cover ./...

# Database targets
setup-db:
	@echo "Setting up database..."
	@if command -v createdb >/dev/null 2>&1; then \
		createdb realitycheck 2>/dev/null || echo "Database might already exist"; \
	else \
		echo "PostgreSQL createdb not found. Please create 'realitycheck' database manually"; \
	fi

migrate: deps
	@echo "Running database migrations..."
	@if [ -f "internal/schema/migrations.sql" ]; then \
		psql realitycheck < internal/schema/migrations.sql; \
	else \
		echo "Migrations will run automatically when starting the API"; \
	fi

# Development targets
dev-api: deps
	@echo "Starting API in development mode with hot reload..."
	@which air >/dev/null 2>&1 || go install github.com/cosmtrek/air@latest
	air -c .air.toml

dev-setup: setup-db
	@echo "Setting up development environment..."
	@echo "Creating .env file template..."
	@if [ ! -f ".env" ]; then \
		echo "# RealityCheck Configuration" > .env; \
		echo "OPENAI_API_KEY=your-openai-api-key" >> .env; \
		echo "DB_DSN=postgres://localhost/realitycheck?sslmode=disable" >> .env; \
		echo "HTTP_ADDR=:9444" >> .env; \
		echo "LOG_LEVEL=debug" >> .env; \
		echo ".env file created. Please update with your OpenAI API key."; \
	else \
		echo ".env file already exists"; \
	fi

# Clean targets
clean:
	@echo "Cleaning build artifacts..."
	rm -rf bin/
	go clean

# Docker targets
docker-build:
	@echo "Building Docker image..."
	docker build -t realitycheck:latest .

docker-run: docker-build
	@echo "Running RealityCheck in Docker..."
	docker run -p 9444:9444 \
		-e OPENAI_API_KEY=$(OPENAI_API_KEY) \
		-e DB_DSN="host=host.docker.internal user=postgres dbname=realitycheck sslmode=disable" \
		realitycheck:latest

# Example targets
example-loom:
	@echo "Running example analysis for Loom..."
	TITLE="Loom" ONELINER="Agentic coding assistant creating verifiable patches" \
	CLI_ARGS="--format markdown --out examples/loom-analysis.md" \
	make run-cli

example-api-test:
	@echo "Testing API with example request..."
	@if ! curl -s http://localhost:9444/health >/dev/null; then \
		echo "API server not running. Start with 'make run-api' first"; \
		exit 1; \
	fi
	curl -X POST http://localhost:9444/v1/analyze \
		-H "Content-Type: application/json" \
		-d '{"idea":{"title":"TestStartup","one_liner":"AI-powered test solution"}}'

# Check prerequisites
check-prereqs:
	@echo "Checking prerequisites..."
	@go version >/dev/null 2>&1 || (echo "Go not installed" && exit 1)
	@psql --version >/dev/null 2>&1 || (echo "PostgreSQL not installed" && exit 1)
	@if [ -z "$(OPENAI_API_KEY)" ]; then \
		echo "Warning: OPENAI_API_KEY not set"; \
	fi
	@echo "Prerequisites check complete"

# Install target for system-wide installation
install: build
	@echo "Installing RealityCheck to /usr/local/bin..."
	sudo cp bin/api /usr/local/bin/realitycheck-api
	sudo cp bin/cli /usr/local/bin/realitycheck
	@echo "Installation complete. Use 'realitycheck' for CLI or 'realitycheck-api' for server"
