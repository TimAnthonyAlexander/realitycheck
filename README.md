# RealityCheck

A comprehensive startup idea analysis tool that provides evidence-based assessments of business viability using AI-powered research and structured analysis frameworks.

## Overview

RealityCheck analyzes startup ideas across multiple dimensions:
- **Market Analysis**: Competition, market stage, and positioning
- **Problem Validation**: Pain points and evidence of real user needs
- **Execution Barriers**: Regulatory, technical, and operational challenges
- **Risk Assessment**: Business risks with severity and likelihood ratings
- **Graveyard Analysis**: Learning from similar failed companies
- **Overall Verdict**: Comprehensive scoring and recommendations

The system uses OpenAI's API with web search capabilities to gather evidence, then applies structured analysis frameworks to generate actionable insights.

## Features

- 🔍 **Evidence-Based Analysis**: All insights backed by web research
- 📊 **Structured Scoring**: Consistent 0-100 scoring across dimensions
- 🚀 **REST API**: Programmatic access to analysis capabilities
- 💻 **CLI Tool**: Command-line interface for batch processing
- 📝 **Multiple Output Formats**: JSON, Markdown, and HTML reports
- 🗄️ **PostgreSQL Storage**: Persistent analysis history with full-text search
- ⚡ **Intelligent Caching**: LRU + database caching with deduplication
- 🔄 **Parallel Processing**: Concurrent analysis for optimal performance

## Prerequisites

- **Go 1.21+**
- **PostgreSQL 15+**
- **OpenAI API Key** (with access to GPT-4o and web search)

## Installation

### 1. Clone and Setup

```bash
git clone <repository-url>
cd realitycheck
go mod download
```

### 2. Database Setup

```bash
# Install PostgreSQL (macOS)
brew install postgresql
brew services start postgresql

# Create database
createdb realitycheck
```

### 3. Environment Configuration

Create a `.env` file or set environment variables:

```bash
# Required
export OPENAI_API_KEY="your-openai-api-key"

# Database
export DB_DSN="postgres://localhost/realitycheck?sslmode=disable"

# Optional (with defaults)
export HTTP_ADDR=":9444"
export OPENAI_RPS="2"
export OPENAI_BURST="4"
export CACHE_LRU_SIZE="4096"
export CACHE_TTL="24h"
export MAX_EVIDENCE_PER_QUERY="10"
export MAX_QUERIES="20"
export ANALYSIS_TIMEOUT="60s"
export BEARER_TOKEN=""  # Leave empty to disable auth
export LOG_LEVEL="info"
```

## Usage

### REST API

Start the API server:

```bash
go run cmd/api/main.go
```

#### Analyze a Startup Idea

```bash
curl -X POST http://localhost:9444/v1/analyze \
  -H "Content-Type: application/json" \
  -d '{
    "idea": {
      "title": "Loom",
      "one_liner": "Agentic coding assistant creating verifiable patches"
    },
    "options": {
      "max_evidence": 15,
      "location": {
        "country": "United States"
      }
    }
  }'
```

Response:
```json
{
  "analysis_id": "abc123...",
  "status": "completed"
}
```

#### Get Analysis Results

```bash
# JSON format
curl http://localhost:9444/v1/analyses/abc123...

# Markdown format
curl http://localhost:9444/v1/analyses/abc123....md

# HTML format
curl http://localhost:9444/v1/analyses/abc123....html
```

#### List Analyses

```bash
# List all analyses
curl http://localhost:9444/v1/analyses?limit=10&offset=0

# Search analyses
curl http://localhost:9444/v1/analyses?q=AI&limit=5
```

### CLI Tool

Analyze an idea directly from the command line:

```bash
# Basic analysis
go run cmd/cli/main.go \
  --title "TaskAI" \
  --one-liner "AI-powered task automation for busy professionals" \
  --out report.md

# Advanced options
go run cmd/cli/main.go \
  --title "EcoTrack" \
  --one-liner "Carbon footprint tracking for small businesses" \
  --category "climate-tech" \
  --location "Europe" \
  --format html \
  --out analysis.html \
  --timeout 120s \
  --max-evidence 25
```

## API Reference

### Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/v1/analyze` | Submit idea for analysis |
| `GET` | `/v1/analyses/{id}` | Get analysis (JSON) |
| `GET` | `/v1/analyses/{id}.md` | Get analysis (Markdown) |
| `GET` | `/v1/analyses/{id}.html` | Get analysis (HTML) |
| `GET` | `/v1/analyses` | List/search analyses |
| `DELETE` | `/v1/analyses/{id}` | Delete analysis |
| `GET` | `/v1/stats` | System statistics |
| `GET` | `/health` | Health check |

