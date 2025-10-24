# ARCHITECTURE.md

## Table of Contents
1. [System Overview](#system-overview)
2. [High-Level Architecture](#high-level-architecture)
3. [Component Details](#component-details)
4. [Data Flow](#data-flow)
5. [Technology Stack](#technology-stack)
6. [Database Schema](#database-schema)
7. [API Structure](#api-structure)
8. [Security Architecture](#security-architecture)
9. [Deployment Architecture](#deployment-architecture)
10. [Scalability Considerations](#scalability-considerations)

## System Overview

### Architecture Philosophy
RWA-Prime employs a **decoupled, microservices-based architecture** designed for:
- Real-time performance (<2s dashboard load time)
- High scalability (horizontal scaling capability)
- Fault tolerance (99.9% uptime SLA)
- Separation of concerns (data ingestion ≠ analytics ≠ presentation)

### Architecture Pattern
**Medallion Architecture** (Bronze → Silver → Gold layers) with microservices orchestration

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         FRONTEND LAYER                           │
│  ┌──────────────────┐  ┌──────────────────┐  ┌───────────────┐ │
│  │  Web App (React) │  │  Mobile App      │  │  Admin Panel  │ │
│  │  + D3.js         │  │  (React Native)  │  │               │ │
│  └────────┬─────────┘  └────────┬─────────┘  └───────┬───────┘ │
└───────────┼─────────────────────┼────────────────────┼─────────┘
            │                     │                    │
            └─────────────────────┼────────────────────┘
                                  │ WebSocket + REST API
┌─────────────────────────────────┼────────────────────────────────┐
│                    BACKEND API LAYER (FastAPI)                    │
│  ┌──────────────┐  ┌─────────────┐  ┌──────────────────────────┐ │
│  │ API Gateway  │  │ Auth Service│  │  User Management          │ │
│  └──────┬───────┘  └─────┬───────┘  └──────────┬───────────────┘ │
└─────────┼─────────────────┼─────────────────────┼─────────────────┘
          │                 │                     │
┌─────────┼─────────────────┼─────────────────────┼─────────────────┐
│         │      ANALYTICS & PREDICTION ENGINE (Kubernetes)         │
│  ┌──────┴────────┐  ┌────┴────────┐  ┌─────────┴──────────────┐  │
│  │  ML Models    │  │ NLP Engine  │  │  Risk Scoring Engine   │  │
│  │  (LSTM/ARIMA) │  │ (BERT)      │  │                        │  │
│  └───────────────┘  └─────────────┘  └────────────────────────┘  │
└──────────────────────────────┬────────────────────────────────────┘
                               │
┌──────────────────────────────┼────────────────────────────────────┐
│         DATA PROCESSING & STORAGE LAYER (Medallion)               │
│                                                                    │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │  GOLD LAYER (Aggregated - Query-Optimized)                 │  │
│  │  ┌──────────────────┐  ┌─────────────────────────────┐    │  │
│  │  │ Time-Series DB   │  │  Relational DB (PostgreSQL) │    │  │
│  │  │ (InfluxDB/       │  │  - User data                │    │  │
│  │  │  TimescaleDB)    │  │  - Asset metadata           │    │  │
│  │  │ - Price data     │  │  - Portfolios               │    │  │
│  │  │ - On-chain       │  │  - Alerts config            │    │  │
│  │  │   metrics        │  │                             │    │  │
│  │  └──────────────────┘  └─────────────────────────────┘    │  │
│  └────────────────────────────────────────────────────────────┘  │
│                               ▲                                   │
│  ┌────────────────────────────┼───────────────────────────────┐  │
│  │  SILVER LAYER (Cleaned - Apache Spark Streaming)          │  │
│  │  - Data cleaning & normalization                           │  │
│  │  - Feature engineering                                     │  │
│  │  - Enrichment (tagging, labeling)                          │  │
│  └────────────────────────────▲───────────────────────────────┘  │
│                               │                                   │
│  ┌────────────────────────────┼───────────────────────────────┐  │
│  │  BRONZE LAYER (Raw - AWS S3 Data Lake)                     │  │
│  │  - Immutable source of truth                               │  │
│  │  - Raw API responses                                       │  │
│  │  - Historical reprocessing capability                      │  │
│  └────────────────────────────▲───────────────────────────────┘  │
└────────────────────────────────┼───────────────────────────────────┘
                                 │
┌────────────────────────────────┼───────────────────────────────────┐
│              DATA INGESTION LAYER (Apache Kafka)                   │
│  ┌─────────────┐  ┌─────────────┐  ┌──────────────┐  ┌─────────┐ │
│  │Price Data   │  │On-Chain Data│  │Economic Data │  │News/    │ │
│  │Microservice │  │Microservice │  │Microservice  │  │Sentiment│ │
│  └──────┬──────┘  └──────┬──────┘  └──────┬───────┘  └────┬────┘ │
└─────────┼────────────────┼─────────────────┼──────────────┼────────┘
          │                │                 │              │
          ▼                ▼                 ▼              ▼
┌─────────────────────────────────────────────────────────────────┐
│                     EXTERNAL DATA SOURCES                        │
│  CoinAPI, FMP, Amberdata, Bitquery, RWA.io, Trading Economics,  │
│  World Bank API, NewsAPI.ai, Tradefeeds                         │
└─────────────────────────────────────────────────────────────────┘
```

## Component Details

### 1. Data Ingestion Layer

**Purpose**: Connect to external APIs and stream data into the system

**Components**:

#### Price Data Microservice
- **Responsibility**: Fetch real-time and historical price data
- **Data Sources**: CoinAPI, Financial Modeling Prep (FMP), Finazon
- **Update Frequency**: Real-time via WebSocket
- **Technology**: Python + aiohttp for async requests
- **Output**: Raw OHLCV data → Kafka topic `price-data-raw`

#### On-Chain Data Microservice
- **Responsibility**: Fetch blockchain transaction and smart contract data
- **Data Sources**: Amberdata, Bitquery, RWA.io API
- **Metrics**: Holder count, transfer volume, mints/burns, DEX liquidity
- **Update Frequency**: Real-time
- **Technology**: Python + web3.py
- **Output**: → Kafka topic `onchain-data-raw`

#### Economic Data Microservice
- **Responsibility**: Fetch macroeconomic indicators
- **Data Sources**: Trading Economics API, World Bank API
- **Metrics**: GDP, inflation, interest rates, unemployment
- **Update Frequency**: Daily/Monthly
- **Technology**: Python + requests
- **Output**: → Kafka topic `economic-data-raw`

#### News & Sentiment Microservice
- **Responsibility**: Fetch and pre-process news articles
- **Data Sources**: NewsAPI.ai, Tradefeeds Crypto News API
- **Update Frequency**: Real-time
- **Technology**: Python + NLP preprocessing
- **Output**: → Kafka topic `news-sentiment-raw`

**Message Queue**: Apache Kafka
- High-throughput, fault-tolerant messaging
- Topic-based architecture for data segregation
- Replay capability for historical reprocessing

### 2. Data Processing & Storage Layer

**Architecture**: Medallion (3-tier)

#### Bronze Layer (Raw)
- **Technology**: AWS S3 (or equivalent object storage)
- **Purpose**: Immutable landing zone for all raw data
- **Format**: JSON/Parquet files partitioned by date and source
- **Retention**: Indefinite (for regulatory and reprocessing)
- **Access Pattern**: Write-once, read for reprocessing

#### Silver Layer (Cleaned)
- **Technology**: Apache Spark Structured Streaming
- **Purpose**: Real-time data transformation and cleaning
- **Operations**:
  - Data validation and cleaning
  - Deduplication
  - Schema enforcement
  - Feature engineering (e.g., moving averages, volatility calculations)
  - Asset tagging and enrichment
- **Output**: Structured, cleaned data → Gold layer

#### Gold Layer (Aggregated)
- **Time-Series Database** (InfluxDB or TimescaleDB):
  - High-frequency time-series data
  - Price OHLCV (1min, 5min, 1hour, 1day intervals)
  - On-chain metrics time-series
  - Sentiment scores over time
  - Optimized for range queries

- **Relational Database** (PostgreSQL):
  - User accounts and authentication
  - Asset metadata (fundamentals, legal structure, issuer info)
  - User portfolios and transactions
  - Alert configurations
  - Model outputs (predictions, risk scores)

### 3. Analytics & Prediction Engine

**Technology**: Containerized Python applications (Docker + Kubernetes)

#### ML Forecasting Service
- **Models**:
  - **ARIMA**: For linear time-series patterns
  - **LSTM**: For complex, non-linear patterns
- **Features**:
  - Historical price data
  - On-chain metrics (holder count, volume, DEX activity)
  - Sentiment scores
  - Economic indicators (for macro-sensitive assets like treasuries)
- **Training**:
  - Periodic retraining (weekly/monthly)
  - Trigger-based retraining (performance degradation detection)
- **Output**: 7-day and 30-day price predictions with confidence intervals

#### NLP Sentiment Analysis Service
- **Model**: BERT-based transformer (or FinBERT for financial text)
- **Input**: News articles, regulatory announcements, social media
- **Process**:
  1. Text preprocessing (tokenization, cleaning)
  2. Sentiment classification (-1 to +1 scale)
  3. Entity extraction (which RWA mentioned)
  4. Aggregation to daily sentiment scores per asset
- **Technology**: Python + Hugging Face Transformers
- **Output**: Sentiment scores → PostgreSQL + feature for ML models

#### Risk Scoring Service
- **Composite Risk Score** (1-100 scale):
  - **Market Risk** (30% weight): Volatility, liquidity depth
  - **Credit Risk** (25%): Underlying asset quality, default probability
  - **Regulatory Risk** (25%): Jurisdiction, legal structure, compliance
  - **Technical Risk** (20%): Smart contract audits, oracle dependency
- **Dynamic Weighting**: Adjusted per asset class
- **Output**: Overall + sub-scores → PostgreSQL

#### Model Validation & Backtesting Service
- **Framework**: backtesting.py
- **Process**:
  - Rolling-forward cross-validation (TimeSeriesSplit)
  - Performance metrics calculation (Sharpe, Sortino, Max Drawdown)
  - Bias mitigation (survivorship, look-ahead, optimization)
- **Runs**: On-demand + after major model updates

### 4. Backend API Layer

**Technology**: FastAPI (Python)

#### API Gateway
- **Purpose**: Single entry point for all client requests
- **Features**:
  - Request routing
  - Rate limiting
  - Request/response logging
  - Error handling
  - CORS configuration

#### Authentication & Authorization Service
- **Authentication**: JWT-based tokens
- **2FA**: TOTP (Time-based One-Time Password)
- **Authorization**: Role-based access control (RBAC)
  - Explorer tier permissions
  - Professional tier permissions
  - Enterprise tier permissions
  - Admin permissions

#### Core API Endpoints (see API_REFERENCE.md for details)
- `/auth/*` - Authentication endpoints
- `/assets/*` - Asset data and analytics
- `/portfolio/*` - Portfolio tracking
- `/alerts/*` - Alert management
- `/predictions/*` - ML model outputs
- `/reports/*` - PDF report generation

#### WebSocket Service
- **Purpose**: Real-time data push to clients
- **Events**:
  - Price updates
  - Alert triggers
  - Portfolio value changes
  - News feed updates

### 5. Frontend Layer

#### Web Application
- **Framework**: React 18+ with TypeScript
- **State Management**: Redux Toolkit or Zustand
- **Styling**: Tailwind CSS + custom design system
- **Charts/Visualizations**: D3.js + Recharts
- **Real-time**: WebSocket client
- **Build Tool**: Vite

**Key Components**:
- Dashboard (modular, widget-based)
- Asset Screener
- Asset Detail Pages (multi-tab)
- Portfolio Tracker
- Alert Configuration UI
- Comparative Analysis Tool

#### Mobile Application
- **Framework**: React Native (code sharing with web)
- **Platform**: iOS + Android
- **Features**: Subset of web app focused on monitoring and alerts

#### Admin Panel
- **Purpose**: Internal operations and monitoring
- **Features**:
  - User management
  - System health monitoring
  - Data pipeline status
  - Model performance tracking

## Data Flow

### Real-Time Price Update Flow
1. CoinAPI WebSocket → Price Data Microservice
2. → Kafka topic `price-data-raw`
3. → Spark Streaming (Silver layer processing)
4. → InfluxDB (Gold layer)
5. → WebSocket Service → Frontend (real-time chart update)

### Prediction Generation Flow
1. Scheduled job triggers ML Forecasting Service
2. Service fetches latest features from Gold layer
3. LSTM/ARIMA model inference
4. Prediction + confidence interval generated
5. Stored in PostgreSQL `predictions` table
6. Available via `/predictions/{asset_id}` API

### User Alert Flow
1. User configures alert via Frontend
2. POST `/alerts` → Alert Service
3. Alert config stored in PostgreSQL
4. Background worker polls for alert conditions
5. Condition met → Alert Service publishes event
6. Notification Service sends email/Telegram/push notification

## Technology Stack

### Programming Languages
- **Python 3.11+**: Backend services, ML/NLP, data processing
- **TypeScript**: Frontend application
- **SQL**: Database queries

### Frameworks & Libraries
- **Backend**: FastAPI, SQLAlchemy, Pydantic
- **ML/AI**: PyTorch/TensorFlow, scikit-learn, Hugging Face Transformers
- **Data Processing**: Apache Spark (PySpark), Pandas, NumPy
- **Frontend**: React, D3.js, Recharts, Axios

### Infrastructure
- **Cloud Provider**: AWS (or Azure/GCP)
- **Containerization**: Docker
- **Orchestration**: Kubernetes (EKS/AKS/GKE)
- **Message Queue**: Apache Kafka (AWS MSK)
- **Object Storage**: AWS S3
- **Databases**:
  - Time-Series: TimescaleDB (PostgreSQL extension) or InfluxDB
  - Relational: PostgreSQL 15+
  - Cache: Redis

### DevOps & Monitoring
- **CI/CD**: GitHub Actions or GitLab CI
- **Infrastructure as Code**: Terraform
- **Monitoring**: Prometheus + Grafana
- **Logging**: ELK Stack (Elasticsearch, Logstash, Kibana)
- **Error Tracking**: Sentry

## Database Schema

### PostgreSQL Tables (Core)

```sql
-- Users
CREATE TABLE users (
    user_id UUID PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    tier VARCHAR(50) NOT NULL, -- 'explorer', 'professional', 'enterprise'
    totp_secret VARCHAR(255),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Assets
CREATE TABLE assets (
    asset_id UUID PRIMARY KEY,
    symbol VARCHAR(50) NOT NULL,
    name VARCHAR(255) NOT NULL,
    asset_class VARCHAR(100) NOT NULL, -- 'tokenized_treasury', 'private_credit', etc.
    blockchain_network VARCHAR(50) NOT NULL,
    contract_address VARCHAR(255),
    issuer_name VARCHAR(255),
    underlying_asset_details JSONB,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Predictions
CREATE TABLE predictions (
    prediction_id UUID PRIMARY KEY,
    asset_id UUID REFERENCES assets(asset_id),
    forecast_horizon INT NOT NULL, -- 7 or 30 days
    predicted_price DECIMAL(20, 8) NOT NULL,
    confidence_lower DECIMAL(20, 8),
    confidence_upper DECIMAL(20, 8),
    generated_at TIMESTAMP DEFAULT NOW(),
    model_version VARCHAR(50)
);

-- Risk Scores
CREATE TABLE risk_scores (
    score_id UUID PRIMARY KEY,
    asset_id UUID REFERENCES assets(asset_id),
    composite_score INT NOT NULL, -- 1-100
    market_risk INT,
    credit_risk INT,
    regulatory_risk INT,
    technical_risk INT,
    calculated_at TIMESTAMP DEFAULT NOW()
);

-- Portfolios
CREATE TABLE portfolios (
    portfolio_id UUID PRIMARY KEY,
    user_id UUID REFERENCES users(user_id),
    asset_id UUID REFERENCES assets(asset_id),
    quantity DECIMAL(20, 8) NOT NULL,
    avg_purchase_price DECIMAL(20, 8),
    wallet_address VARCHAR(255),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Alerts
CREATE TABLE alerts (
    alert_id UUID PRIMARY KEY,
    user_id UUID REFERENCES users(user_id),
    asset_id UUID REFERENCES assets(asset_id),
    condition_type VARCHAR(100) NOT NULL,
    condition_value JSONB NOT NULL,
    notification_method VARCHAR(50) NOT NULL, -- 'email', 'telegram', 'push'
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT NOW()
);
```

### TimescaleDB Hypertables

```sql
-- Price Data (hypertable for time-series optimization)
CREATE TABLE price_data (
    time TIMESTAMPTZ NOT NULL,
    asset_id UUID NOT NULL,
    open DECIMAL(20, 8),
    high DECIMAL(20, 8),
    low DECIMAL(20, 8),
    close DECIMAL(20, 8),
    volume DECIMAL(30, 8)
);
SELECT create_hypertable('price_data', 'time');

-- On-Chain Metrics
CREATE TABLE onchain_metrics (
    time TIMESTAMPTZ NOT NULL,
    asset_id UUID NOT NULL,
    holder_count INT,
    transfer_volume DECIMAL(30, 8),
    dex_liquidity DECIMAL(30, 8),
    exchange_inflow DECIMAL(30, 8),
    exchange_outflow DECIMAL(30, 8)
);
SELECT create_hypertable('onchain_metrics', 'time');

-- Sentiment Scores
CREATE TABLE sentiment_scores (
    time TIMESTAMPTZ NOT NULL,
    asset_id UUID NOT NULL,
    sentiment_score DECIMAL(3, 2), -- -1.00 to 1.00
    article_count INT,
    source VARCHAR(100)
);
SELECT create_hypertable('sentiment_scores', 'time');
```

## API Structure

See [API_REFERENCE.md](./API_REFERENCE.md) for complete API documentation.

### REST API Patterns
- RESTful resource-based URLs
- JSON request/response bodies
- JWT authentication via `Authorization: Bearer {token}` header
- Pagination via `?page=X&limit=Y` query parameters
- Filtering via query parameters
- Sorting via `?sort_by=field&order=asc|desc`

### WebSocket Events
- `price_update`: Real-time price changes
- `alert_triggered`: User alert fired
- `portfolio_update`: Portfolio value recalculated
- `news_item`: New relevant news article

## Security Architecture

### Authentication Flow
1. User submits email + password → `/auth/login`
2. Server validates credentials
3. If valid, request TOTP code (2FA)
4. User submits TOTP → `/auth/verify-2fa`
5. Server issues JWT access token (15min expiry) + refresh token (7 days)
6. Client stores tokens securely (HttpOnly cookies for web)

### Data Encryption
- **In Transit**: TLS 1.3 for all connections
- **At Rest**:
  - Database encryption (AWS RDS encryption)
  - S3 bucket encryption (SSE-S3 or SSE-KMS)
  - Secrets management: AWS Secrets Manager or HashiCorp Vault

### API Security
- Rate limiting: 100 req/min per user (Explorer), 500 req/min (Professional), unlimited (Enterprise)
- API key rotation for external data sources
- Input validation and sanitization
- SQL injection prevention (parameterized queries via SQLAlchemy)
- XSS prevention (React default escaping + CSP headers)

### Compliance
- GDPR: Data deletion endpoints, export capabilities, consent management
- KYC/AML: Identity verification for Enterprise tier (partner with identity service)
- Audit logging: All user actions logged with timestamps

## Deployment Architecture

### Kubernetes Cluster Layout

```
┌─────────────────────────────────────────────────┐
│              Kubernetes Cluster (AWS EKS)       │
│                                                 │
│  ┌──────────────────────────────────────────┐  │
│  │  Ingress Controller (NGINX)              │  │
│  │  - TLS termination                       │  │
│  │  - Load balancing                        │  │
│  └────────────┬─────────────────────────────┘  │
│               │                                 │
│  ┌────────────┴─────────────────────────────┐  │
│  │  Frontend Service (React SPA)            │  │
│  │  Replicas: 3                             │  │
│  └──────────────────────────────────────────┘  │
│                                                 │
│  ┌──────────────────────────────────────────┐  │
│  │  Backend API Service (FastAPI)           │  │
│  │  Replicas: 5                             │  │
│  │  Horizontal Pod Autoscaling: enabled     │  │
│  └──────────────────────────────────────────┘  │
│                                                 │
│  ┌──────────────────────────────────────────┐  │
│  │  ML Service (Python)                     │  │
│  │  Replicas: 2                             │  │
│  │  GPU nodes: 1x NVIDIA T4                 │  │
│  └──────────────────────────────────────────┘  │
│                                                 │
│  ┌──────────────────────────────────────────┐  │
│  │  Data Ingestion Services                 │  │
│  │  - Price microservice: 2 replicas        │  │
│  │  - On-chain microservice: 2 replicas     │  │
│  │  - Economic microservice: 1 replica      │  │
│  │  - News microservice: 2 replicas         │  │
│  └──────────────────────────────────────────┘  │
│                                                 │
│  ┌──────────────────────────────────────────┐  │
│  │  Spark Streaming (Silver layer)          │  │
│  │  - Driver: 1 pod                         │  │
│  │  - Executors: 3-10 pods (autoscaling)    │  │
│  └──────────────────────────────────────────┘  │
└─────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────┐
│          Managed Services (AWS)                 │
│  - RDS PostgreSQL (Multi-AZ)                   │
│  - MSK (Managed Kafka)                         │
│  - S3 (Data Lake)                              │
│  - ElastiCache Redis (Caching)                 │
└─────────────────────────────────────────────────┘
```

### Environments
- **Development**: Single cluster, lower resources
- **Staging**: Production-like, for integration testing
- **Production**: Multi-region (US-East, EU-West for latency), high availability

## Scalability Considerations

### Horizontal Scaling
- **Stateless Services**: All services designed to be stateless for easy horizontal scaling
- **Auto-scaling**: Kubernetes HPA based on CPU/memory and custom metrics (request rate)
- **Database**: Read replicas for query distribution

### Performance Optimization
- **Caching**: Redis for frequently accessed data (asset metadata, popular predictions)
- **CDN**: CloudFront for static assets and frontend SPA
- **Database Indexing**: Comprehensive indexing strategy for time-series and relational queries
- **Connection Pooling**: Database connection pooling (PgBouncer)

### Data Volume Management
- **Partitioning**: Time-based partitioning for historical data
- **Archival**: Old data moved to S3 Glacier after 2 years
- **Data Retention Policies**: Clear policies per data type

---

**Related Documentation**:
- [PROJECT_CONTEXT.md](./PROJECT_CONTEXT.md)
- [DEVELOPMENT_GUIDE.md](./DEVELOPMENT_GUIDE.md)
- [API_REFERENCE.md](./API_REFERENCE.md)
- [DEPENDENCIES.md](./DEPENDENCIES.md)
