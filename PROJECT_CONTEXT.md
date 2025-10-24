# PROJECT_CONTEXT.md

## Project Overview

### Project Name
**RWA-Prime** - Predictive Analytics Engine for Real-World Assets

### Version
1.1 (Draft Phase)

### Project Purpose
RWA-Prime is a web and mobile Software-as-a-Service (SaaS) platform designed to be the definitive predictive analytics engine for Real-World Assets (RWAs) in the crypto space. The platform bridges the gap between traditional finance (TradFi) and decentralized finance (DeFi) by providing an integrated, predictive, and context-aware analytics solution.

### Vision Statement
To become the definitive intelligence layer for the next generation of financial markets by delivering an integrated, predictive, and context-aware analytics solution that synthesizes off-chain fundamental data, on-chain market metrics, and real-time market sentiment into a cohesive framework.

## Target Market

### Primary Market
- **RWA Investors**: Spectrum ranging from retail crypto enthusiasts exploring stable, yield-bearing assets to sophisticated, active traders looking for an edge in the RWA market
- Core design philosophy: Ease-of-use centered on serving the primary investor

### Secondary Market
- **Portfolio Managers**: From crypto-native funds and traditional finance (TradFi) institutions
- **Financial Analysts**: Leveraging advanced features for deep due diligence and reporting

## Core Value Proposition

RWA-Prime ingests and synthesizes:
1. **Off-chain fundamental data**
2. **On-chain market metrics**
3. **Real-time market sentiment**

Into a cohesive, predictive framework that delivers:
- Clear, explainable buy/sell predictive analysis
- Composite risk scores for each asset
- Powerful portfolio management tools
- Simple, intuitive user interface

## Market Opportunity

### Market Size
- RWA tokenization represents a multi-trillion-dollar market opportunity
- RWA sector (excluding stablecoins) experiencing exponential growth
- Fiat-backed stablecoins: $224.9 billion (April 2025)
- Tokenized Treasuries & Government Securities: $5.5 billion (+539% growth from Jan 2024)
- Private Credit: $558.3 million active loans
- Commodities: $1.9 billion market cap

### Market Gap
Current analytics landscape is fragmented:
- **Generalist platforms** (Nansen, Glassnode, Dune) lack off-chain RWA context
- **RWA-specific platforms** (RWA.xyz) lack predictive analytics
- **No platform** integrates off-chain fundamentals, on-chain metrics, AND predictive models
- Forcing users into an "analytics trilemma"

## Technology Stack Summary

### Frontend
- Modern single-page application (SPA)
- React or Vue.js framework
- D3.js for interactive visualizations
- WebSockets for real-time updates
- Mobile-first responsive design

### Backend
- FastAPI for API gateway
- Microservices architecture
- Kubernetes for container management
- Two-Factor Authentication (2FA) mandatory

### Data Infrastructure
- Apache Kafka for message queuing
- Apache Spark for stream processing
- AWS S3 for data lake (Medallion Architecture)
- Time-Series Database + Relational Database

### Analytics Engine
- Python-based ML models (LSTM, ARIMA)
- NLP models (BERT) for sentiment analysis
- Containerized applications

## Current Development Phase

### Status: Pre-Development / Planning Phase
- Product Requirements Document (PRD) completed
- Market research and competitive analysis completed
- Technical architecture defined
- Development not yet started

### Next Steps
1. Assemble development team
2. Set up development environment
3. Begin Phase 1 (MVP) development
4. Establish data ingestion pipelines
5. Build core analytics engine

## Key Constraints and Requirements

### Performance Requirements
- Data freshness: <1 minute latency for on-chain/market data
- Predictive models recalculated every hour
- Dashboard load time: <2 seconds
- 99.9% uptime SLA

### Security Requirements
- 2FA mandatory for all accounts
- Data encryption at rest and in transit
- KYC/AML compliance for higher-tier features
- GDPR compliance

### Scalability Requirements
- Microservices architecture
- Containerized deployment (Kubernetes)
- Cloud provider (AWS)
- Horizontal scaling support

## Business Model

### SaaS Tiers

#### Explorer Tier ($29/month)
- Target: Retail investors and crypto enthusiasts new to RWAs
- Phase 1 features: Market Overview, Basic Screener, Core Asset Pages, Manual Portfolio, 7-Day Prediction, Overall Risk Score

#### Professional Tier ($149/month)
- Target: Active RWA investors, sophisticated traders, DeFi researchers
- All Explorer features + Phase 2 features: Advanced Screener, 30-Day Prediction with Key Drivers, Detailed Risk Breakdown, Automated Portfolio, Custom Alerts, Comparison Tool, CSV Export

#### Enterprise Tier (Custom Pricing)
- Target: Hedge funds, asset managers, financial institutions
- All Professional features + Phase 3 features: Full XAI Suite, Advanced On-Chain Analytics, Advanced Alerts, PDF Reporting, API Access, Backtesting Module

## Success Metrics

### Platform Metrics
- User acquisition and retention rates
- Portfolio tracking accuracy: 99%
- Alert latency: <5 minutes from trigger event
- API uptime: 99.95%

### Business Metrics
- Monthly Recurring Revenue (MRR)
- Customer Acquisition Cost (CAC)
- Lifetime Value (LTV)
- Tier conversion rates

### Technical Metrics
- Model prediction accuracy
- Data ingestion latency
- System uptime
- API response times

## Key Stakeholders

### Internal
- Product Manager
- Engineering Team (Frontend, Backend, Data, ML/AI)
- Design/UX Team
- QA/Testing Team

### External
- RWA Investors (Primary users)
- Institutional Clients (Enterprise users)
- Data Providers (API vendors)
- Regulatory Bodies

## Project Risks

### Technical Risks
- Data provider API reliability
- Model accuracy in volatile markets
- Scaling challenges
- Real-time processing complexity

### Business Risks
- Market adoption uncertainty
- Competitive pressure
- Regulatory changes
- Data acquisition costs

### Market Risks
- RWA market maturity
- Crypto market volatility
- Traditional finance adoption pace
- Liquidity constraints in RWA markets

## Documentation References

- [PRD.md](./PRD.md) - Detailed Product Requirements
- [Research.md](./Research.md) - Market Research and Technical Blueprint
- ARCHITECTURE.md - System Architecture (to be created)
- DEVELOPMENT_GUIDE.md - Development Setup and Guidelines (to be created)