### Authentication

If `BEARER_TOKEN` is configured, include it in requests:

```bash
curl -H "Authorization: Bearer your-token" http://localhost:9444/v1/analyze
```

## Analysis Framework

### Scoring Dimensions

Each dimension is scored 0-100:

1. **Market (25% weight)**
   - Competition analysis
   - Market stage assessment
   - Positioning opportunities

2. **Problem (20% weight)**
   - Pain point validation
   - Problem urgency
   - User evidence

3. **Barriers (15% weight)**
   - Regulatory hurdles
   - Technical challenges
   - Distribution difficulties

4. **Execution (15% weight)**
   - Capital requirements
   - Talent availability
   - Complexity assessment

5. **Risks (15% weight)**
   - Business risks
   - Market risks
   - Technical risks

6. **Graveyard (10% weight)**
   - Failed competitor analysis
   - Lesson extraction
   - Pattern recognition

### Evidence Types

The system categorizes evidence sources:
- **News**: TechCrunch, VentureBeat, Reuters
- **Database**: Crunchbase, PitchBook
- **Regulatory**: SEC, FDA filings
- **Forum**: Reddit, Hacker News
- **Professional**: LinkedIn
- **Academic**: Research papers
- **And more...**

## Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   CLI / API     │────│   Orchestrator   │────│   Analyzers     │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                                │                        │
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Search        │────│   Evidence       │────│   Scoring       │
│   Planning      │    │   Normalization  │    │   System        │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                                │
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   OpenAI        │────│   Caching        │────│   PostgreSQL    │
│   Client        │    │   (LRU + DB)     │    │   Storage       │
└─────────────────┘    └──────────────────┘    └─────────────────┘
```

### Key Components

- **Orchestrator**: Coordinates the entire analysis pipeline
- **Search Planner**: Generates targeted research queries
- **Evidence Normalizer**: Deduplicates and quality-filters results
- **Analyzers**: Parallel processing of different analysis dimensions
- **Scoring System**: Consistent, weighted scoring methodology
- **Caching**: Multi-level caching with PostgreSQL persistence

## Development

### Building

```bash
# Build API server
go build -o bin/api cmd/api/main.go

# Build CLI tool
go build -o bin/cli cmd/cli/main.go
```

### Testing

```bash
# Run tests
go test ./...

# Test with coverage
go test -cover ./...
```

### Database Migrations

Migrations run automatically on startup. Manual migration:

```bash
# Connect to database and run migrations.sql
psql realitycheck < internal/schema/migrations.sql
```

## Configuration Reference

| Variable | Default | Description |
|----------|---------|-------------|
| `OPENAI_API_KEY` | Required | OpenAI API key |
| `DB_DSN` | `postgres://localhost/realitycheck?sslmode=disable` | PostgreSQL connection |
| `HTTP_ADDR` | `:9444` | HTTP server address |
| `OPENAI_RPS` | `2` | OpenAI requests per second |
| `OPENAI_BURST` | `4` | OpenAI burst capacity |
| `CACHE_LRU_SIZE` | `4096` | LRU cache size |
| `CACHE_TTL` | `24h` | Cache time-to-live |
| `MAX_EVIDENCE_PER_QUERY` | `10` | Evidence limit per analysis |
| `MAX_QUERIES` | `20` | Search query limit |
| `ANALYSIS_TIMEOUT` | `60s` | Analysis timeout |
| `BEARER_TOKEN` | Empty | API authentication token |
| `LOG_LEVEL` | `info` | Logging level |

## Deployment

### Docker (recommended approach for production)

```dockerfile
FROM golang:1.21-alpine AS builder
WORKDIR /app
COPY . .
RUN go build -o api cmd/api/main.go

FROM alpine:latest
RUN apk --no-cache add ca-certificates
WORKDIR /root/
COPY --from=builder /app/api .
CMD ["./api"]
```

### Health Monitoring

The API provides health check endpoints:

```bash
curl http://localhost:9444/health
```

## Limitations & Considerations

- **Rate Limits**: Respects OpenAI API rate limits (configurable)
- **Cost**: Each analysis uses multiple OpenAI API calls
- **Quality**: Analysis quality depends on available web evidence
- **Language**: Currently optimized for English content
- **Geographic**: Best results for US/Western markets

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make changes with tests
4. Submit a pull request

## License

MIT

## Support

For issues and questions:
- Create GitHub issues for bugs
- Use discussions for questions
- Check logs for debugging (`LOG_LEVEL=debug`)
