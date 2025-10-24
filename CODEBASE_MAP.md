# CODEBASE_MAP.md

## Overview

This document provides a detailed file-by-file breakdown of the RWA-Prime codebase. Since this is a **pre-development project**, this map describes the intended structure once development begins.

## Current Project State

### Existing Files

```
RWA_Prime/
├── PRD.md                     # Product Requirements Document
├── PRD.docx                   # Original PRD (Word format)
├── PRD.txt                    # Text version of PRD
├── Research.md                # Market Research & Technical Blueprint
├── Research.docx              # Original Research (Word format)
├── Research.txt               # Text version of Research
├── PROJECT_CONTEXT.md         # Project overview and context
├── ARCHITECTURE.md            # System architecture documentation
├── DEVELOPMENT_GUIDE.md       # Development setup and workflow
├── CODEBASE_MAP.md           # This file
├── TASKS_AND_TODO.md         # Development tasks and roadmap
├── API_REFERENCE.md          # API documentation
├── DEPENDENCIES.md           # Dependencies and versions
├── TESTING_GUIDE.md          # Testing strategy and guidelines
└── CLAUDE_INSTRUCTIONS.md    # AI development assistant guidelines
```

## Planned Directory Structure

When development begins, the codebase will follow this structure:

### Root Level

| File/Directory | Purpose | Key Contents |
|---|---|---|
| `.github/` | GitHub configurations | Workflows, issue templates, PR templates |
| `backend/` | All backend services | API, ML, data ingestion |
| `frontend/` | Frontend React application | UI components, pages, services |
| `infrastructure/` | Infrastructure as Code | Terraform, K8s manifests, Dockerfiles |
| `data_processing/` | Data pipeline code | Spark jobs, Airflow DAGs |
| `scripts/` | Utility scripts | Database seeding, deployment helpers |
| `docs/` | Additional documentation | Diagrams, design docs, ADRs |
| `docker-compose.yml` | Local dev environment | Services: Postgres, Redis, Kafka |
| `.env.example` | Environment variables template | API keys, DB URLs, secrets |
| `README.md` | Project README | Quick start, overview |
| `.gitignore` | Git ignore patterns | Python, Node, IDE files |

## Backend Structure (`backend/`)

### Entry Points

| File | Purpose | Key Functions |
|---|---|---|
| `api/main.py` | FastAPI application entry | App initialization, middleware, route registration |
| `ml_service/ml_server.py` | ML inference server | Model loading, prediction endpoints |
| `data_ingestion/price_service.py` | Price data ingestion | CoinAPI connection, Kafka production |
| `data_ingestion/onchain_service.py` | On-chain data ingestion | Amberdata/Bitquery, event streaming |
| `data_ingestion/economic_service.py` | Economic data ingestion | Trading Economics API |
| `data_ingestion/news_service.py` | News/sentiment ingestion | NewsAPI.ai, sentiment preprocessing |

### API Module (`backend/api/`)

#### Core Files

| File | Purpose | Dependencies |
|---|---|---|
| `main.py` | Application entry point | FastAPI, routes, middleware, CORS |
| `dependencies.py` | Dependency injection | Database sessions, auth, current user |
| `database/session.py` | Database connection management | SQLAlchemy engine, session factory |
| `database/base.py` | SQLAlchemy base class | Declarative base for models |
| `core/config.py` | Settings/configuration | Pydantic BaseSettings, env variables |
| `core/auth.py` | Authentication logic | JWT creation/validation, password hashing |
| `core/security.py` | Security utilities | TOTP verification, rate limiting |

#### Routes (`backend/api/routes/`)

