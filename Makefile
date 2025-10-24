# RWA Prime - Makefile
# Common development commands for convenience
#
# Usage:
#   make help          # Show this help message
#   make setup         # Initial project setup
#   make dev           # Start development environment
#   make test          # Run all tests

.PHONY: help setup dev test clean install lint format docker-up docker-down

# Default target
.DEFAULT_GOAL := help

# ============================================
# Help
# ============================================

help: ## Show this help message
	@echo "RWA Prime - Available Commands:"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'
	@echo ""

# ============================================
# Setup
# ============================================

setup: ## Initial project setup (run once)
	@echo "📦 Setting up RWA Prime project..."
	@cp .env.example .env || true
	@echo "✅ Created .env file from template"
	@echo "⚠️  Please edit .env and fill in your API keys"
	@$(MAKE) install
	@$(MAKE) docker-up
	@echo "✅ Setup complete!"

install: ## Install dependencies
	@echo "📦 Installing Python dependencies..."
	@pip install -r requirements.txt
	@pip install -r requirements-dev.txt
	@echo "📦 Installing Node dependencies..."
	@cd frontend && npm install
	@echo "✅ Dependencies installed"

install-pre-commit: ## Install pre-commit hooks
	@echo "🔧 Installing pre-commit hooks..."
	@pip install pre-commit
	@pre-commit install
	@echo "✅ Pre-commit hooks installed"

# ============================================
# Development
# ============================================

dev: ## Start development environment
	@echo "🚀 Starting development environment..."
	@$(MAKE) docker-up
	@echo "🔥 Starting backend (FastAPI)..."
	@uvicorn app.main:app --reload --host 0.0.0.0 --port 8000 &
	@echo "⚛️  Starting frontend (React)..."
	@cd frontend && npm run dev &
	@echo "✅ Development servers running:"
	@echo "   Backend:  http://localhost:8000"
	@echo "   Frontend: http://localhost:3000"
	@echo "   API Docs: http://localhost:8000/docs"

dev-backend: ## Start backend only
	@echo "🔥 Starting backend (FastAPI)..."
	@uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

dev-frontend: ## Start frontend only
	@echo "⚛️  Starting frontend (React)..."
	@cd frontend && npm run dev

# ============================================
# Docker
# ============================================

docker-up: ## Start Docker services (PostgreSQL, Redis, Kafka)
	@echo "🐳 Starting Docker services..."
	@docker-compose up -d
	@echo "✅ Docker services running"
	@docker-compose ps

docker-down: ## Stop Docker services
	@echo "🛑 Stopping Docker services..."
	@docker-compose down
	@echo "✅ Docker services stopped"

docker-logs: ## View Docker logs
	@docker-compose logs -f

docker-ps: ## List running Docker containers
	@docker-compose ps

docker-clean: ## Remove Docker volumes (WARNING: deletes data)
	@echo "⚠️  WARNING: This will delete all Docker volumes and data!"
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		docker-compose down -v; \
		echo "✅ Docker volumes removed"; \
	else \
		echo "❌ Cancelled"; \
	fi

# ============================================
# Database
# ============================================

db-migrate: ## Run database migrations
	@echo "🗄️  Running database migrations..."
	@alembic upgrade head
	@echo "✅ Migrations complete"

db-migrate-create: ## Create a new migration (usage: make db-migrate-create MSG="your message")
	@echo "📝 Creating new migration..."
	@alembic revision --autogenerate -m "$(MSG)"
	@echo "✅ Migration created"

db-reset: ## Reset database (WARNING: deletes all data)
	@echo "⚠️  WARNING: This will reset the database and delete all data!"
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		alembic downgrade base; \
		alembic upgrade head; \
		echo "✅ Database reset"; \
	else \
		echo "❌ Cancelled"; \
	fi

db-shell: ## Open PostgreSQL shell
	@docker exec -it rwa-prime-postgres psql -U postgres -d rwa_prime

