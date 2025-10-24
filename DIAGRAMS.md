# RWA Prime - System Diagrams

This document contains all Mermaid diagrams for visualizing the RWA Prime architecture, data flows, and processes.

---

## Table of Contents
1. [System Architecture](#system-architecture)
2. [Data Flow Diagrams](#data-flow-diagrams)
3. [Database Schema](#database-schema)
4. [API Sequence Diagrams](#api-sequence-diagrams)
5. [Deployment Architecture](#deployment-architecture)
6. [User Flows](#user-flows)

---

## System Architecture

### High-Level System Architecture

```mermaid
graph TB
    subgraph Frontend["Frontend Layer"]
        WebApp["Web App<br/>(React + TypeScript)"]
        MobileApp["Mobile App<br/>(React Native)"]
        AdminPanel["Admin Panel"]
    end

    subgraph API["Backend API Layer (FastAPI)"]
        APIGateway["API Gateway<br/>(Rate Limiting, Auth)"]
        AuthService["Auth Service<br/>(JWT + 2FA)"]
        UserMgmt["User Management"]
    end

    subgraph Analytics["Analytics & Prediction Engine (Kubernetes)"]
        MLModels["ML Models<br/>(LSTM/ARIMA)"]
        NLPEngine["NLP Engine<br/>(BERT Sentiment)"]
        RiskEngine["Risk Scoring Engine"]
    end

    subgraph DataLayer["Data Processing & Storage (Medallion)"]
        Gold["Gold Layer<br/>(Query-Optimized)"]
        Silver["Silver Layer<br/>(Cleaned Data)"]
        Bronze["Bronze Layer<br/>(Raw Data)"]

        subgraph GoldDB["Gold Databases"]
            TimescaleDB["TimescaleDB<br/>(Time-Series)"]
            PostgreSQL["PostgreSQL<br/>(Relational)"]
        end
    end

    subgraph Ingestion["Data Ingestion Layer (Kafka)"]
        PriceService["Price Data<br/>Microservice"]
        OnChainService["On-Chain Data<br/>Microservice"]
        EconomicService["Economic Data<br/>Microservice"]
        NewsService["News/Sentiment<br/>Microservice"]
    end

    subgraph External["External Data Sources"]
        CoinAPI["CoinAPI"]
        Amberdata["Amberdata"]
        Bitquery["Bitquery"]
        RWAio["RWA.io"]
        TradingEcon["Trading Economics"]
        NewsAPI["NewsAPI.ai"]
    end

    WebApp <-->|REST + WebSocket| APIGateway
    MobileApp <-->|REST + WebSocket| APIGateway
    AdminPanel <-->|REST| APIGateway

    APIGateway --> AuthService
    APIGateway --> UserMgmt

    API --> Analytics
    Analytics --> Gold

    Gold --> TimescaleDB
    Gold --> PostgreSQL
    Silver --> Gold
    Bronze --> Silver

    Ingestion --> Bronze

    PriceService -->|Kafka| Bronze
    OnChainService -->|Kafka| Bronze
    EconomicService -->|Kafka| Bronze
    NewsService -->|Kafka| Bronze

    CoinAPI --> PriceService
    Amberdata --> OnChainService
    Bitquery --> OnChainService
    RWAio --> OnChainService
    TradingEcon --> EconomicService
    NewsAPI --> NewsService

    style Frontend fill:#e1f5ff
    style API fill:#fff4e1
    style Analytics fill:#ffe1f5
    style DataLayer fill:#e1ffe1
    style Ingestion fill:#f5e1ff
    style External fill:#ffe1e1
```

### Medallion Data Architecture

```mermaid
graph LR
    subgraph Bronze["🥉 Bronze Layer (Raw)"]
        S3Raw["AWS S3<br/>Raw JSON/Parquet<br/>Immutable"]
    end

    subgraph Silver["🥈 Silver Layer (Cleaned)"]
        Spark["Apache Spark<br/>Streaming"]
        Cleaned["Validated<br/>Deduplicated<br/>Enriched"]
    end

    subgraph Gold["🥇 Gold Layer (Aggregated)"]
        TSDB["TimescaleDB<br/>Price, Metrics"]
        RDBMS["PostgreSQL<br/>Users, Assets"]
        Cache["Redis<br/>Hot Data"]
    end

    S3Raw -->|Stream| Spark
    Spark --> Cleaned
    Cleaned --> TSDB
    Cleaned --> RDBMS
    RDBMS --> Cache

    style Bronze fill:#cd7f32,color:#fff
    style Silver fill:#c0c0c0
    style Gold fill:#ffd700
```

---

## Data Flow Diagrams

### Real-Time Price Update Flow

```mermaid
sequenceDiagram
    participant CoinAPI
    participant PriceService as Price Microservice
    participant Kafka
    participant Spark as Spark Streaming
    participant TimescaleDB
    participant API as Backend API
    participant WebSocket as WebSocket Service
    participant Frontend

    CoinAPI->>PriceService: WebSocket: Price Update
    PriceService->>Kafka: Publish to 'price-data-raw'
    Kafka->>Spark: Consume message
    Spark->>Spark: Clean & Validate
    Spark->>TimescaleDB: Insert into price_data table

    loop Every 1 second
        Frontend->>WebSocket: Subscribe to asset updates
        WebSocket->>TimescaleDB: Query latest prices
        TimescaleDB-->>WebSocket: Return prices
        WebSocket-->>Frontend: Push update via WebSocket
    end
```

### ML Prediction Generation Flow

```mermaid
flowchart TD
    A[Scheduled Job<br/>Airflow] --> B{Fetch Latest<br/>Features}
    B --> C[TimescaleDB:<br/>Price History]
    B --> D[TimescaleDB:<br/>On-Chain Metrics]
    B --> E[PostgreSQL:<br/>Sentiment Scores]

    C --> F[Feature<br/>Engineering]
    D --> F
    E --> F

    F --> G{Load Model}
    G --> H[ARIMA Model]
    G --> I[LSTM Model]

    H --> J[Ensemble<br/>Weighted Average]
    I --> J

    J --> K[Generate<br/>Predictions]
    K --> L[Calculate<br/>Confidence Intervals]

    L --> M[Store in PostgreSQL<br/>predictions table]
    M --> N[Cache in Redis<br/>TTL: 1 hour]

    N --> O[Available via<br/>GET /predictions/:id]

    style A fill:#e1f5ff
    style J fill:#ffe1f5
    style M fill:#e1ffe1
    style O fill:#fff4e1
```

### User Alert Trigger Flow

```mermaid
stateDiagram-v2
    [*] --> UserConfigured: User creates alert
    UserConfigured --> Stored: Save to PostgreSQL
    Stored --> Monitoring: Background worker polls

    state Monitoring {
        [*] --> CheckCondition
        CheckCondition --> ConditionMet: Threshold exceeded
        CheckCondition --> ConditionNotMet: Still normal
        ConditionNotMet --> CheckCondition: Wait 30s
    }

    ConditionMet --> NotificationService: Trigger alert

    state NotificationService {
        [*] --> DetermineMethod
        DetermineMethod --> SendEmail: Method: email
        DetermineMethod --> SendTelegram: Method: telegram
        DetermineMethod --> SendPush: Method: push

        SendEmail --> [*]
        SendTelegram --> [*]
        SendPush --> [*]
    }

    NotificationService --> LogEvent: Record in alert_history
    LogEvent --> Monitoring: Continue monitoring
```

---

## Database Schema

### Core Entity Relationship Diagram

```mermaid
erDiagram
    USERS ||--o{ PORTFOLIOS : owns
    USERS ||--o{ ALERTS : configures
    USERS {
        uuid user_id PK
        string email UK
        string password_hash
        string tier
        string totp_secret
        timestamp created_at
    }

    ASSETS ||--o{ PORTFOLIOS : contains
    ASSETS ||--o{ PREDICTIONS : has
    ASSETS ||--o{ RISK_SCORES : has
    ASSETS {
        uuid asset_id PK
        string symbol
        string name
        string asset_class
        string blockchain_network
        string contract_address
        jsonb underlying_asset_details
    }

    PORTFOLIOS {
        uuid portfolio_id PK
        uuid user_id FK
        uuid asset_id FK
        decimal quantity
        decimal avg_purchase_price
        string wallet_address
        timestamp created_at
    }

    PREDICTIONS {
        uuid prediction_id PK
        uuid asset_id FK
        int forecast_horizon
        decimal predicted_price
        decimal confidence_lower
        decimal confidence_upper
        timestamp generated_at
        string model_version
    }

    RISK_SCORES {
        uuid score_id PK
        uuid asset_id FK
        int composite_score
        int market_risk
        int credit_risk
        int regulatory_risk
        int technical_risk
        timestamp calculated_at
    }

    ALERTS {
        uuid alert_id PK
        uuid user_id FK
        uuid asset_id FK
        string condition_type
        jsonb condition_value
        string notification_method
        boolean is_active
    }
```

### Time-Series Data Model

```mermaid
erDiagram
    PRICE_DATA {
        timestamptz time PK
        uuid asset_id PK
        decimal open
        decimal high
        decimal low
        decimal close
        decimal volume
    }

    ONCHAIN_METRICS {
        timestamptz time PK
        uuid asset_id PK
        int holder_count
        decimal transfer_volume
        decimal dex_liquidity
        decimal exchange_inflow
        decimal exchange_outflow
    }

    SENTIMENT_SCORES {
        timestamptz time PK
        uuid asset_id PK
        decimal sentiment_score
        int article_count
        string source
    }

    PRICE_DATA ||--o{ ONCHAIN_METRICS : "same asset"
    PRICE_DATA ||--o{ SENTIMENT_SCORES : "same asset"
```

---

## API Sequence Diagrams

### User Authentication Flow (with 2FA)

```mermaid
sequenceDiagram
    actor User
    participant Frontend
    participant API as API Gateway
    participant Auth as Auth Service
    participant DB as PostgreSQL
    participant TOTP as TOTP Validator

    User->>Frontend: Enter email + password
    Frontend->>API: POST /auth/login
    API->>Auth: Validate credentials
    Auth->>DB: Query user by email
    DB-->>Auth: Return user record
    Auth->>Auth: Verify password hash

    alt Credentials Valid
        Auth->>Auth: Generate temp JWT
        Auth-->>API: Return temp_token
        API-->>Frontend: 200 OK {temp_token}
        Frontend->>User: Show 2FA input

        User->>Frontend: Enter TOTP code
        Frontend->>API: POST /auth/verify-2fa<br/>{totp_code}
        API->>TOTP: Validate TOTP

        alt TOTP Valid
            TOTP->>Auth: Generate access + refresh tokens
            Auth-->>API: Return tokens
            API-->>Frontend: 200 OK {access_token, refresh_token}
            Frontend->>Frontend: Store tokens securely
            Frontend->>User: Redirect to dashboard
        else TOTP Invalid
            TOTP-->>API: 401 Invalid code
            API-->>Frontend: Error response
            Frontend->>User: Show error message
        end
    else Credentials Invalid
        Auth-->>API: 401 Unauthorized
        API-->>Frontend: Error response
        Frontend->>User: Show error message
    end
```

### Portfolio Sync from Wallet

```mermaid
sequenceDiagram
    participant User
    participant Frontend
    participant API
    participant Portfolio as Portfolio Service
    participant Blockchain as Blockchain RPC
    participant DB as PostgreSQL

    User->>Frontend: Click "Sync Wallet"
    Frontend->>API: POST /portfolio/sync-wallet<br/>{wallet_address, blockchain}

    API->>Portfolio: Initiate sync
    Portfolio->>Blockchain: Query wallet transactions
    Blockchain-->>Portfolio: Return transaction history

    loop For each RWA token
        Portfolio->>DB: Check if asset exists
        DB-->>Portfolio: Asset metadata
        Portfolio->>Portfolio: Calculate quantity & avg price
        Portfolio->>DB: Upsert portfolio item
    end

    Portfolio->>DB: Commit transaction
    Portfolio-->>API: Sync complete<br/>{synced_assets: 3, new_transactions: 5}
    API-->>Frontend: 200 OK
    Frontend->>User: Show success + updated portfolio
```

### Prediction Request Flow

```mermaid
sequenceDiagram
    participant Client
    participant API
    participant Cache as Redis Cache
    participant PredService as Prediction Service
    participant DB as PostgreSQL

    Client->>API: GET /predictions/asset-123?horizon=7
    API->>Cache: Check cache for asset-123:7d

    alt Cache Hit
        Cache-->>API: Return cached prediction
        API-->>Client: 200 OK {predictions}
    else Cache Miss
        Cache-->>API: Cache miss
        API->>DB: Query latest prediction
        DB-->>API: Return prediction data
        API->>Cache: Store in cache (TTL: 1h)
        API-->>Client: 200 OK {predictions}
    end

    Note over API,DB: Predictions refreshed hourly<br/>by background job
```

---

## Deployment Architecture

### Kubernetes Cluster Architecture

```mermaid
graph TB
    subgraph Internet
        Users["Users"]
        DevOps["DevOps"]
    end

    subgraph AWS["AWS Cloud"]
        subgraph VPC["VPC (Multi-AZ)"]
            subgraph EKS["EKS Cluster"]
                Ingress["NGINX Ingress<br/>Controller"]

                subgraph FrontendNS["frontend namespace"]
                    FrontendPods["React App Pods<br/>(3 replicas)"]
                end

                subgraph BackendNS["backend namespace"]
                    APIPods["FastAPI Pods<br/>(5 replicas + HPA)"]
                    WorkerPods["Background Workers<br/>(2 replicas)"]
                end

                subgraph MLNS["ml-service namespace"]
                    MLPods["ML Service Pods<br/>(2 replicas, GPU)"]
                end

                subgraph DataNS["data-ingestion namespace"]
                    IngestionPods["Data Ingestion<br/>Microservices"]
                end
            end

            RDS["RDS PostgreSQL<br/>(Multi-AZ)"]
            MSK["MSK Kafka Cluster<br/>(3 brokers)"]
            ElastiCache["ElastiCache Redis<br/>(Cluster mode)"]
        end

        S3["S3 Data Lake<br/>(Bronze/Silver/Gold)"]
        CloudFront["CloudFront CDN"]
        Route53["Route 53 DNS"]
    end

    Users -->|HTTPS| Route53
    Route53 --> CloudFront
    CloudFront --> Ingress

    Ingress --> FrontendPods
    Ingress --> APIPods

    APIPods --> MLPods
    APIPods --> RDS
    APIPods --> ElastiCache

    WorkerPods --> MSK
    IngestionPods --> MSK

    MLPods --> RDS

    WorkerPods --> S3
    IngestionPods --> S3

    DevOps -->|kubectl| EKS

    style EKS fill:#ff9900
    style RDS fill:#527FFF
    style MSK fill:#FF6B35
    style S3 fill:#569A31
```

### Multi-Environment Strategy

```mermaid
graph LR
    subgraph Development["Development Environment"]
        DevEKS["EKS (1 node)"]
        DevRDS["RDS t3.medium"]
    end

    subgraph Staging["Staging Environment"]
        StageEKS["EKS (3 nodes)"]
        StageRDS["RDS t3.large"]
    end

    subgraph Production["Production Environment"]
        ProdEKS1["EKS Cluster<br/>US-East"]
        ProdEKS2["EKS Cluster<br/>EU-West"]
        ProdRDS["RDS db.r5.xlarge<br/>(Multi-AZ)"]
    end

    DevEKS -->|Promote & Test| StageEKS
    StageEKS -->|Manual Approval| ProdEKS1
    ProdEKS1 <-->|Replication| ProdEKS2

    style Development fill:#90EE90
    style Staging fill:#FFD700
    style Production fill:#FF6B6B
```

---

## User Flows

### New User Onboarding

```mermaid
journey
    title New User Onboarding Journey
    section Discovery
      Visit landing page: 5: User
      Read about features: 4: User
      Click "Sign Up": 5: User
    section Registration
      Enter email & password: 3: User
      Choose subscription tier: 4: User
      Verify email: 3: User
      Set up 2FA: 2: User
    section First Use
      Complete tutorial: 4: User
      Connect wallet: 3: User
      View first prediction: 5: User
      Add asset to watchlist: 5: User
    section Engagement
      Set up first alert: 4: User
      Explore screener: 4: User
      Check portfolio daily: 5: User
```

### Asset Analysis Flow

```mermaid
flowchart TD
    Start([User wants to analyze<br/>an RWA asset]) --> Dashboard[Go to Dashboard]
    Dashboard --> Screener{Use Screener<br/>or Search?}

    Screener -->|Screener| Filter[Apply Filters:<br/>Asset Class, Blockchain, APY]
    Screener -->|Search| Search[Search by Symbol/Name]

    Filter --> Results[View Results List]
    Search --> Results

    Results --> SelectAsset[Click on Asset]
    SelectAsset --> AssetPage[Asset Detail Page Loads]

    AssetPage --> ViewData{What to View?}

    ViewData -->|Overview| Overview[View Price Chart<br/>+ 7-day Prediction]
    ViewData -->|Risk| Risk[View Composite Risk Score<br/>+ Breakdown]
    ViewData -->|On-Chain| OnChain[View Holder Stats<br/>+ DEX Liquidity]
    ViewData -->|Fundamentals| Fundamentals[View Underlying Asset<br/>+ Issuer Info]

    Overview --> Decision{Investment<br/>Decision?}
    Risk --> Decision
    OnChain --> Decision
    Fundamentals --> Decision

    Decision -->|Interested| AddPortfolio[Add to Portfolio<br/>or Watchlist]
    Decision -->|Not Interested| Back[Back to Results]
    Decision -->|Need More Info| ViewData

    AddPortfolio --> SetAlert[Set Price Alert?]
    SetAlert -->|Yes| CreateAlert[Configure Alert]
    SetAlert -->|No| End([Done])
    CreateAlert --> End
    Back --> Results

    style Start fill:#e1f5ff
    style Decision fill:#ffe1e1
    style End fill:#e1ffe1
```

### Alert Lifecycle

```mermaid
stateDiagram-v2
    [*] --> Draft: User starts creating alert
    Draft --> Configured: User sets conditions
    Configured --> Active: User saves alert

    state Active {
        [*] --> Monitoring
        Monitoring --> Triggered: Condition met
        Triggered --> Notifying: Send notification
        Notifying --> Monitoring: Continue monitoring
    }

    Active --> Paused: User pauses
    Paused --> Active: User resumes

    Active --> Modified: User edits
    Modified --> Active: User saves changes

    Active --> Deleted: User deletes
    Paused --> Deleted: User deletes

    Deleted --> [*]
```

---

## CI/CD Pipeline Flow

```mermaid
graph LR
    subgraph Developer["Developer Workflow"]
        Code[Write Code] --> Commit[Git Commit]
        Commit --> Push[Git Push]
    end

    subgraph CI["Continuous Integration (GitHub Actions)"]
        Push --> Lint[Lint Check]
        Lint --> Test[Run Tests]
        Test --> Build[Build Docker Image]
        Build --> Scan[Security Scan]
        Scan --> Push2[Push to ECR]
    end

    subgraph CD["Continuous Deployment"]
        Push2 --> DeployDev[Deploy to Dev]
        DeployDev --> SmokeTest[Smoke Tests]
        SmokeTest --> DeployStage[Deploy to Staging]
        DeployStage --> IntegrationTest[Integration Tests]
        IntegrationTest --> Approval{Manual Approval}
        Approval -->|Approved| DeployProd[Deploy to Production]
        Approval -->|Rejected| Rollback[Rollback]
    end

    style Code fill:#90EE90
    style Approval fill:#FFD700
    style DeployProd fill:#FF6B6B
```

---

**Last Updated**: October 23, 2025
**Maintained By**: Development Team

**Note**: These diagrams are rendered using Mermaid. View this file in GitHub, GitLab, or any Mermaid-compatible markdown viewer for proper visualization.

**Related Documentation**:
- [ARCHITECTURE.md](./ARCHITECTURE.md) - Detailed architecture explanations
- [API_REFERENCE.md](./API_REFERENCE.md) - API endpoint specifications
- [DEVELOPMENT_GUIDE.md](./DEVELOPMENT_GUIDE.md) - Development workflows