| File | Endpoints | Purpose |
|---|---|---|
| `auth.py` | `/auth/login`, `/auth/register`, `/auth/verify-2fa` | User authentication |
| `assets.py` | `/assets`, `/assets/{id}`, `/assets/screener` | Asset data and search |
| `portfolios.py` | `/portfolio`, `/portfolio/sync`, `/portfolio/transactions` | Portfolio management |
| `predictions.py` | `/predictions/{asset_id}`, `/predictions/batch` | ML predictions retrieval |
| `alerts.py` | `/alerts`, `/alerts/{id}`, `/alerts/test` | Alert configuration |
| `risk.py` | `/risk/{asset_id}`, `/risk/breakdown/{asset_id}` | Risk scores and breakdown |
| `reports.py` | `/reports/asset/{id}`, `/reports/portfolio` | PDF report generation |
| `admin.py` | `/admin/users`, `/admin/system-health` | Admin operations |

#### Models (`backend/api/models/`)

Pydantic schemas for request/response validation:

| File | Schemas | Purpose |
|---|---|---|
| `user.py` | `UserCreate`, `UserLogin`, `UserResponse`, `Token` | User data structures |
| `asset.py` | `Asset`, `AssetDetail`, `AssetScreener` | Asset representations |
| `portfolio.py` | `PortfolioItem`, `PortfolioSummary`, `Transaction` | Portfolio data |
| `prediction.py` | `PredictionInput`, `PredictionOutput`, `ConfidenceInterval` | Prediction structures |
| `alert.py` | `AlertCreate`, `AlertCondition`, `AlertResponse` | Alert configurations |
| `risk.py` | `RiskScore`, `RiskBreakdown` | Risk assessment data |

#### CRUD (`backend/api/crud/`)

Database operations (Create, Read, Update, Delete):

| File | Operations | Tables Affected |
|---|---|---|
| `user.py` | `create_user()`, `get_user_by_email()`, `update_user()` | `users` |
| `asset.py` | `get_asset()`, `list_assets()`, `search_assets()` | `assets` |
| `portfolio.py` | `add_to_portfolio()`, `get_portfolio()`, `calculate_pnl()` | `portfolios`, `transactions` |
| `prediction.py` | `get_latest_prediction()`, `store_prediction()` | `predictions` |
| `alert.py` | `create_alert()`, `check_alert_conditions()` | `alerts`, `alert_history` |

### ML Service (`backend/ml_service/`)

#### Models (`backend/ml_service/models/`)

| File | Model Type | Purpose |
|---|---|---|
| `lstm_model.py` | LSTM Neural Network | Long-term price prediction, non-linear patterns |
| `arima_model.py` | ARIMA Statistical Model | Short-term prediction, trend/seasonality |
| `ensemble.py` | Ensemble Model | Combines LSTM + ARIMA with weighted average |
| `sentiment_model.py` | BERT NLP Model | Financial news sentiment classification |
| `risk_calculator.py` | Rule-based + ML | Composite risk score calculation |

#### Training (`backend/ml_service/training/`)

| File | Purpose | Output |
|---|---|---|
| `train_lstm.py` | Train LSTM on historical data | Model weights (.pth file) |
| `train_arima.py` | Fit ARIMA model | Model parameters (pickle) |
| `train_sentiment.py` | Fine-tune BERT on financial corpus | Fine-tuned model |
| `feature_engineering.py` | Create features for training | Feature pipeline |
| `data_loader.py` | Load and preprocess training data | PyTorch DataLoader |

#### Inference (`backend/ml_service/inference/`)

| File | Purpose | Input → Output |
|---|---|---|
| `predictor.py` | Load models and run predictions | Asset features → Price prediction |
| `batch_predictor.py` | Predict for multiple assets | Asset list → Predictions |
| `risk_engine.py` | Calculate risk scores | Asset data → Risk scores |
| `explainer.py` | Generate XAI insights | Prediction → Key drivers explanation |

#### Evaluation (`backend/ml_service/evaluation/`)

| File | Purpose | Metrics |
|---|---|---|
| `backtester.py` | Backtest trading strategy | Sharpe ratio, max drawdown, ROI |
| `cross_validator.py` | Time-series cross-validation | MAE, RMSE, MAPE |
| `bias_detector.py` | Detect optimization/survivorship bias | Bias metrics, warnings |
| `performance_monitor.py` | Monitor live model performance | Prediction accuracy over time |

### Data Ingestion (`backend/data_ingestion/`)

