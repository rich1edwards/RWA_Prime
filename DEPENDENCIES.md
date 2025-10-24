# DEPENDENCIES.md

## Overview

This document lists all external dependencies, libraries, APIs, and services required for the RWA-Prime platform.

## External API Dependencies

### Critical Data Sources

| Service | Purpose | Pricing Tier Needed | Est. Monthly Cost | Documentation |
|---------|---------|---------------------|-------------------|---------------|
| **CoinAPI** | Real-time & historical crypto price data | Pro | $329/month | https://www.coinapi.io/ |
| **Amberdata** | Comprehensive blockchain data API | Professional | $500/month | https://www.amberdata.io/ |
| **Bitquery** | RWA-specific blockchain data | Standard | $99/month | https://bitquery.io/solutions/rwa |
| **Financial Modeling Prep** | Crypto price data (backup) | Professional | $29/month | https://site.financialmodelingprep.com/ |
| **RWA.io API** | Off-chain RWA fundamental data | Professional | $299/month | https://www.rwa.io/ |
| **Trading Economics** | Macroeconomic indicators | Basic | $250/month | https://tradingeconomics.com/api/ |
| **World Bank API** | Global development indicators | Free | $0 | https://datahelpdesk.worldbank.org/ |
| **NewsAPI.ai** | Global news aggregation | Business | $449/month | https://newsapi.ai/ |
| **Tradefeeds** | Crypto news with sentiment | Pro | $99/month | https://tradefeeds.com/ |

**Total External API Costs**: ~$2,054/month

### Optional/Future APIs

- Finazon: Alternative price data
- Bloomberg API: TradFi data (enterprise pricing)
- Refinitiv: Financial data (enterprise pricing)
- CryptoCompare: Additional crypto data

## Backend Dependencies

### Python (requirements.txt)

#### Core Framework
```
fastapi==0.104.1
uvicorn[standard]==0.24.0
pydantic==2.4.2
pydantic-settings==2.0.3
```

#### Database & ORM
```
sqlalchemy==2.0.23
alembic==1.12.1
psycopg2-binary==2.9.9
asyncpg==0.29.0
timescale==0.1.0
```

#### Authentication & Security
```
python-jose[cryptography]==3.3.0
passlib[bcrypt]==1.7.4
python-multipart==0.0.6
pyotp==2.9.0
```

#### Data Processing
```
pandas==2.1.3
numpy==1.26.2
apache-kafka-python==2.0.2
pyspark==3.5.0
```

#### ML & NLP
```
torch==2.1.1
scikit-learn==1.3.2
statsmodels==0.14.0
transformers==4.35.2
nltk==3.8.1
```

#### HTTP & Async
```
httpx==0.25.1
aiohttp==3.9.0
websockets==12.0
```

#### AWS & Cloud
```
boto3==1.29.7
botocore==1.32.7
```

#### Utilities
```
python-dotenv==1.0.0
redis==5.0.1
celery==5.3.4
```

### Python Version
**Minimum**: Python 3.11+

## Frontend Dependencies

### package.json

#### Core Framework
```json
{
  "react": "^18.2.0",
  "react-dom": "^18.2.0",
  "react-router-dom": "^6.20.0",
  "typescript": "^5.3.2"
}
```

#### State Management
```json
{
  "@reduxjs/toolkit": "^1.9.7",
  "react-redux": "^8.1.3"
}
```

#### UI Components & Styling
```json
{
  "tailwindcss": "^3.3.5",
  "@headlessui/react": "^1.7.17",
  "@heroicons/react": "^2.0.18"
}
```

#### Data Visualization
```json
{
  "d3": "^7.8.5",
  "recharts": "^2.10.3"
}
```

#### HTTP & WebSocket
```json
{
  "axios": "^1.6.2",
  "socket.io-client": "^4.5.4"
}
```

#### Forms & Validation
```json
{
  "react-hook-form": "^7.48.2",
  "zod": "^3.22.4"
}
```

#### Build Tools
```json
{
  "vite": "^5.0.2",
  "@vitejs/plugin-react": "^4.2.0"
}
```

### Node.js Version
**Minimum**: Node.js 18+  
**Package Manager**: npm or yarn

## Infrastructure Dependencies

### Cloud Services (AWS)

