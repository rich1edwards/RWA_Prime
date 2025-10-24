# Architecture Decision Records (ADR)

## Purpose

This document records significant architectural decisions made for the RWA Prime platform, including the context, alternatives considered, decision rationale, and consequences. ADRs help prevent re-litigating past decisions and provide context for future changes.

---

## Table of Contents

- [ADR-001: PostgreSQL + TimescaleDB for Data Storage](#adr-001-postgresql--timescaledb-for-data-storage)
- [ADR-002: FastAPI for Backend Framework](#adr-002-fastapi-for-backend-framework)
- [ADR-003: Apache Kafka for Message Streaming](#adr-003-apache-kafka-for-message-streaming)
- [ADR-004: Medallion Architecture for Data Pipeline](#adr-004-medallion-architecture-for-data-pipeline)
- [ADR-005: LSTM + ARIMA Ensemble for Price Predictions](#adr-005-lstm--arima-ensemble-for-price-predictions)
- [ADR-006: Microservices Architecture](#adr-006-microservices-architecture)
- [ADR-007: React + TypeScript for Frontend](#adr-007-react--typescript-for-frontend)
- [ADR-008: Kubernetes on AWS EKS for Orchestration](#adr-008-kubernetes-on-aws-eks-for-orchestration)
- [ADR-009: Redis for Caching Layer](#adr-009-redis-for-caching-layer)
- [ADR-010: JWT for Authentication](#adr-010-jwt-for-authentication)
- [ADR-011: Apache Spark for Stream Processing](#adr-011-apache-spark-for-stream-processing)
- [ADR-012: S3 for Data Lake Storage](#adr-012-s3-for-data-lake-storage)
- [ADR-013: BERT for Sentiment Analysis](#adr-013-bert-for-sentiment-analysis)
- [ADR-014: GitHub Actions for CI/CD](#adr-014-github-actions-for-cicd)
- [ADR-015: Terraform for Infrastructure as Code](#adr-015-terraform-for-infrastructure-as-code)

---

## ADR-001: PostgreSQL + TimescaleDB for Data Storage

**Status**: Accepted
**Date**: October 2025
**Deciders**: Architecture Team

### Context

We need a database solution that handles:
- Relational data (users, assets, portfolios, transactions)
- Time-series data (price history, on-chain metrics, sentiment scores)
- Complex queries (joins, aggregations, analytics)
- High write throughput (real-time price updates)
- Efficient time-based queries (last 7 days, last 30 days)

### Alternatives Considered

#### 1. **PostgreSQL Only**
- **Pros**: Simple, well-known, ACID compliant, rich ecosystem
- **Cons**: Not optimized for time-series queries, performance degrades with billions of time-series rows
- **Cost**: Low (managed RDS ~$200/month)

#### 2. **Cassandra + PostgreSQL**
- **Pros**: Excellent for time-series, linear scalability, high write throughput
- **Cons**: Eventually consistent, complex operations team, no joins, separate databases increase complexity
- **Cost**: High (managed Cassandra ~$800/month + PostgreSQL ~$200/month)

#### 3. **InfluxDB + PostgreSQL**
- **Pros**: Purpose-built for time-series, efficient compression, InfluxQL query language
- **Cons**: Separate database increases complexity, limited ecosystem, licensing concerns (InfluxDB 2.0+)
- **Cost**: Medium (managed InfluxDB ~$400/month + PostgreSQL ~$200/month)

#### 4. **PostgreSQL + TimescaleDB (Extension)**
- **Pros**: Single database for both relational and time-series, full SQL support, automatic partitioning, excellent compression, PostgreSQL ecosystem compatibility
- **Cons**: Slightly more complex than vanilla PostgreSQL, single point of failure (mitigated by replication)
- **Cost**: Medium (managed TimescaleDB RDS ~$350/month)

### Decision

**Chosen**: PostgreSQL + TimescaleDB

**Rationale**:
1. **Unified Database**: Single database for all data reduces operational complexity, simplifies transactions, enables joins between relational and time-series data
2. **SQL Compatibility**: Team expertise in SQL, no need to learn new query language
3. **Performance**: Hypertables provide 10-100x faster queries on time-series data compared to vanilla PostgreSQL
4. **Compression**: Automatic compression reduces storage costs by 90%+ for time-series data
5. **Ecosystem**: Full PostgreSQL ecosystem (ORMs, tools, extensions)
6. **Cost**: More economical than multi-database approach

### Consequences

**Positive**:
- ✅ Simplified architecture (one database instead of two)
- ✅ Fast time-series queries with standard SQL
- ✅ Excellent PostgreSQL tooling support
- ✅ Easier to maintain consistency across data types

**Negative**:
- ❌ Requires team to learn TimescaleDB-specific features (hypertables, continuous aggregates)
- ❌ Scaling limitations compared to Cassandra (vertical scaling primarily)
- ❌ Single database dependency (mitigated with read replicas)

**Migration Path**: If write throughput exceeds TimescaleDB capacity (>100K writes/sec), migrate time-series data to Cassandra while keeping relational data in PostgreSQL.

---

## ADR-002: FastAPI for Backend Framework

**Status**: Accepted
**Date**: October 2025
**Deciders**: Backend Team

### Context

We need a Python backend framework that supports:
- RESTful API development
- WebSocket support (real-time price updates, alerts)
- High performance (low latency for predictions)
- Async/await patterns (concurrent external API calls)
- Automatic API documentation
- Type safety and validation

### Alternatives Considered

#### 1. **Django + Django REST Framework (DRF)**
- **Pros**: Mature, batteries-included, excellent ORM, admin panel, large ecosystem
- **Cons**: Synchronous (limited async support), slower performance, heavyweight for API-only service
- **Performance**: ~1,000 req/sec

#### 2. **Flask + Flask-RESTful**
- **Pros**: Lightweight, flexible, large ecosystem, team familiarity
- **Cons**: Synchronous, no built-in validation, manual API docs, requires many extensions
- **Performance**: ~1,500 req/sec

#### 3. **FastAPI**
- **Pros**: Async/await native, automatic OpenAPI docs, Pydantic validation, high performance, modern Python (3.11+), type hints
- **Cons**: Younger ecosystem, fewer third-party packages than Django/Flask
- **Performance**: ~10,000+ req/sec

#### 4. **aiohttp**
- **Pros**: Pure async, high performance, low-level control
- **Cons**: Low-level (requires more boilerplate), no automatic validation/docs, smaller ecosystem
- **Performance**: ~12,000+ req/sec

### Decision

**Chosen**: FastAPI

**Rationale**:
1. **Performance**: 5-10x faster than Django/Flask due to async support and Starlette foundation
2. **Async Native**: Critical for ML predictions (concurrent feature fetching), external API calls (CoinAPI, Amberdata), WebSocket connections
3. **Developer Experience**: Automatic OpenAPI/Swagger docs, Pydantic validation, type safety reduces bugs
4. **Modern Python**: Leverages Python 3.11+ features (type hints, async/await)
5. **Validation**: Built-in request/response validation via Pydantic reduces boilerplate
6. **WebSocket Support**: First-class WebSocket support for real-time features

### Consequences

**Positive**:
- ✅ High performance meets SLA requirements (<500ms API response)
- ✅ Async/await enables efficient concurrent operations
- ✅ Automatic API documentation (OpenAPI/Swagger)
- ✅ Type safety catches errors at development time
- ✅ Less boilerplate code compared to Flask

**Negative**:
- ❌ Smaller ecosystem than Django (fewer third-party packages)
- ❌ Team needs to learn async programming patterns
- ❌ No built-in admin panel (mitigated with custom admin or third-party)

**Migration Path**: None anticipated. FastAPI is suitable for current and future scale.

---

## ADR-003: Apache Kafka for Message Streaming

**Status**: Accepted
**Date**: October 2025
**Deciders**: Data Engineering Team

### Context

We need a message streaming platform to:
- Ingest real-time price updates from external APIs
- Distribute events to multiple consumers (API service, ML service, analytics)
- Decouple microservices
- Provide replay capability (reprocess historical events)
- Handle high throughput (1000+ messages/sec)

### Alternatives Considered

#### 1. **RabbitMQ**
- **Pros**: Mature, flexible routing, AMQP protocol, easier to operate
- **Cons**: Lower throughput, no event replay, messages deleted after consumption, not designed for streaming
- **Throughput**: ~10K msg/sec
- **Cost**: AWS MQ ~$150/month

#### 2. **AWS Kinesis**
- **Pros**: Fully managed, AWS integration, auto-scaling, simple setup
- **Cons**: AWS vendor lock-in, limited retention (max 365 days), higher cost at scale, limited partition control
- **Throughput**: ~1M msg/sec
- **Cost**: ~$500/month (at our volume)

#### 3. **Apache Kafka (AWS MSK)**
- **Pros**: High throughput, infinite retention, replay capability, industry standard, rich ecosystem, flexible partitioning
- **Cons**: Complex to operate (mitigated by AWS MSK), steeper learning curve
- **Throughput**: ~10M msg/sec
- **Cost**: AWS MSK ~$400/month

#### 4. **Redis Streams**
- **Pros**: Simple, already using Redis for caching, low latency
- **Cons**: Not designed for high-volume streaming, limited consumer groups, memory-bound
- **Throughput**: ~100K msg/sec
- **Cost**: Included in ElastiCache

### Decision

**Chosen**: Apache Kafka (AWS MSK - Managed Streaming for Kafka)

**Rationale**:
1. **Throughput**: Can handle 10M+ messages/sec, future-proof for growth
2. **Replay Capability**: Essential for ML model retraining (reprocess historical price data)
3. **Durability**: Persistent storage enables event replay, debugging, auditing
4. **Decoupling**: Multiple consumers can read same events independently
5. **Industry Standard**: Large ecosystem (Kafka Connect, Kafka Streams), extensive tooling
6. **AWS MSK**: Managed service reduces operational burden

### Consequences

**Positive**:
- ✅ High throughput supports current and future scale
- ✅ Event replay enables ML model retraining without re-fetching data
- ✅ Decoupled architecture enables independent microservice scaling
- ✅ Strong consistency and durability guarantees
- ✅ Rich ecosystem (Kafka Connect for integrations)

**Negative**:
- ❌ More complex than RabbitMQ or Redis Streams
- ❌ Team needs to learn Kafka concepts (topics, partitions, consumer groups)
- ❌ Higher operational overhead (mitigated by AWS MSK)
- ❌ Higher cost than RabbitMQ

**Migration Path**: None anticipated. Kafka is industry standard for event streaming.

---

## ADR-004: Medallion Architecture for Data Pipeline

**Status**: Accepted
**Date**: October 2025
**Deciders**: Data Engineering Team

### Context

We need a data pipeline architecture to:
- Ingest raw data from multiple external APIs
- Clean, transform, and enrich data
- Serve data to API and ML models
- Support data quality monitoring
- Enable data lineage tracking

### Alternatives Considered

#### 1. **Lambda Architecture**
- **Pros**: Handles both batch and streaming, proven at scale (Netflix, LinkedIn)
- **Cons**: Dual codebases (batch + stream), complex to maintain, data inconsistency between layers
- **Diagram**: Raw → Batch Layer + Speed Layer → Serving Layer

#### 2. **Kappa Architecture**
- **Pros**: Single streaming pipeline, simpler than Lambda, easier to maintain
- **Cons**: Requires reprocessing entire stream for batch corrections, not ideal for complex transformations
- **Diagram**: Raw → Stream Processing → Serving Layer

#### 3. **Medallion Architecture (Bronze → Silver → Gold)**
- **Pros**: Clear data quality zones, incremental refinement, data lineage, supports both batch and streaming, Databricks best practice
- **Cons**: More storage tiers, slightly more complex than Kappa
- **Diagram**: Bronze (Raw) → Silver (Cleaned) → Gold (Aggregated/Business)

### Decision

**Chosen**: Medallion Architecture

**Rationale**:
1. **Data Quality**: Clear progression from raw → clean → refined makes quality issues easy to diagnose
2. **Flexibility**: Supports both batch and streaming without dual codebases
3. **Debugging**: Can trace data lineage from Gold → Silver → Bronze
4. **Reprocessing**: Can reprocess Silver/Gold from Bronze without re-ingesting
5. **Best Practice**: Databricks-recommended pattern, proven in production
6. **Incremental**: Can fix issues in Silver layer without touching Bronze

**Layer Definitions**:
- **Bronze**: Raw data as-is from external APIs (S3, JSON/Parquet)
- **Silver**: Cleaned, validated, deduplicated data (S3, Parquet)
- **Gold**: Aggregated, business-ready data (TimescaleDB/PostgreSQL)

### Consequences

**Positive**:
- ✅ Clear data quality zones enable easier debugging
- ✅ Can reprocess without re-ingesting from external APIs (saves cost)
- ✅ Data lineage is explicit (Gold sources from Silver sources from Bronze)
- ✅ Incremental improvements (fix Silver without touching Bronze)
- ✅ Supports both batch and streaming use cases

**Negative**:
- ❌ More storage tiers than Lambda/Kappa (3 vs 2)
- ❌ Additional processing stages (Bronze → Silver → Gold)
- ❌ Requires S3 lifecycle policies to manage storage costs

**Migration Path**: None anticipated. Medallion is suitable for current and future scale.

---

## ADR-005: LSTM + ARIMA Ensemble for Price Predictions

**Status**: Accepted
**Date**: October 2025
**Deciders**: ML Team

### Context

We need a price prediction model that:
- Provides 7-day and 30-day price forecasts
- Handles both short-term and long-term patterns
- Performs well with limited RWA historical data
- Is interpretable (Explainable AI requirement)
- Can be trained and retrained efficiently

### Alternatives Considered

#### 1. **ARIMA Only**
- **Pros**: Simple, interpretable, works with small datasets, fast training
- **Cons**: Assumes linear relationships, struggles with non-stationary data, poor for complex patterns
- **Accuracy**: MAPE ~15-20% (7-day), ~25-30% (30-day)

#### 2. **LSTM Only**
- **Pros**: Captures long-term dependencies, handles non-linear patterns, proven for time-series
- **Cons**: Requires large datasets, black box (hard to explain), prone to overfitting with limited data
- **Accuracy**: MAPE ~10-15% (7-day), ~20-25% (30-day) with sufficient data

#### 3. **Prophet (Facebook)**
- **Pros**: Handles seasonality well, interpretable, robust to missing data
- **Cons**: Optimized for business metrics (not financial), slower than ARIMA, limited customization
- **Accuracy**: MAPE ~12-18% (7-day), ~22-28% (30-day)

#### 4. **Transformer Models (Temporal Fusion Transformer)**
- **Pros**: State-of-the-art for time-series, handles multiple covariates, attention mechanism
- **Cons**: Requires massive datasets, computationally expensive, complex to interpret
- **Accuracy**: MAPE ~8-12% (7-day), ~18-22% (30-day) with massive data

#### 5. **LSTM + ARIMA Ensemble**
- **Pros**: Combines ARIMA's linear strength with LSTM's pattern recognition, works with limited data, more robust than single model
- **Cons**: More complex than single model, requires tuning ensemble weights
- **Accuracy**: MAPE ~12-16% (7-day), ~20-24% (30-day)

### Decision

**Chosen**: LSTM + ARIMA Ensemble with weighted averaging

**Ensemble Strategy**:
```python
# Weighted average based on validation performance
final_prediction = (0.6 * lstm_prediction) + (0.4 * arima_prediction)

# Adaptive weighting based on data availability
if historical_days < 90:
    arima_weight = 0.7  # More weight to ARIMA with limited data
else:
    arima_weight = 0.3  # More weight to LSTM with sufficient data
```

**Rationale**:
1. **Robustness**: Ensemble reduces overfitting risk from either model alone
2. **Limited Data**: ARIMA performs well with limited RWA historical data
3. **Pattern Recognition**: LSTM captures complex patterns as data grows
4. **Interpretability**: ARIMA component provides explainable linear trends
5. **Adaptability**: Can adjust weights based on data availability per asset
6. **MVP Ready**: ARIMA-only for Phase 1, add LSTM in Phase 2

### Consequences

**Positive**:
- ✅ More robust predictions than single model
- ✅ Works well with limited RWA historical data (ARIMA component)
- ✅ Improves as data grows (LSTM component)
- ✅ Partially interpretable (ARIMA trend + LSTM patterns)
- ✅ Phased rollout (ARIMA MVP → Ensemble Phase 2)

**Negative**:
- ❌ More complex than single model
- ❌ Requires tuning ensemble weights
- ❌ Slower training than single model
- ❌ LSTM still requires significant data (90+ days minimum)

**Migration Path**:
- **Phase 1 (MVP)**: ARIMA only for 7-day predictions
- **Phase 2**: Add LSTM, create ensemble for 7-day and 30-day predictions
- **Phase 3**: Add XGBoost to ensemble if accuracy improves

---

## ADR-006: Microservices Architecture

**Status**: Accepted
**Date**: October 2025
**Deciders**: Architecture Team

### Context

We need an architecture that:
- Enables independent scaling of components (API, ML, data ingestion)
- Allows independent deployment (deploy ML model updates without touching API)
- Supports team autonomy (frontend, backend, ML teams work independently)
- Handles varying load patterns (API spikes during market hours, ML batch processing)

### Alternatives Considered

#### 1. **Monolith**
- **Pros**: Simple deployment, easy local development, no network latency between components
- **Cons**: Tight coupling, single point of failure, difficult to scale independently, deployment bottlenecks
- **Team Size**: Best for teams <10 developers

#### 2. **Modular Monolith**
- **Pros**: Clear module boundaries, simpler than microservices, easier to refactor to microservices later
- **Cons**: Still single deployment unit, limited independent scaling, shared database
- **Team Size**: Best for teams 10-25 developers

#### 3. **Microservices**
- **Pros**: Independent scaling/deployment, technology flexibility, fault isolation, team autonomy
- **Cons**: Operational complexity, network latency, distributed transactions, requires orchestration
- **Team Size**: Best for teams >15 developers

### Decision

**Chosen**: Microservices Architecture

**Service Boundaries**:
1. **API Service** (FastAPI) - User-facing REST/WebSocket API
2. **ML Service** (Python) - Price predictions, risk scoring, sentiment analysis
3. **Data Ingestion Services** (Python) - Price, on-chain, news, fundamentals ingestion
4. **Alert Service** (Python) - Alert monitoring and notification
5. **Frontend** (React) - Web application

**Rationale**:
1. **Independent Scaling**: ML service scales for batch predictions, API service scales for user traffic
2. **Independent Deployment**: Deploy ML model updates without touching API
3. **Technology Flexibility**: Use PyTorch for ML, FastAPI for API
4. **Fault Isolation**: ML service failure doesn't crash API (serves cached predictions)
5. **Team Structure**: Aligns with team boundaries (API team, ML team, data team)

### Consequences

**Positive**:
- ✅ Scale ML service independently during batch prediction jobs
- ✅ Deploy ML model updates without API downtime
- ✅ Teams can work independently with clear contracts (API specs)
- ✅ Fault isolation (one service failure doesn't cascade)
- ✅ Technology flexibility (different languages per service)

**Negative**:
- ❌ Operational complexity (more services to monitor)
- ❌ Network latency between services
- ❌ Distributed transactions complexity
- ❌ Requires service discovery, orchestration (Kubernetes)
- ❌ More complex local development setup

**Migration Path**: Start with 3 core services (API, ML, Ingestion), add more as needed. If operational complexity becomes too high, consolidate related services.

---

## ADR-007: React + TypeScript for Frontend

**Status**: Accepted
**Date**: October 2025
**Deciders**: Frontend Team

### Context

We need a frontend framework that:
- Supports complex dashboards with real-time data
- Handles interactive charts (price history, predictions)
- Provides type safety (reduces bugs)
- Has rich ecosystem (charting, state management)
- Enables mobile app development (future React Native)

### Alternatives Considered

#### 1. **React + JavaScript**
- **Pros**: Huge ecosystem, flexible, large talent pool
- **Cons**: No type safety, runtime errors, poor IDE support
- **Bundle Size**: ~300KB

#### 2. **React + TypeScript**
- **Pros**: Type safety, excellent IDE support, catches errors at compile time, easier refactoring
- **Cons**: Steeper learning curve, more boilerplate
- **Bundle Size**: ~300KB (types stripped at build)

#### 3. **Vue.js + TypeScript**
- **Pros**: Simpler than React, great documentation, growing ecosystem
- **Cons**: Smaller ecosystem than React, fewer charting libraries, less React Native synergy
- **Bundle Size**: ~250KB

#### 4. **Angular**
- **Pros**: Full framework (batteries included), TypeScript native, enterprise-proven
- **Cons**: Heavyweight, steeper learning curve, more opinionated, larger bundles
- **Bundle Size**: ~500KB

#### 5. **Svelte**
- **Pros**: Smallest bundles, compile-time framework, simple syntax
- **Cons**: Small ecosystem, fewer libraries, less proven at scale, limited talent pool
- **Bundle Size**: ~150KB

### Decision

**Chosen**: React 18+ with TypeScript

**Technology Stack**:
- **Framework**: React 18 (concurrent rendering, suspense)
- **Language**: TypeScript 5+
- **State Management**: Redux Toolkit (for complex global state)
- **Styling**: Tailwind CSS (utility-first)
- **Charts**: D3.js (custom charts) + Recharts (standard charts)
- **Build Tool**: Vite (fast HMR)

**Rationale**:
1. **Type Safety**: TypeScript catches errors at compile time, critical for complex financial data
2. **Ecosystem**: Largest ecosystem (D3.js, Recharts, charting libraries)
3. **React Native**: Enables future mobile app with code sharing
4. **Performance**: React 18 concurrent features optimize dashboard rendering
5. **Talent Pool**: Largest talent pool for hiring
6. **Proven**: Proven at scale (Facebook, Airbnb, Netflix)

### Consequences

**Positive**:
- ✅ Type safety reduces bugs in complex financial calculations
- ✅ Excellent charting ecosystem (D3.js, Recharts, TradingView)
- ✅ React Native path for mobile app
- ✅ Large talent pool for hiring
- ✅ Concurrent rendering optimizes dashboard performance

**Negative**:
- ❌ TypeScript learning curve for team
- ❌ More boilerplate than Vue/Svelte
- ❌ Requires careful optimization for large datasets

**Migration Path**: None anticipated. React is suitable for current and future needs.

---

## ADR-008: Kubernetes on AWS EKS for Orchestration

**Status**: Accepted
**Date**: October 2025
**Deciders**: DevOps Team

### Context

We need a container orchestration platform that:
- Manages microservices deployment
- Provides auto-scaling (horizontal pod autoscaling)
- Enables zero-downtime deployments
- Supports multi-environment (dev, staging, production)
- Provides service discovery and load balancing

### Alternatives Considered

#### 1. **AWS ECS (Elastic Container Service)**
- **Pros**: AWS-native, simpler than Kubernetes, lower learning curve, cheaper
- **Cons**: AWS vendor lock-in, less flexible than Kubernetes, smaller ecosystem
- **Cost**: ~$200/month (Fargate)
- **Complexity**: Low

#### 2. **AWS EKS (Elastic Kubernetes Service)**
- **Pros**: Industry standard, cloud-agnostic (multi-cloud ready), rich ecosystem, flexibility
- **Cons**: Complex, steeper learning curve, higher operational overhead
- **Cost**: ~$400/month (managed control plane $73 + worker nodes ~$350)
- **Complexity**: High

#### 3. **Docker Compose (Self-Managed)**
- **Pros**: Simple, great for local development, low learning curve
- **Cons**: Not production-ready, no auto-scaling, manual orchestration, no multi-node support
- **Cost**: $0 (infrastructure cost only)
- **Complexity**: Very Low

#### 4. **Nomad (HashiCorp)**
- **Pros**: Simpler than Kubernetes, flexible (supports VMs + containers), HashiCorp ecosystem
- **Cons**: Smaller ecosystem, less proven at scale, limited managed options
- **Cost**: ~$300/month (self-managed)
- **Complexity**: Medium

### Decision

**Chosen**: AWS EKS (Elastic Kubernetes Service)

**Configuration**:
- **Control Plane**: AWS-managed
- **Worker Nodes**: Auto-scaling groups (2-10 nodes)
- **Namespaces**: `dev`, `staging`, `production`
- **Ingress**: AWS ALB Ingress Controller
- **Monitoring**: Prometheus + Grafana
- **Service Mesh**: Istio (Phase 3)

**Rationale**:
1. **Industry Standard**: Kubernetes skills are transferable, large community
2. **Cloud-Agnostic**: Can migrate to GCP/Azure if needed (avoid AWS lock-in)
3. **Ecosystem**: Rich ecosystem (Helm, Prometheus, Istio, service meshes)
4. **Auto-Scaling**: Horizontal pod autoscaling based on CPU/memory/custom metrics
5. **Future-Proof**: Scales from MVP to enterprise without migration

### Consequences

**Positive**:
- ✅ Industry-standard orchestration (Kubernetes skills are valuable)
- ✅ Cloud-agnostic (can migrate to GCP/Azure)
- ✅ Rich ecosystem (Helm charts, operators)
- ✅ Auto-scaling supports traffic spikes
- ✅ Zero-downtime deployments (rolling updates)

**Negative**:
- ❌ Steep learning curve for team
- ❌ Operational complexity (requires DevOps expertise)
- ❌ Higher cost than ECS
- ❌ More YAML configuration than ECS

**Migration Path**: Start with simple deployments (Deployment + Service), add complexity (Helm, Istio, GitOps) as team matures. If complexity becomes overwhelming, migrate to ECS.

---

## ADR-009: Redis for Caching Layer

**Status**: Accepted
**Date**: October 2025
**Deciders**: Backend Team

### Context

We need a caching layer to:
- Cache API responses (reduce database load)
- Cache ML predictions (avoid recomputing)
- Store session data (user authentication)
- Rate limiting (API throttling)
- Real-time features (pub/sub for WebSocket)

### Alternatives Considered

#### 1. **In-Memory Cache (Application-Level)**
- **Pros**: Zero latency, no network overhead, simple
- **Cons**: Not shared across instances, lost on restart, limited memory
- **Cost**: $0
- **Latency**: <1ms

#### 2. **Memcached**
- **Pros**: Simple, fast, distributed caching
- **Cons**: No persistence, limited data structures (key-value only), no pub/sub
- **Cost**: AWS ElastiCache ~$50/month
- **Latency**: ~1ms

#### 3. **Redis**
- **Pros**: Rich data structures (lists, sets, sorted sets), persistence, pub/sub, Lua scripting, proven at scale
- **Cons**: Single-threaded (per instance), slightly more complex than Memcached
- **Cost**: AWS ElastiCache ~$100/month
- **Latency**: ~1ms

#### 4. **DynamoDB (AWS)**
- **Pros**: Fully managed, auto-scaling, serverless
- **Cons**: Higher latency than Redis, more expensive, less flexible
- **Cost**: ~$200/month (at our traffic)
- **Latency**: ~5-10ms

### Decision

**Chosen**: Redis (AWS ElastiCache)

**Use Cases**:
1. **API Response Caching**: Cache asset details, screener results (TTL: 1 minute)
2. **ML Prediction Caching**: Cache 7-day/30-day predictions (TTL: 1 hour)
3. **Session Storage**: Store JWT refresh tokens, user sessions (TTL: 24 hours)
4. **Rate Limiting**: Track API request counts per user (sliding window)
5. **Pub/Sub**: WebSocket message distribution (price updates, alerts)

**Configuration**:
- **Type**: ElastiCache for Redis 7.0
- **Instance**: cache.t4g.medium (2 vCPU, 3.09 GB RAM)
- **Replication**: Multi-AZ with read replicas
- **Persistence**: AOF (Append-Only File) enabled

**Rationale**:
1. **Rich Data Structures**: Sorted sets for leaderboards, lists for queues, pub/sub for WebSocket
2. **Performance**: Sub-millisecond latency (critical for <500ms API SLA)
3. **Persistence**: AOF ensures cache survives restarts
4. **Ecosystem**: Well-supported by FastAPI, Python libraries
5. **Cost**: More economical than DynamoDB for high-traffic caching

### Consequences

**Positive**:
- ✅ Sub-millisecond latency meets SLA requirements
- ✅ Rich data structures enable rate limiting, pub/sub, caching
- ✅ Persistence prevents cold starts
- ✅ Proven at scale (Twitter, GitHub, StackOverflow use Redis)
- ✅ Reduces database load by 80%+

**Negative**:
- ❌ Single-threaded per instance (mitigated with clustering)
- ❌ Requires cache invalidation strategy
- ❌ Memory-bound (must monitor memory usage)

**Migration Path**: Start with single ElastiCache instance, add read replicas as traffic grows, enable Redis Cluster if dataset exceeds single instance memory.

---

## ADR-010: JWT for Authentication

**Status**: Accepted
**Date**: October 2025
**Deciders**: Backend Team

### Context

We need an authentication mechanism that:
- Supports stateless authentication (microservices)
- Enables API access (mobile apps, third-party integrations)
- Provides short-lived access tokens
- Supports token refresh without re-login
- Enables role-based access control (RBAC)

### Alternatives Considered

#### 1. **Session-Based Authentication (Cookies)**
- **Pros**: Simple, secure (HttpOnly cookies), well-understood
- **Cons**: Stateful (requires session store), difficult to scale across microservices, CSRF vulnerabilities
- **Scalability**: Requires shared session store (Redis)

#### 2. **OAuth 2.0 (Third-Party)**
- **Pros**: Industry standard, proven, delegates authentication to Google/GitHub
- **Cons**: Dependency on third parties, complex setup, not suitable for all users
- **Use Case**: Social login only

#### 3. **JWT (JSON Web Tokens)**
- **Pros**: Stateless, self-contained, works across microservices, no server-side session storage, supports mobile/API
- **Cons**: Token revocation complexity, larger payload than session ID, token theft risk (mitigated with short expiry)
- **Scalability**: Fully stateless

#### 4. **API Keys**
- **Pros**: Simple, suitable for server-to-server
- **Cons**: No expiry (long-lived), difficult to rotate, no user identity, no fine-grained permissions
- **Use Case**: Enterprise API access only

### Decision

**Chosen**: JWT (JSON Web Tokens) with Refresh Token Pattern

**Token Strategy**:
```python
# Access Token (short-lived)
access_token = {
    "sub": "user_id",
    "email": "user@example.com",
    "tier": "professional",  # SaaS tier
    "permissions": ["read:assets", "write:portfolio"],
    "exp": now + 15_minutes
}

# Refresh Token (long-lived, stored in Redis)
refresh_token = {
    "sub": "user_id",
    "jti": "unique_token_id",  # for revocation
    "exp": now + 7_days
}
```

**Configuration**:
- **Algorithm**: RS256 (asymmetric keys)
- **Access Token TTL**: 15 minutes
- **Refresh Token TTL**: 7 days (stored in Redis with revocation support)
- **Key Rotation**: Every 90 days

**Rationale**:
1. **Stateless**: No server-side session storage, scales horizontally
2. **Microservices**: Self-contained tokens work across all services
3. **Mobile/API Support**: Works with React Native, third-party API clients
4. **Fine-Grained Permissions**: Include SaaS tier and permissions in token
5. **Security**: Short-lived access tokens limit theft damage, refresh tokens stored in Redis for revocation

### Consequences

**Positive**:
- ✅ Stateless authentication scales horizontally
- ✅ Works across all microservices without session sharing
- ✅ Supports mobile apps and API clients
- ✅ Fine-grained RBAC via token claims
- ✅ Short expiry limits theft impact (15 minutes)

**Negative**:
- ❌ Token revocation requires Redis lookup (breaks stateless model)
- ❌ Larger payload than session ID (~500 bytes vs 32 bytes)
- ❌ Client must handle token refresh logic
- ❌ Token theft risk (mitigated with short expiry + HttpOnly cookies for web)

**Migration Path**: None anticipated. JWT is industry standard for stateless authentication.

---

## ADR-011: Apache Spark for Stream Processing

**Status**: Accepted
**Date**: October 2025
**Deciders**: Data Engineering Team

### Context

We need a stream processing engine to:
- Process real-time data from Kafka (price updates, on-chain events)
- Transform Bronze → Silver → Gold in real-time
- Join streams (enrich price data with on-chain metrics)
- Aggregate time-series data (1-minute, 5-minute, 1-hour candles)
- Write to TimescaleDB and S3

### Alternatives Considered

#### 1. **Apache Flink**
- **Pros**: True stream processing, low latency (<1 second), exactly-once semantics, stateful processing
- **Cons**: Steeper learning curve, smaller ecosystem than Spark, more complex operations
- **Latency**: <1 second
- **Cost**: Self-managed on Kubernetes

#### 2. **Kafka Streams**
- **Pros**: Simple, tightly integrated with Kafka, lightweight, embedded (no separate cluster)
- **Cons**: Limited to Kafka, less flexible than Spark/Flink, Java/Scala only
- **Latency**: 1-5 seconds
- **Cost**: Included in Kafka

#### 3. **Apache Spark Structured Streaming**
- **Pros**: Unified batch + streaming, DataFrame API (familiar to team), rich ecosystem, SQL support, good documentation
- **Cons**: Micro-batch processing (not true streaming), higher latency than Flink
- **Latency**: 5-30 seconds (micro-batches)
- **Cost**: AWS EMR ~$300/month or self-managed on Kubernetes

#### 4. **AWS Kinesis Data Analytics**
- **Pros**: Fully managed, simple setup, auto-scaling
- **Cons**: AWS vendor lock-in, limited flexibility, SQL-only, expensive at scale
- **Latency**: 5-10 seconds
- **Cost**: ~$500/month

### Decision

**Chosen**: Apache Spark Structured Streaming

**Configuration**:
- **Deployment**: Self-managed on Kubernetes (cost optimization)
- **Micro-Batch Interval**: 10 seconds (balance latency vs throughput)
- **Checkpointing**: S3 (fault tolerance)
- **Output Modes**: Append (time-series inserts), Update (aggregations)

**Rationale**:
1. **Unified API**: Same code for batch and streaming (Bronze → Silver reprocessing)
2. **DataFrame API**: Familiar to team (Pandas-like), easier than Flink's low-level API
3. **Ecosystem**: Rich ecosystem (Kafka connector, JDBC, S3, Delta Lake)
4. **SQL Support**: Can use SQL for transformations (easier for analysts)
5. **Latency Acceptable**: 10-second micro-batches are acceptable (price updates every 1 minute)
6. **Cost**: Self-managed on Kubernetes is cheaper than AWS Kinesis

### Consequences

**Positive**:
- ✅ Unified batch + streaming simplifies codebase
- ✅ DataFrame API is familiar to team (Pandas experience)
- ✅ Rich ecosystem (connectors, libraries)
- ✅ SQL support enables analyst-friendly transformations
- ✅ Checkpointing provides fault tolerance

**Negative**:
- ❌ Higher latency than Flink (10-30 seconds vs <1 second)
- ❌ Micro-batch model is less efficient than true streaming
- ❌ Self-managed on Kubernetes requires operational expertise
- ❌ Resource-intensive (requires dedicated cluster)

**Migration Path**: If latency requirements drop below 5 seconds, migrate to Apache Flink. If operational burden is too high, migrate to AWS Kinesis Data Analytics.

---

## ADR-012: S3 for Data Lake Storage

**Status**: Accepted
**Date**: October 2025
**Deciders**: Data Engineering Team

### Context

We need a data lake to:
- Store raw data from external APIs (Bronze layer)
- Store cleaned/transformed data (Silver layer)
- Archive historical data for ML model retraining
- Support petabyte-scale growth
- Enable cost-effective long-term storage

### Alternatives Considered

#### 1. **AWS S3**
- **Pros**: Industry standard, 11 nines durability, lifecycle policies, cheap storage ($0.023/GB/month), integrates with all AWS services
- **Cons**: AWS vendor lock-in (mitigated with S3-compatible APIs)
- **Cost**: $23/TB/month (Standard), $12/TB/month (Infrequent Access), $1/TB/month (Glacier)

#### 2. **Google Cloud Storage**
- **Pros**: Similar features to S3, slightly cheaper, good BigQuery integration
- **Cons**: Requires multi-cloud setup, less mature ecosystem than S3
- **Cost**: $20/TB/month (Standard)

#### 3. **Azure Blob Storage**
- **Pros**: Similar features to S3, good Azure integration
- **Cons**: Requires multi-cloud setup, less mature ecosystem than S3
- **Cost**: $18/TB/month (Hot), $10/TB/month (Cool)

#### 4. **HDFS (Hadoop Distributed File System)**
- **Pros**: Self-managed, no egress costs, good for on-prem
- **Cons**: Complex to operate, requires dedicated infrastructure, expensive
- **Cost**: ~$50/TB/month (storage + compute + operations)

#### 5. **MinIO (Self-Hosted S3-Compatible)**
- **Pros**: S3-compatible API, self-managed, no vendor lock-in, cheap
- **Cons**: Requires Kubernetes management, lower durability than S3, operations burden
- **Cost**: ~$15/TB/month (storage + operations)

### Decision

**Chosen**: AWS S3 with Lifecycle Policies

**Bucket Structure**:
```
rwa-prime-data-lake/
├── bronze/
│   ├── price_data/         # Raw price data from CoinAPI
│   ├── onchain_data/       # Raw on-chain data from Amberdata
│   └── news_data/          # Raw news from NewsAPI
├── silver/
│   ├── price_data/         # Cleaned price data
│   ├── onchain_data/       # Cleaned on-chain data
│   └── news_data/          # Cleaned news data
└── gold/
    └── features/           # ML model features
```

**Lifecycle Policies**:
- **Bronze**: Standard (30 days) → Infrequent Access (90 days) → Glacier (365 days)
- **Silver**: Standard (60 days) → Infrequent Access (180 days)
- **Gold**: Standard (no transition, actively used by ML models)

**Rationale**:
1. **Cost-Effective**: Cheapest option for petabyte-scale storage ($23/TB vs $50/TB HDFS)
2. **Durability**: 11 nines durability (better than self-managed)
3. **Lifecycle Policies**: Automatic cost optimization (move old data to Glacier)
4. **Integration**: Native integration with Spark, Kafka, Airflow
5. **Scalability**: Unlimited storage, no capacity planning

### Consequences

**Positive**:
- ✅ Cheapest storage option at scale
- ✅ No capacity planning (unlimited storage)
- ✅ Lifecycle policies automatically optimize costs
- ✅ 11 nines durability (no data loss)
- ✅ Native AWS integration (EMR, Athena, Glue)

**Negative**:
- ❌ AWS vendor lock-in (mitigated with S3-compatible APIs)
- ❌ Egress costs if migrating to another cloud
- ❌ Eventual consistency for overwrites (not an issue for append-only workloads)

**Migration Path**: None anticipated. S3 is industry standard for data lakes. If multi-cloud is required, use MinIO with S3-compatible API.

---

## ADR-013: BERT for Sentiment Analysis

**Status**: Accepted
**Date**: October 2025
**Deciders**: ML Team

### Context

We need a sentiment analysis model to:
- Analyze RWA-related news articles
- Extract sentiment scores (-1 to +1)
- Understand financial/crypto terminology
- Process 1000+ articles per day
- Provide accurate sentiment for risk scoring

### Alternatives Considered

#### 1. **Rule-Based (VADER, TextBlob)**
- **Pros**: Simple, fast, no training required, interpretable
- **Cons**: Poor accuracy for domain-specific text (finance/crypto), misses context, fixed lexicon
- **Accuracy**: ~60% on financial news
- **Latency**: <1ms per article
- **Cost**: $0

#### 2. **Traditional ML (Naive Bayes, SVM with TF-IDF)**
- **Pros**: Faster than deep learning, interpretable, works with small datasets
- **Cons**: Requires labeled training data, poor at understanding context, fixed vocabulary
- **Accuracy**: ~70% on financial news
- **Latency**: ~10ms per article
- **Cost**: Low

#### 3. **LSTM/GRU (Recurrent Neural Networks)**
- **Pros**: Captures sequential patterns, better than traditional ML
- **Cons**: Requires large labeled datasets, slower than BERT, less accurate than transformers
- **Accuracy**: ~75% on financial news
- **Latency**: ~50ms per article
- **Cost**: Medium

#### 4. **BERT (Bidirectional Encoder Representations from Transformers)**
- **Pros**: State-of-the-art accuracy, pre-trained on massive corpus, fine-tunable, understands context
- **Cons**: Slower than traditional ML, requires GPU for inference, larger model size
- **Accuracy**: ~85-90% on financial news
- **Latency**: ~100ms per article (GPU), ~500ms (CPU)
- **Cost**: Medium-High (GPU required)

#### 5. **FinBERT (BERT fine-tuned for financial text)**
- **Pros**: Pre-trained on financial news, best accuracy for financial sentiment
- **Cons**: Same as BERT, requires GPU, limited to financial domain
- **Accuracy**: ~90-92% on financial news
- **Latency**: ~100ms per article (GPU)
- **Cost**: Medium-High

### Decision

**Chosen**: FinBERT (BERT fine-tuned for financial sentiment)

**Model**: `ProsusAI/finbert` from Hugging Face
**Deployment**:
- **Batch Processing**: Process news overnight on GPU instance (cost optimization)
- **Real-Time**: Cache sentiment scores in Redis (TTL: 24 hours)
- **Fallback**: Use VADER for real-time if cache miss (rare)

**Rationale**:
1. **Accuracy**: 90%+ accuracy on financial news (critical for risk scoring)
2. **Pre-Trained**: FinBERT is pre-trained on financial corpus (saves training time)
3. **Context Understanding**: Transformer architecture understands context better than rule-based/traditional ML
4. **Cost Optimization**: Batch processing overnight reduces GPU costs
5. **Proven**: FinBERT is industry standard for financial sentiment

### Consequences

**Positive**:
- ✅ High accuracy (90%+) improves risk scoring quality
- ✅ Pre-trained model requires no labeled training data
- ✅ Understands financial/crypto terminology
- ✅ Batch processing optimizes GPU costs
- ✅ Caching prevents redundant processing

**Negative**:
- ❌ Requires GPU for inference (cost: ~$200/month for batch processing)
- ❌ Higher latency than rule-based (mitigated with caching)
- ❌ Larger model size (440MB) vs rule-based (<1MB)
- ❌ Black box (less interpretable than rule-based)

**Migration Path**:
- **Phase 1**: Use VADER (rule-based) for MVP
- **Phase 2**: Migrate to FinBERT with batch processing
- **Phase 3**: Explore fine-tuning FinBERT on RWA-specific news corpus

---

## ADR-014: GitHub Actions for CI/CD

**Status**: Accepted
**Date**: October 2025
**Deciders**: DevOps Team

### Context

We need a CI/CD platform that:
- Runs automated tests on every PR
- Builds and deploys to Kubernetes
- Integrates with GitHub (our code repository)
- Supports Docker image builds
- Enables documentation validation

### Alternatives Considered

#### 1. **GitHub Actions**
- **Pros**: Native GitHub integration, free for open source (2000 min/month free), simple YAML config, marketplace for actions
- **Cons**: Limited free tier for private repos, less flexible than Jenkins
- **Cost**: $0 (free tier) or $0.008/minute beyond free tier
- **Complexity**: Low

#### 2. **Jenkins**
- **Pros**: Very flexible, self-hosted (no usage limits), rich plugin ecosystem, battle-tested
- **Cons**: Self-hosted (requires maintenance), complex setup, outdated UI, steeper learning curve
- **Cost**: ~$100/month (server costs)
- **Complexity**: High

#### 3. **GitLab CI**
- **Pros**: Similar to GitHub Actions, integrated with GitLab, generous free tier
- **Cons**: Requires migrating from GitHub to GitLab, additional platform
- **Cost**: $0 (free tier) or $19/user/month
- **Complexity**: Low

#### 4. **CircleCI**
- **Pros**: Fast, Docker-native, easy setup, good documentation
- **Cons**: Third-party dependency, costs add up at scale, GitHub integration less native
- **Cost**: $15/month (1 container) or $70/month (5 containers)
- **Complexity**: Low

#### 5. **AWS CodePipeline**
- **Pros**: AWS-native, integrates with EKS/ECR, managed service
- **Cons**: AWS-specific, less flexible, more expensive, YAML config is complex
- **Cost**: $1/pipeline/month + compute costs (~$50/month)
- **Complexity**: Medium

### Decision

**Chosen**: GitHub Actions

**Workflows**:
1. **Test Workflow** (`.github/workflows/test.yml`):
   - Trigger: Every PR, push to main
   - Jobs: Lint, unit tests, integration tests
   - Matrix: Python 3.11, 3.12 (future-proofing)

2. **Build Workflow** (`.github/workflows/build.yml`):
   - Trigger: Push to main, release tags
   - Jobs: Build Docker images, push to ECR

3. **Deploy Workflow** (`.github/workflows/deploy.yml`):
   - Trigger: Manual (workflow_dispatch) or release tags
   - Jobs: Deploy to EKS (dev, staging, production)

4. **Documentation Validation** (`.github/workflows/docs-validation.yml`):
   - Trigger: Every PR
   - Jobs: Link checks, code example validation, spell check

**Rationale**:
1. **Native Integration**: Already using GitHub, no additional platform
2. **Free Tier**: 2000 minutes/month free (sufficient for MVP)
3. **Simple**: YAML config is straightforward, easy for team to learn
4. **Marketplace**: Rich ecosystem of pre-built actions (AWS deploy, Docker build, etc.)
5. **Documentation**: Extensive documentation and community support

### Consequences

**Positive**:
- ✅ Native GitHub integration (no context switching)
- ✅ Free tier covers MVP needs (2000 minutes/month)
- ✅ Simple YAML config (lower learning curve)
- ✅ Rich marketplace (AWS, Docker, Kubernetes actions)
- ✅ Fast feedback on PRs (parallel jobs)

**Negative**:
- ❌ Limited free tier for private repos (may need paid plan at scale)
- ❌ Less flexible than Jenkins (fewer customization options)
- ❌ GitHub dependency (all eggs in one basket)

**Migration Path**: If GitHub Actions becomes too expensive (>$500/month), migrate to self-hosted Jenkins or GitLab CI.

---

## ADR-015: Terraform for Infrastructure as Code

**Status**: Accepted
**Date**: October 2025
**Deciders**: DevOps Team

### Context

We need an Infrastructure as Code (IaC) tool to:
- Provision AWS resources (EKS, RDS, S3, etc.)
- Support multi-environment (dev, staging, production)
- Enable version control for infrastructure
- Provide reproducible deployments
- Support disaster recovery

### Alternatives Considered

#### 1. **Terraform**
- **Pros**: Cloud-agnostic, declarative, large ecosystem (providers), state management, plan/apply workflow
- **Cons**: State file management complexity, no built-in rollback, HCL learning curve
- **Ecosystem**: 3000+ providers (AWS, GCP, Azure, Kubernetes)
- **Maturity**: Very mature (10+ years)

#### 2. **AWS CloudFormation**
- **Pros**: AWS-native, free, integrates with AWS Console, automatic rollback
- **Cons**: AWS-only (vendor lock-in), verbose YAML, slower than Terraform, less flexible
- **Ecosystem**: AWS only
- **Maturity**: Mature (12+ years)

#### 3. **Pulumi**
- **Pros**: Use real programming languages (Python, TypeScript), type safety, testing support, cloud-agnostic
- **Cons**: Younger ecosystem, smaller community, requires programming knowledge
- **Ecosystem**: 100+ providers
- **Maturity**: Young (5 years)

#### 4. **AWS CDK (Cloud Development Kit)**
- **Pros**: Use real programming languages, generates CloudFormation, type safety, AWS-native
- **Cons**: AWS-only (vendor lock-in), abstractions can be leaky, less mature than Terraform
- **Ecosystem**: AWS only
- **Maturity**: Young (4 years)

#### 5. **Ansible**
- **Pros**: Simple YAML, agentless, configuration management + provisioning
- **Cons**: Not designed for cloud provisioning, less declarative, no state management
- **Ecosystem**: Medium
- **Maturity**: Mature (12+ years, but not for IaC)

### Decision

**Chosen**: Terraform

**Structure**:
```
infrastructure/terraform/
├── modules/
│   ├── eks/              # EKS cluster module
│   ├── rds/              # RDS/TimescaleDB module
│   ├── s3/               # S3 buckets module
│   └── vpc/              # VPC/networking module
├── environments/
│   ├── dev/
│   ├── staging/
│   └── production/
└── backend.tf            # S3 backend for state
```

**State Management**:
- **Backend**: S3 bucket with versioning + DynamoDB locking
- **Workspaces**: Separate workspaces per environment (dev, staging, production)

**Rationale**:
1. **Cloud-Agnostic**: Can manage AWS, Kubernetes, and future multi-cloud (avoid vendor lock-in)
2. **Ecosystem**: 3000+ providers (AWS, Kubernetes, Helm, Datadog, PagerDuty)
3. **Plan/Apply**: Preview changes before applying (reduces risk)
4. **Modules**: Reusable modules for DRY infrastructure
5. **Industry Standard**: Most popular IaC tool, large community, extensive documentation

### Consequences

**Positive**:
- ✅ Cloud-agnostic (can migrate to GCP/Azure)
- ✅ Large ecosystem (manage AWS + Kubernetes + monitoring in one place)
- ✅ Plan/apply workflow reduces deployment risk
- ✅ Modules enable DRY infrastructure
- ✅ Large community and documentation

**Negative**:
- ❌ State file management complexity (mitigated with S3 backend)
- ❌ No automatic rollback (must manually revert)
- ❌ HCL learning curve for team
- ❌ Requires careful state locking (mitigated with DynamoDB)

**Migration Path**: None anticipated. Terraform is industry standard for IaC. If team prefers programming languages over HCL, consider Pulumi in future.

---

## Appendix

### How to Use ADRs

**When to Create an ADR**:
- Significant architectural decision (impacts system design)
- Technology choice (database, framework, language)
- Trade-offs exist (multiple valid alternatives)
- Decision has long-term consequences
- Reversal would be costly

**When NOT to Create an ADR**:
- Tactical decisions (which library for CSV parsing)
- Easily reversible decisions (UI component library)
- Implementation details (code style, naming conventions)

**ADR Template**:
```markdown
## ADR-XXX: [Decision Title]

**Status**: [Proposed | Accepted | Deprecated | Superseded]
**Date**: [Month Year]
**Deciders**: [Team Name]

### Context
[What is the issue we're seeing that is motivating this decision?]

### Alternatives Considered
1. **Option A**
   - Pros:
   - Cons:
   - Cost:
2. **Option B**
   - Pros:
   - Cons:
   - Cost:

### Decision
**Chosen**: [Option X]

**Rationale**:
1. [Reason 1]
2. [Reason 2]

### Consequences
**Positive**:
- ✅ [Benefit 1]

**Negative**:
- ❌ [Drawback 1]

**Migration Path**: [How to migrate if this decision needs to be reversed]
```

### Updating ADRs

**When an ADR is Superseded**:
1. Update status to "Superseded by ADR-XXX"
2. Create new ADR documenting the new decision
3. Do NOT delete old ADRs (preserve history)

**When Circumstances Change**:
- Add "Update" section with date and new information
- If decision changes, create new ADR and mark old one as "Superseded"

---

**Last Updated**: October 24, 2025
**Total ADRs**: 15
**Status**: All Accepted
**Next Review**: January 2026

---

**Remember**: ADRs document *why* we made decisions, not just *what* we decided. Future developers will thank you! 📝