| File | Data Source | Output (Kafka Topic) |
|---|---|---|
| `price_service.py` | CoinAPI, FMP, Finazon | `price-data-raw` |
| `onchain_service.py` | Amberdata, Bitquery | `onchain-data-raw` |
| `economic_service.py` | Trading Economics, World Bank | `economic-data-raw` |
| `news_service.py` | NewsAPI.ai, Tradefeeds | `news-sentiment-raw` |
| `rwa_specific_service.py` | RWA.io API | `rwa-fundamentals-raw` |
| `kafka_producer.py` | Shared Kafka producer utility | - |
| `api_clients/` | Wrapper classes for external APIs | - |

### Common Utilities (`backend/common/`)

| File | Purpose | Used By |
|---|---|---|
| `kafka_producer.py` | Kafka message production | All ingestion services |
| `s3_client.py` | AWS S3 operations | Data pipeline, report generation |
| `logging_config.py` | Structured logging setup | All services |
| `utils.py` | Generic helper functions | Various modules |
| `constants.py` | Application constants | Enums, magic numbers |
| `exceptions.py` | Custom exception classes | Error handling |

### Tests (`backend/tests/`)

| Directory | Test Type | Tools |
|---|---|---|
| `unit/` | Unit tests for individual functions | pytest, unittest.mock |
| `integration/` | Integration tests (DB, Kafka) | pytest, testcontainers |
| `e2e/` | End-to-end API tests | pytest, requests |
| `fixtures/` | Shared test fixtures | pytest fixtures |
| `conftest.py` | Pytest configuration | - |

## Frontend Structure (`frontend/`)

### Entry Point

| File | Purpose |
|---|---|
| `src/main.tsx` | Application entry, ReactDOM render |
| `src/App.tsx` | Root component, routing setup |
| `src/vite-env.d.ts` | TypeScript environment definitions |

### Pages (`frontend/src/pages/`)

| File | Route | Purpose |
|---|---|---|
| `Dashboard.tsx` | `/` | Main dashboard with widgets |
| `AssetDetail.tsx` | `/assets/:id` | Detailed asset view |
| `Screener.tsx` | `/screener` | Asset discovery and filtering |
| `Portfolio.tsx` | `/portfolio` | Portfolio tracking |
| `Alerts.tsx` | `/alerts` | Alert management |
| `Compare.tsx` | `/compare` | Side-by-side asset comparison |
| `Settings.tsx` | `/settings` | User settings, API keys |
| `Login.tsx` | `/login` | Authentication |
| `Register.tsx` | `/register` | User registration |

### Components (`frontend/src/components/`)

#### Common (`frontend/src/components/common/`)

| File | Purpose | Props |
|---|---|---|
| `Button.tsx` | Reusable button | `variant`, `size`, `onClick`, `disabled` |
| `Card.tsx` | Container card | `title`, `children`, `className` |
| `Modal.tsx` | Modal dialog | `isOpen`, `onClose`, `title`, `children` |
| `Input.tsx` | Form input | `type`, `value`, `onChange`, `validation` |
| `Select.tsx` | Dropdown select | `options`, `value`, `onChange` |
| `Table.tsx` | Data table | `columns`, `data`, `onSort`, `onFilter` |
| `Spinner.tsx` | Loading indicator | `size`, `color` |
| `Toast.tsx` | Notification toast | `message`, `type`, `duration` |

#### Charts (`frontend/src/components/charts/`)

| File | Purpose | Library |
|---|---|---|
| `PredictionChart.tsx` | Price + prediction visualization | D3.js |
| `RiskGauge.tsx` | Risk score gauge | D3.js (arc diagram) |
| `PortfolioChart.tsx` | Portfolio allocation pie chart | Recharts |
| `PerformanceChart.tsx` | Historical P&L line chart | Recharts |
| `CandlestickChart.tsx` | Price OHLCV candles | D3.js |
| `SentimentTimeline.tsx` | Sentiment score over time | D3.js |

#### Widgets (`frontend/src/components/widgets/`)