| Service | Purpose | Estimated Cost |
|---------|---------|----------------|
| **EKS** | Kubernetes cluster | $146/month (cluster) + nodes |
| **RDS PostgreSQL** | Relational database | $200/month (db.t3.large Multi-AZ) |
| **MSK** | Managed Kafka | $300/month (kafka.m5.large × 3) |
| **S3** | Data lake storage | $50/month (1TB + requests) |
| **ElastiCache Redis** | Caching layer | $60/month (cache.t3.medium) |
| **CloudFront** | CDN | $20/month (low traffic estimate) |
| **Route 53** | DNS | $1/month |
| **Secrets Manager** | Secret storage | $5/month |
| **CloudWatch** | Monitoring & logs | $30/month |

**Total AWS Infrastructure**: ~$812/month (dev/staging), ~$2,500/month (production with scaling)

### Container Registry
- Docker Hub (Free tier or $5/month Pro)
- Or AWS ECR ($1-10/month)

### CI/CD
- GitHub Actions (Free for public repos, $0.008/minute for private)

### Monitoring & Logging
- Prometheus + Grafana (self-hosted on K8s)
- ELK Stack (self-hosted) or AWS OpenSearch ($100/month managed)

## Development Tools

### Required
- **Docker**: 20.10+
- **Docker Compose**: 2.0+
- **kubectl**: 1.28+
- **terraform**: 1.6+
- **Git**: 2.40+

### Recommended IDEs
- **VS Code** with extensions:
  - Python
  - ESLint
  - Prettier
  - Docker
  - Kubernetes
- **PyCharm Professional** (alternative)

### Database Tools
- **DBeaver** or **pgAdmin** for PostgreSQL management
- **Redis Insight** for Redis

### API Testing
- **Postman** or **Insomnia**

## Third-Party Services

| Service | Purpose | Est. Cost |
|---------|---------|-----------|
| **SendGrid** | Email notifications | $15/month (40K emails) |
| **Twilio** | SMS/2FA (if needed) | Pay-as-you-go (~$50/month) |
| **Sentry** | Error tracking | $26/month (Dev plan) |
| **GitHub** | Code repository | Free (public) or $4/user/month (private) |

## ML Model Dependencies

### Pre-trained Models
- **FinBERT**: Financial sentiment analysis (Hugging Face)
- **BERT-base-uncased**: NLP foundation model (Hugging Face)

### Training Infrastructure
- **GPU**: NVIDIA T4 or better (AWS p3.2xlarge: ~$3/hour)
- Training frequency: Weekly (estimated 4 hours/week)
- **Est. ML training cost**: ~$50/month

## License Compliance

All dependencies use permissive licenses compatible with commercial use:
- **MIT**: FastAPI, React, most libraries
- **Apache 2.0**: TensorFlow, PyTorch
- **BSD**: NumPy, Pandas, scikit-learn

## Version Management

### Backend
- Use `pip-compile` (from pip-tools) for pinning dependencies
- Separate `requirements.txt` (prod) and `requirements-dev.txt` (dev/testing)

### Frontend
- Use `package-lock.json` (npm) or `yarn.lock` (yarn) for deterministic installs

### Docker Base Images
- Python: `python:3.11-slim`
- Node.js: `node:18-alpine`
- NGINX: `nginx:alpine`

## Dependency Update Policy

- **Security patches**: Apply immediately
- **Minor version updates**: Monthly review and testing
- **Major version updates**: Quarterly evaluation, comprehensive testing before upgrade

## Known Version Constraints

- **Python**: Must be >=3.11 for type hinting features
- **PostgreSQL**: >=15 for TimescaleDB 2.x compatibility
- **Node.js**: >=18 for native fetch API
- **Kubernetes**: >=1.26 for autoscaling improvements

## Contingency Plans

### API Provider Failures
- **Price Data**: Primary (CoinAPI) → Fallback (FMP, Finazon)
- **On-Chain Data**: Primary (Amberdata) → Fallback (Bitquery, direct node RPC)
- **News**: Primary (NewsAPI.ai) → Fallback (Tradefeeds, RSS feeds)

### Infrastructure Failures
- Multi-AZ deployment for high availability
- Database backups (automated daily snapshots)
- Disaster recovery plan (documented separately)

---

**Related Documentation**:
- [ARCHITECTURE.md](./ARCHITECTURE.md)
- [DEVELOPMENT_GUIDE.md](./DEVELOPMENT_GUIDE.md)