# ============================================
# Testing
# ============================================

test: ## Run all tests
	@echo "🧪 Running tests..."
	@pytest tests/ -v --cov=app --cov-report=html --cov-report=term
	@echo "✅ Tests complete"
	@echo "📊 Coverage report: htmlcov/index.html"

test-unit: ## Run unit tests only
	@echo "🧪 Running unit tests..."
	@pytest tests/unit/ -v

test-integration: ## Run integration tests only
	@echo "🧪 Running integration tests..."
	@pytest tests/integration/ -v

test-e2e: ## Run end-to-end tests
	@echo "🧪 Running E2E tests..."
	@cd frontend && npm run test:e2e

test-watch: ## Run tests in watch mode
	@pytest tests/ -v --watch

test-coverage: ## Generate test coverage report
	@pytest tests/ --cov=app --cov-report=html --cov-report=term
	@open htmlcov/index.html || xdg-open htmlcov/index.html

# ============================================
# Code Quality
# ============================================

lint: ## Run linters
	@echo "🔍 Running linters..."
	@echo "Python (flake8):"
	@flake8 app/ tests/
	@echo "Python (pylint):"
	@pylint app/ tests/
	@echo "Python (mypy):"
	@mypy app/
	@echo "TypeScript (ESLint):"
	@cd frontend && npm run lint
	@echo "✅ Linting complete"

format: ## Format code
	@echo "✨ Formatting code..."
	@echo "Python (black):"
	@black app/ tests/
	@echo "Python (isort):"
	@isort app/ tests/
	@echo "TypeScript (prettier):"
	@cd frontend && npm run format
	@echo "✅ Formatting complete"

format-check: ## Check code formatting without changing files
	@echo "🔍 Checking code formatting..."
	@black --check app/ tests/
	@isort --check-only app/ tests/
	@cd frontend && npm run format:check

type-check: ## Run type checking
	@echo "🔍 Running type checks..."
	@mypy app/
	@cd frontend && npm run type-check
	@echo "✅ Type checking complete"

# ============================================
# Security
# ============================================

security-check: ## Run security checks
	@echo "🔒 Running security checks..."
	@echo "Python (safety):"
	@safety check
	@echo "Python (bandit):"
	@bandit -r app/
	@echo "Node (npm audit):"
	@cd frontend && npm audit
	@echo "✅ Security checks complete"

# ============================================
# Build
# ============================================

build-backend: ## Build backend Docker image
	@echo "🐳 Building backend Docker image..."
	@docker build -t rwa-prime-api:latest -f backend/Dockerfile backend/
	@echo "✅ Backend image built"

build-frontend: ## Build frontend Docker image
	@echo "🐳 Building frontend Docker image..."
	@docker build -t rwa-prime-frontend:latest -f frontend/Dockerfile frontend/
	@echo "✅ Frontend image built"

build-all: build-backend build-frontend ## Build all Docker images

# ============================================
# ML Models
# ============================================

train-models: ## Train ML models
	@echo "🤖 Training ML models..."
	@python -m app.ml_service.train
	@echo "✅ Models trained"

predict: ## Run prediction (usage: make predict ASSET=USDC)
	@echo "🔮 Running prediction for $(ASSET)..."
	@python -m app.ml_service.predict --asset $(ASSET)

# ============================================
# Data
# ============================================

ingest-data: ## Ingest data from external APIs
	@echo "📥 Ingesting data..."
	@python -m app.data_ingestion.run
	@echo "✅ Data ingestion complete"

backfill-data: ## Backfill historical data (usage: make backfill-data DAYS=365)
	@echo "📥 Backfilling $(DAYS) days of data..."
	@python -m app.data_ingestion.backfill --days $(DAYS)
	@echo "✅ Backfill complete"

# ============================================
# Deployment
# ============================================