| File | Purpose | Data Source |
|---|---|---|
| `MarketOverview.tsx` | RWA market totals (TVL, volume) | `/api/market/overview` |
| `PortfolioSummary.tsx` | User portfolio value, P&L | `/api/portfolio/summary` |
| `Watchlist.tsx` | User's tracked assets | `/api/user/watchlist` |
| `AlertsList.tsx` | Recent alert triggers | `/api/alerts/recent` |
| `NewsFeed.tsx` | Latest news articles | WebSocket `news_item` |
| `TopMovers.tsx` | Best/worst performers (24h) | `/api/market/movers` |
| `PredictiveInsights.tsx` | XAI key drivers | `/api/predictions/{id}/explain` |

### Services (`frontend/src/services/`)

| File | Purpose | Endpoints |
|---|---|---|
| `api.ts` | Axios instance, interceptors, auth header injection | - |
| `auth.service.ts` | Authentication operations | `/auth/*` |
| `asset.service.ts` | Asset data fetching | `/assets/*` |
| `portfolio.service.ts` | Portfolio operations | `/portfolio/*` |
| `prediction.service.ts` | Prediction retrieval | `/predictions/*` |
| `alert.service.ts` | Alert CRUD | `/alerts/*` |
| `websocket.service.ts` | WebSocket connection | `ws://` |

### State Management (`frontend/src/store/`)

| File | Purpose | State |
|---|---|---|
| `index.ts` | Redux store configuration | - |
| `slices/authSlice.ts` | Authentication state | `user`, `token`, `isAuthenticated` |
| `slices/assetSlice.ts` | Assets data | `assets`, `selectedAsset`, `loading` |
| `slices/portfolioSlice.ts` | Portfolio state | `holdings`, `totalValue`, `pnl` |
| `slices/uiSlice.ts` | UI state | `sidebarOpen`, `theme`, `notifications` |
| `hooks.ts` | Typed hooks | `useAppDispatch`, `useAppSelector` |

### Custom Hooks (`frontend/src/hooks/`)

| File | Purpose | Returns |
|---|---|---|
| `useWebSocket.ts` | WebSocket connection management | `{ data, connected, sendMessage }` |
| `useAuth.ts` | Authentication helpers | `{ user, login, logout, isAuth }` |
| `useAssets.ts` | Asset data fetching | `{ assets, loading, fetchAssets }` |
| `useDebounce.ts` | Debounce input | Debounced value |
| `useLocalStorage.ts` | LocalStorage persistence | `[value, setValue]` |

## Infrastructure (`infrastructure/`)

### Terraform (`infrastructure/terraform/`)

| File | Purpose | Resources |
|---|---|---|
| `main.tf` | Root Terraform config | Module imports |
| `variables.tf` | Input variables | Region, environment, etc. |
| `outputs.tf` | Output values | Cluster endpoint, DB URL |
| `modules/vpc/` | VPC networking | VPC, subnets, IGW, NAT |
| `modules/eks/` | Kubernetes cluster | EKS cluster, node groups |
| `modules/rds/` | PostgreSQL database | RDS instance, security groups |
| `modules/s3/` | S3 data lake | Buckets, policies |
| `modules/kafka/` | Managed Kafka (MSK) | Kafka cluster, topics |

### Kubernetes (`infrastructure/kubernetes/`)

| File | Purpose | Resources |
|---|---|---|
| `dev/` | Dev environment manifests | Lower resource limits |
| `prod/` | Production manifests | HA, multi-replica |
| `api-deployment.yaml` | FastAPI deployment | Pods, HPA, service |
| `ml-deployment.yaml` | ML service deployment | GPU nodes, PVC |
| `frontend-deployment.yaml` | React app deployment | NGINX, service |
| `ingress.yaml` | Ingress controller | TLS, routing rules |
| `configmap.yaml` | Non-secret configuration | API URLs, feature flags |
| `secret.yaml` | Encrypted secrets | API keys, DB passwords |

### Docker (`infrastructure/docker/`)

