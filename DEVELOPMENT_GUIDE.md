# DEVELOPMENT_GUIDE.md

## Table of Contents
1. [Getting Started](#getting-started)
2. [Development Environment Setup](#development-environment-setup)
3. [Project Structure](#project-structure)
4. [Development Workflow](#development-workflow)
5. [Code Style and Conventions](#code-style-and-conventions)
6. [Testing Strategy](#testing-strategy)
7. [Build and Deployment](#build-and-deployment)
8. [Common Development Tasks](#common-development-tasks)
9. [Troubleshooting](#troubleshooting)

## Getting Started

### Prerequisites

#### Required Software
- **Python 3.11+**
- **Node.js 18+ and npm/yarn**
- **Docker 20+**
- **Docker Compose 2+**
- **Git**
- **PostgreSQL 15+ client tools**

#### Recommended IDE/Tools
- **VS Code** with extensions:
  - Python (Microsoft)
  - ESLint
  - Prettier
  - Docker
  - Kubernetes
  - GitLens
- **Postman** or **Insomnia** for API testing
- **DBeaver** or **pgAdmin** for database management

#### Cloud Accounts (for full deployment)
- AWS account with appropriate IAM permissions
- Docker Hub account (for container registry)
- GitHub account (for version control)

### Repository Structure

```
RWA_Prime/
├── backend/                    # Backend services
│   ├── api/                   # FastAPI application
│   ├── ml_service/            # ML/NLP services
│   ├── data_ingestion/        # Data ingestion microservices
│   ├── common/                # Shared utilities
│   └── tests/                 # Backend tests
├── frontend/                   # React frontend application
│   ├── src/
│   ├── public/
│   └── tests/
├── infrastructure/             # IaC and deployment configs
│   ├── terraform/             # Terraform configs
│   ├── kubernetes/            # K8s manifests
│   └── docker/                # Dockerfiles
├── data_processing/            # Spark/data pipeline code
│   ├── spark_jobs/
│   └── airflow_dags/
├── scripts/                    # Utility scripts
├── docs/                       # Additional documentation
├── .github/                    # GitHub Actions workflows
├── docker-compose.yml          # Local development stack
├── .env.example                # Environment variables template
└── README.md
```

## Development Environment Setup

### 1. Clone the Repository

```bash
git clone https://github.com/your-org/RWA_Prime.git
cd RWA_Prime
```

### 2. Environment Configuration

Create a `.env` file from the template:

```bash
cp .env.example .env
```

Edit `.env` and configure:

```env
# Database
DATABASE_URL=postgresql://rwa_user:rwa_pass@localhost:5432/rwa_prime_dev
TIMESCALE_URL=postgresql://rwa_user:rwa_pass@localhost:5432/rwa_prime_timeseries

# Redis
REDIS_URL=redis://localhost:6379/0

# Kafka
KAFKA_BOOTSTRAP_SERVERS=localhost:9092

# External API Keys (get from respective providers)
COINAPI_KEY=your_coinapi_key_here
AMBERDATA_KEY=your_amberdata_key_here
BITQUERY_KEY=your_bitquery_key_here
NEWSAPI_KEY=your_newsapi_key_here
TRADING_ECONOMICS_KEY=your_trading_economics_key_here

# JWT Secret (generate with: openssl rand -hex 32)
JWT_SECRET=your_jwt_secret_here
JWT_ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=15

# AWS (for local S3 emulation, use LocalStack)
AWS_ACCESS_KEY_ID=test
AWS_SECRET_ACCESS_KEY=test
AWS_REGION=us-east-1
S3_BUCKET_NAME=rwa-prime-dev

# Frontend
REACT_APP_API_URL=http://localhost:8000
REACT_APP_WS_URL=ws://localhost:8000/ws
```

### 3. Start Local Development Stack

Use Docker Compose to start all required services:

```bash
docker-compose up -d
```

This starts:
- PostgreSQL (port 5432)
- TimescaleDB (port 5433)
- Redis (port 6379)
- Kafka + Zookeeper (ports 9092, 2181)
- LocalStack (AWS services emulation, port 4566)

Verify all services are running:

```bash
docker-compose ps
```

### 4. Backend Setup

```bash
cd backend

# Create Python virtual environment
python3.11 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements-dev.txt

# Run database migrations
alembic upgrade head

# Seed database with sample data (optional)
python scripts/seed_database.py

# Start the FastAPI development server
uvicorn api.main:app --reload --host 0.0.0.0 --port 8000
```

Backend API will be available at `http://localhost:8000`
API docs (Swagger): `http://localhost:8000/docs`

### 5. Frontend Setup

```bash
cd frontend

# Install dependencies
npm install
# or
yarn install

# Start development server
npm run dev
# or
yarn dev
```

Frontend will be available at `http://localhost:3000`

### 6. Start Data Ingestion Services (Optional for development)

```bash
cd backend/data_ingestion

# Start price data ingestion
python price_service.py &

# Start on-chain data ingestion
python onchain_service.py &

# Start news/sentiment ingestion
python news_service.py &
```

### 7. Start ML Service (Optional for development)

```bash
cd backend/ml_service

# Ensure models are downloaded/initialized
python init_models.py

# Start ML inference server
python ml_server.py
```

## Project Structure

### Backend Structure

```
backend/
├── api/                        # FastAPI application
│   ├── __init__.py
│   ├── main.py                # Application entry point
│   ├── dependencies.py        # Dependency injection
│   ├── routes/                # API route modules
│   │   ├── auth.py
│   │   ├── assets.py
│   │   ├── portfolios.py
│   │   ├── predictions.py
│   │   └── alerts.py
│   ├── models/                # Pydantic models (schemas)
│   │   ├── user.py
│   │   ├── asset.py
│   │   └── ...
│   ├── crud/                  # Database operations
│   │   ├── user.py
│   │   ├── asset.py
│   │   └── ...
│   ├── database/              # Database configuration
│   │   ├── session.py
│   │   └── base.py
│   └── core/                  # Core functionality
│       ├── auth.py            # Authentication logic
│       ├── config.py          # Settings management
│       └── security.py        # Security utilities
├── ml_service/                # Machine Learning services
│   ├── models/
│   │   ├── lstm_model.py
│   │   ├── arima_model.py
│   │   └── ensemble.py
│   ├── training/
│   │   ├── train_lstm.py
│   │   └── train_arima.py
│   ├── inference/
│   │   └── predictor.py
│   └── evaluation/
│       └── backtester.py
├── data_ingestion/            # Data ingestion microservices
│   ├── price_service.py
│   ├── onchain_service.py
│   ├── economic_service.py
│   └── news_service.py
├── common/                    # Shared utilities
│   ├── kafka_producer.py
│   ├── s3_client.py
│   ├── logging_config.py
│   └── utils.py
├── alembic/                   # Database migrations
│   ├── versions/
│   └── env.py
├── tests/                     # Test suites
│   ├── unit/
│   ├── integration/
│   └── e2e/
├── requirements.txt           # Production dependencies
├── requirements-dev.txt       # Development dependencies
└── pytest.ini                 # Pytest configuration
```

### Frontend Structure

```
frontend/
├── src/
│   ├── components/            # Reusable React components
│   │   ├── common/           # Generic components
│   │   │   ├── Button.tsx
│   │   │   ├── Card.tsx
│   │   │   └── Modal.tsx
│   │   ├── charts/           # Chart components
│   │   │   ├── PredictionChart.tsx
│   │   │   ├── RiskGauge.tsx
│   │   │   └── PortfolioChart.tsx
│   │   └── widgets/          # Dashboard widgets
│   │       ├── MarketOverview.tsx
│   │       ├── PortfolioSummary.tsx
│   │       └── AlertsList.tsx
│   ├── pages/                # Page components
│   │   ├── Dashboard.tsx
│   │   ├── AssetDetail.tsx
│   │   ├── Portfolio.tsx
│   │   ├── Screener.tsx
│   │   └── Settings.tsx
│   ├── services/             # API service layer
│   │   ├── api.ts            # Axios instance & config
│   │   ├── auth.service.ts
│   │   ├── asset.service.ts
│   │   └── portfolio.service.ts
│   ├── store/                # Redux store (or Zustand)
│   │   ├── index.ts
│   │   ├── slices/
│   │   │   ├── authSlice.ts
│   │   │   ├── assetSlice.ts
│   │   │   └── portfolioSlice.ts
│   │   └── hooks.ts
│   ├── hooks/                # Custom React hooks
│   │   ├── useWebSocket.ts
│   │   ├── useAuth.ts
│   │   └── useAssets.ts
│   ├── utils/                # Utility functions
│   │   ├── formatting.ts
│   │   ├── validation.ts
│   │   └── constants.ts
│   ├── types/                # TypeScript type definitions
│   │   ├── asset.types.ts
│   │   ├── user.types.ts
│   │   └── api.types.ts
│   ├── styles/               # Global styles
│   │   └── globals.css
│   ├── App.tsx               # Root component
│   ├── main.tsx              # Entry point
│   └── vite-env.d.ts
├── public/                   # Static assets
├── tests/                    # Frontend tests
├── package.json
├── tsconfig.json
├── vite.config.ts
└── tailwind.config.js
```

## Development Workflow

### Git Workflow

We follow **Git Flow** branching strategy:

```
main (production)
  └── develop (integration)
       ├── feature/add-portfolio-tracker
       ├── feature/implement-lstm-model
       ├── bugfix/fix-auth-token-expiry
       └── release/v1.0.0
```

#### Branch Naming Convention
- `feature/short-description` - New features
- `bugfix/short-description` - Bug fixes
- `hotfix/short-description` - Critical production fixes
- `release/vX.Y.Z` - Release preparation
- `chore/short-description` - Maintenance tasks

#### Workflow Steps

1. **Create feature branch**:
   ```bash
   git checkout develop
   git pull origin develop
   git checkout -b feature/your-feature-name
   ```

2. **Develop and commit**:
   ```bash
   git add .
   git commit -m "feat: add portfolio tracker widget"
   ```

3. **Push and create PR**:
   ```bash
   git push origin feature/your-feature-name
   ```
   Then create Pull Request on GitHub targeting `develop`

4. **Code review** → Approval → **Merge**

### Commit Message Convention

Follow **Conventional Commits**:

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types**:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, no logic change)
- `refactor`: Code refactoring
- `perf`: Performance improvements
- `test`: Adding/updating tests
- `chore`: Build process, tooling changes

**Examples**:
```
feat(api): add endpoint for risk score calculation
fix(frontend): resolve chart rendering issue on mobile
docs: update API reference for /predictions endpoint
refactor(ml): optimize LSTM model training pipeline
```

## Code Style and Conventions

### Python (Backend)

**Style Guide**: PEP 8 + Black formatting

#### Key Conventions:
- **Formatting**: Use `black` for auto-formatting
- **Linting**: Use `flake8` and `pylint`
- **Type Hints**: Use type hints for all function signatures
- **Docstrings**: Use Google-style docstrings

```python
from typing import List, Optional
from pydantic import BaseModel

def get_asset_predictions(
    asset_id: str,
    forecast_horizon: int = 7,
    model_version: Optional[str] = None
) -> List[PredictionOutput]:
    """
    Fetch predictions for a given asset.

    Args:
        asset_id: Unique identifier for the asset
        forecast_horizon: Number of days to forecast (7 or 30)
        model_version: Specific model version to use (default: latest)

    Returns:
        List of prediction outputs with confidence intervals

    Raises:
        AssetNotFoundError: If asset_id doesn't exist
        ModelNotAvailableError: If requested model version not found
    """
    # Implementation
    pass
```

#### Pre-commit Hooks:
```bash
# Install pre-commit
pip install pre-commit
pre-commit install

# .pre-commit-config.yaml will run:
# - black (formatting)
# - flake8 (linting)
# - isort (import sorting)
# - mypy (type checking)
```

### TypeScript/React (Frontend)

**Style Guide**: Airbnb TypeScript Style Guide + Prettier

#### Key Conventions:
- **Formatting**: Use `prettier`
- **Linting**: Use `eslint` with TypeScript config
- **Components**: Use functional components with hooks
- **Props**: Define explicit interfaces for all props

```typescript
interface AssetCardProps {
  asset: Asset;
  showRiskScore?: boolean;
  onSelect?: (assetId: string) => void;
}

export const AssetCard: React.FC<AssetCardProps> = ({
  asset,
  showRiskScore = true,
  onSelect,
}) => {
  const handleClick = () => {
    if (onSelect) {
      onSelect(asset.id);
    }
  };

  return (
    <div className="asset-card" onClick={handleClick}>
      <h3>{asset.name}</h3>
      <p>{asset.symbol}</p>
      {showRiskScore && <RiskGauge score={asset.riskScore} />}
    </div>
  );
};
```

#### ESLint + Prettier Configuration:
```bash
# Install
npm install --save-dev eslint prettier eslint-config-prettier

# Configuration is in .eslintrc.json and .prettierrc
```

### SQL

- Use lowercase for SQL keywords: `select`, `from`, `where`
- Use snake_case for table and column names
- Always use parameterized queries (via SQLAlchemy ORM)
- Add comments for complex queries

## Testing Strategy

See [TESTING_GUIDE.md](./TESTING_GUIDE.md) for comprehensive testing documentation.

### Quick Testing Commands

#### Backend Tests
```bash
cd backend

# Run all tests
pytest

# Run with coverage
pytest --cov=api --cov=ml_service --cov-report=html

# Run specific test file
pytest tests/unit/test_auth.py

# Run tests matching pattern
pytest -k "test_prediction"
```

#### Frontend Tests
```bash
cd frontend

# Run all tests
npm test

# Run with coverage
npm test -- --coverage

# Run in watch mode
npm test -- --watch
```

### Test Coverage Requirements
- **Minimum coverage**: 80% for all new code
- **Critical paths**: 95%+ coverage (authentication, payment processing, risk calculations)

## Build and Deployment

### Local Build

#### Backend Docker Image
```bash
cd backend
docker build -t rwa-prime-api:local -f ../infrastructure/docker/Dockerfile.api .
```

#### Frontend Build
```bash
cd frontend
npm run build
# Output in dist/ directory
```

### Deploy to Development Environment

```bash
# Ensure kubectl is configured for dev cluster
kubectl config use-context rwa-prime-dev

# Deploy via Kubernetes manifests
kubectl apply -f infrastructure/kubernetes/dev/

# Or use Helm (if Helm charts are configured)
helm upgrade --install rwa-prime ./infrastructure/helm/rwa-prime \
  --namespace rwa-dev \
  --values infrastructure/helm/values-dev.yaml
```

### Deploy to Production

Production deployments are automated via GitHub Actions on merge to `main`:

1. Merge to `main` triggers CI/CD pipeline
2. Runs all tests
3. Builds Docker images
4. Pushes to container registry
5. Deploys to staging environment
6. Runs smoke tests
7. Requires manual approval
8. Deploys to production (blue-green deployment)

## Common Development Tasks

### 1. Add a New API Endpoint

```bash
cd backend/api

# 1. Define Pydantic model in models/
# Example: models/new_feature.py

# 2. Create database CRUD operations in crud/
# Example: crud/new_feature.py

# 3. Add route handler in routes/
# Example: routes/new_feature.py

# 4. Register route in main.py
# Add: app.include_router(new_feature.router, prefix="/api/v1/new_feature", tags=["new_feature"])

# 5. Write tests in tests/unit/ and tests/integration/

# 6. Update API documentation (if needed)
```

### 2. Add a New Database Table

```bash
cd backend

# 1. Define SQLAlchemy model in api/database/models.py
# Example: Add Asset class inheriting from Base

# 2. Create Alembic migration
alembic revision --autogenerate -m "Add new_table"

# 3. Review generated migration in alembic/versions/

# 4. Apply migration
alembic upgrade head

# 5. Update CRUD operations and API routes
```

### 3. Train/Update ML Model

```bash
cd backend/ml_service

# 1. Prepare training data
python scripts/prepare_training_data.py --asset-class tokenized_treasury --days 365

# 2. Train LSTM model
python training/train_lstm.py --config configs/lstm_config.json --output models/lstm_v2.pth

# 3. Evaluate model
python evaluation/backtester.py --model models/lstm_v2.pth --test-data data/test_set.csv

# 4. If performance is good, deploy to staging
python scripts/deploy_model.py --model lstm_v2.pth --environment staging

# 5. Monitor performance, then promote to production
python scripts/deploy_model.py --model lstm_v2.pth --environment production
```

### 4. Add a New React Component

```bash
cd frontend/src/components

# 1. Create component file
# Example: components/NewWidget.tsx

# 2. Write component with TypeScript + props interface

# 3. Add Storybook story (if using Storybook)
# Example: components/NewWidget.stories.tsx

# 4. Write unit tests
# Example: __tests__/NewWidget.test.tsx

# 5. Export from index.ts for easy imports
```

### 5. Debug a Data Ingestion Issue

```bash
# 1. Check Kafka topics for messages
docker exec -it rwa-prime-kafka kafka-console-consumer \
  --bootstrap-server localhost:9092 \
  --topic price-data-raw \
  --from-beginning

# 2. Check ingestion service logs
docker logs -f data-ingestion-price

# 3. Check Spark streaming job status
kubectl logs -f spark-driver-pod -n rwa-prime

# 4. Query raw data in S3
aws s3 ls s3://rwa-prime-dev/bronze/price-data/2025/10/23/

# 5. Verify processed data in database
psql $DATABASE_URL -c "SELECT COUNT(*) FROM price_data WHERE time > NOW() - INTERVAL '1 hour';"
```

## Troubleshooting

### Common Issues

#### 1. Database Connection Errors

**Symptom**: `could not connect to server: Connection refused`

**Solution**:
```bash
# Check if PostgreSQL is running
docker-compose ps | grep postgres

# Restart PostgreSQL
docker-compose restart postgres

# Verify connection
psql $DATABASE_URL -c "SELECT 1;"
```

#### 2. Kafka Message Not Being Consumed

**Symptom**: Data not flowing from ingestion to database

**Solution**:
```bash
# List consumer groups
docker exec rwa-prime-kafka kafka-consumer-groups --bootstrap-server localhost:9092 --list

# Check consumer lag
docker exec rwa-prime-kafka kafka-consumer-groups \
  --bootstrap-server localhost:9092 \
  --group spark-consumer-group \
  --describe

# Reset consumer offset (if needed)
docker exec rwa-prime-kafka kafka-consumer-groups \
  --bootstrap-server localhost:9092 \
  --group spark-consumer-group \
  --topic price-data-raw \
  --reset-offsets --to-earliest \
  --execute
```

#### 3. Frontend Not Connecting to Backend API

**Symptom**: API calls fail with CORS error or timeout

**Solution**:
```bash
# Check backend is running
curl http://localhost:8000/health

# Verify CORS configuration in backend/api/main.py
# Ensure REACT_APP_API_URL in frontend/.env is correct

# Check browser console for exact error
# May need to clear browser cache
```

#### 4. ML Model Not Loading

**Symptom**: `FileNotFoundError: model file not found`

**Solution**:
```bash
# Check if model file exists
ls -lh backend/ml_service/models/

# Download pre-trained model (if available)
python backend/ml_service/scripts/download_models.py

# Or train a new model
python backend/ml_service/training/train_lstm.py --quick-test
```

### Getting Help

- **Slack**: #rwa-prime-dev channel
- **GitHub Issues**: Tag with `help-wanted` or `question`
- **Documentation**: Check [docs/](./docs/) folder
- **Email**: dev-team@rwa-prime.com

---

**Next Steps**: After setup, see [TASKS_AND_TODO.md](./TASKS_AND_TODO.md) for current development priorities.

**Related Documentation**:
- [PROJECT_CONTEXT.md](./PROJECT_CONTEXT.md)
- [ARCHITECTURE.md](./ARCHITECTURE.md)
- [TESTING_GUIDE.md](./TESTING_GUIDE.md)
- [API_REFERENCE.md](./API_REFERENCE.md)