deploy-dev: ## Deploy to development environment
	@echo "🚀 Deploying to development..."
	@kubectl apply -f infrastructure/kubernetes/dev/
	@echo "✅ Deployed to development"

deploy-staging: ## Deploy to staging environment
	@echo "🚀 Deploying to staging..."
	@kubectl apply -f infrastructure/kubernetes/staging/
	@echo "✅ Deployed to staging"

deploy-prod: ## Deploy to production environment
	@echo "⚠️  WARNING: Deploying to PRODUCTION!"
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		kubectl apply -f infrastructure/kubernetes/production/; \
		echo "✅ Deployed to production"; \
	else \
		echo "❌ Cancelled"; \
	fi

# ============================================
# Cleanup
# ============================================

clean: ## Clean temporary files and caches
	@echo "🧹 Cleaning temporary files..."
	@find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	@find . -type d -name "*.egg-info" -exec rm -rf {} + 2>/dev/null || true
	@find . -type d -name ".pytest_cache" -exec rm -rf {} + 2>/dev/null || true
	@find . -type d -name ".mypy_cache" -exec rm -rf {} + 2>/dev/null || true
	@find . -type f -name "*.pyc" -delete 2>/dev/null || true
	@find . -type f -name "*.pyo" -delete 2>/dev/null || true
	@find . -type f -name "*.log" -delete 2>/dev/null || true
	@rm -rf htmlcov/ .coverage 2>/dev/null || true
	@rm -rf dist/ build/ 2>/dev/null || true
	@cd frontend && rm -rf node_modules/.cache 2>/dev/null || true
	@echo "✅ Cleanup complete"

clean-all: clean docker-clean ## Clean everything (including Docker volumes)

# ============================================
# Git
# ============================================

git-hooks: install-pre-commit ## Install git hooks

git-status: ## Show git status in a clean format
	@git status -sb

git-log: ## Show git log in a clean format
	@git log --oneline --graph --all --decorate -20

# ============================================
# Documentation
# ============================================

docs-serve: ## Serve documentation locally
	@echo "📚 Serving documentation..."
	@python -m http.server 8000 --directory .
	@echo "📖 Documentation available at http://localhost:8000"

docs-validate: ## Validate documentation
	@echo "✅ Running documentation validation..."
	@.github/workflows/scripts/validate-docs.sh

# ============================================
# Monitoring
# ============================================

logs: ## View application logs
	@tail -f logs/app.log

stats: ## Show system stats
	@echo "💻 System Stats:"
	@echo ""
	@echo "Docker:"
	@docker stats --no-stream
	@echo ""
	@echo "Database Size:"
	@docker exec rwa-prime-postgres psql -U postgres -d rwa_prime -c "SELECT pg_size_pretty(pg_database_size('rwa_prime'));"

# ============================================
# CI/CD
# ============================================

ci: lint format-check type-check test security-check ## Run all CI checks locally

ci-fast: lint test-unit ## Run fast CI checks

# ============================================
# Utilities
# ============================================

shell: ## Open Python shell with app context
	@python -m IPython

generate-secrets: ## Generate secret keys
	@echo "🔑 Generating secret keys..."
	@echo "JWT_SECRET_KEY=$(shell openssl rand -hex 32)"
	@echo "CSRF_SECRET_KEY=$(shell openssl rand -hex 32)"
	@echo "SESSION_SECRET_KEY=$(shell openssl rand -hex 32)"
	@echo ""
	@echo "Copy these to your .env file"

generate-jwt-keys: ## Generate RSA keys for JWT
	@echo "🔑 Generating RSA keys for JWT..."
	@mkdir -p secrets
	@openssl genrsa -out secrets/jwt_private_key.pem 2048
	@openssl rsa -in secrets/jwt_private_key.pem -pubout -out secrets/jwt_public_key.pem
	@echo "✅ Keys generated in secrets/ directory"
	@echo "⚠️  Add secrets/ to .gitignore if not already there"