| File | Purpose | Base Image |
|---|---|---|
| `Dockerfile.api` | FastAPI application | python:3.11-slim |
| `Dockerfile.ml` | ML service | pytorch/pytorch:latest |
| `Dockerfile.ingestion` | Data ingestion services | python:3.11-slim |
| `Dockerfile.frontend` | React production build | node:18 → nginx:alpine |
| `Dockerfile.spark` | Spark streaming | bitnami/spark:latest |

## Data Processing (`data_processing/`)

### Spark Jobs (`data_processing/spark_jobs/`)

| File | Purpose | Input → Output |
|---|---|---|
| `bronze_to_silver.py` | Data cleaning pipeline | S3 Bronze → S3 Silver |
| `silver_to_gold.py` | Aggregation pipeline | S3 Silver → TimescaleDB/Postgres |
| `feature_aggregator.py` | ML feature generation | Raw data → Feature store |
| `sentiment_aggregator.py` | Daily sentiment calculation | News data → Sentiment scores |

### Airflow DAGs (`data_processing/airflow_dags/`)

| File | Purpose | Schedule |
|---|---|---|
| `daily_data_pipeline.py` | Orchestrate daily data processing | Daily at 00:00 UTC |
| `model_retraining.py` | Trigger model retraining | Weekly |
| `data_quality_checks.py` | Validate data quality | Daily |
| `report_generation.py` | Generate system health reports | Daily |

## Scripts (`scripts/`)

| File | Purpose | Usage |
|---|---|---|
| `seed_database.py` | Populate DB with sample data | `python seed_database.py --env dev` |
| `create_admin_user.py` | Create admin account | `python create_admin_user.py` |
| `migrate_data.py` | Data migration utility | `python migrate_data.py --source old_db --target new_db` |
| `generate_api_docs.py` | Generate API documentation | `python generate_api_docs.py` |
| `deploy.sh` | Deployment script | `./deploy.sh production` |

## Configuration Files

| File | Purpose |
|---|---|
| `.github/workflows/ci.yml` | CI pipeline: lint, test, build |
| `.github/workflows/deploy.yml` | CD pipeline: deploy to staging/prod |
| `docker-compose.yml` | Local dev services |
| `.env.example` | Environment variables template |
| `.gitignore` | Git ignore patterns |
| `.pre-commit-config.yaml` | Pre-commit hooks (black, flake8) |
| `pyproject.toml` | Python project metadata |
| `requirements.txt` | Python dependencies |
| `frontend/package.json` | Node dependencies |
| `frontend/tsconfig.json` | TypeScript configuration |
| `frontend/vite.config.ts` | Vite build configuration |

## Key Flows

### 1. Price Update Flow
```
CoinAPI WebSocket
  → backend/data_ingestion/price_service.py
  → Kafka topic: price-data-raw
  → data_processing/spark_jobs/bronze_to_silver.py (Spark Streaming)
  → TimescaleDB: price_data table
  → backend/api/routes/assets.py (WebSocket push)
  → frontend/components/charts/PredictionChart.tsx
```

### 2. Prediction Generation Flow
```
Scheduled job (Airflow)
  → backend/ml_service/inference/batch_predictor.py
  → Fetch features from TimescaleDB
  → Load backend/ml_service/models/ensemble.py
  → Generate predictions
  → Store in PostgreSQL: predictions table
  → Cache in Redis
  → Available via backend/api/routes/predictions.py
```

### 3. User Alert Flow
```
User configures alert via frontend/pages/Alerts.tsx
  → POST backend/api/routes/alerts.py
  → Store in PostgreSQL: alerts table
  → Background worker (backend/workers/alert_checker.py) polls
  → Condition met → backend/workers/notification_service.py
  → Email/Telegram/Push notification sent
```

---

**Note**: This codebase map will be updated as development progresses. File paths and structures may evolve based on implementation needs.

**Related Documentation**:
- [DEVELOPMENT_GUIDE.md](./DEVELOPMENT_GUIDE.md) - Setup and workflow
- [ARCHITECTURE.md](./ARCHITECTURE.md) - System design
- [API_REFERENCE.md](./API_REFERENCE.md) - API endpoints
