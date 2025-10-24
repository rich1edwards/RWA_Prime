# 🚀 RWA Prime - Master Context & Documentation Guide

**Welcome to the RWA Prime Project!**

This is your starting point for understanding and working on the RWA Prime platform - a predictive analytics SaaS for Real-World Assets (RWAs) in the crypto space.

---

## 📖 Required Reading Order

When approaching this project for the first time, follow this sequence:

### 1. **[PROJECT_CONTEXT.md](./PROJECT_CONTEXT.md)** - Start Here ⭐
**What & Why** - Understand the project
- Project purpose and goals
- Target market and users
- Core value proposition
- Business model (SaaS tiers)
- Success metrics

### 2. **[ARCHITECTURE.md](./ARCHITECTURE.md)** - System Design
**How** - Understand the technical implementation
- System architecture (Microservices, Kafka, Spark)
- Data flow (Ingestion → Processing → Storage → Analytics → API)
- Technology stack
- Database schema
- Security architecture
- Deployment strategy

### 3. **[CODEBASE_MAP.md](./CODEBASE_MAP.md)** - Navigate the Code
**Where** - Find what you need
- Complete file structure breakdown
- Purpose of each module/directory
- Key functions and classes
- Entry points and main flows
- Data flow through the system

### 4. **[CLAUDE_INSTRUCTIONS.md](./CLAUDE_INSTRUCTIONS.md)** - Development Guidelines
**Rules & Best Practices** - How to develop
- Development principles
- File modification guidelines
- Code style conventions
- Testing requirements
- Security checklist
- Decision-making framework

### 5. **[DEVELOPMENT_GUIDE.md](./DEVELOPMENT_GUIDE.md)** - Setup & Workflows
**Practical How-To** - Get started developing
- Environment setup (Docker, Python, Node.js)
- Running the project locally
- Development workflow (Git, commits, PRs)
- Common development tasks
- Troubleshooting

---

## 🔍 Quick Reference Files

Use these when you need specific information:

| File | Purpose | When to Use |
|------|---------|-------------|
| **[API_REFERENCE.md](./API_REFERENCE.md)** | All endpoints and contracts | Implementing/calling APIs |
| **[DEPENDENCIES.md](./DEPENDENCIES.md)** | Package information & external services | Adding dependencies, understanding costs |
| **[TESTING_GUIDE.md](./TESTING_GUIDE.md)** | Testing requirements & examples | Writing tests, running test suites |
| **[TASKS_AND_TODO.md](./TASKS_AND_TODO.md)** | Current work items & roadmap | Checking priorities, finding tasks |
| **[ARCHITECTURE_DECISION_RECORDS.md](./ARCHITECTURE_DECISION_RECORDS.md)** | Why technical decisions were made | Understanding rationale behind choices |
| **[ERROR_CODES_AND_HANDLING.md](./ERROR_CODES_AND_HANDLING.md)** | Standardized error codes & patterns | Implementing error handling |
| **[DATA_DICTIONARY.md](./DATA_DICTIONARY.md)** | Complete database schema | Working with database, understanding data |
| **[SECURITY_GUIDELINES.md](./SECURITY_GUIDELINES.md)** | Security best practices | Implementing secure features |
| **[TROUBLESHOOTING.md](./TROUBLESHOOTING.md)** | Common issues and solutions | Debugging problems |

---

## 💼 Business Context

Understand the product vision and market:

### **[PRD.md](./PRD.md)** - Product Requirements Document
- Detailed feature specifications
- User personas (Ivan, Diana, Tom)
- Phase 1-3 feature breakdown
- Use cases and user stories
- Non-functional requirements
- External data sources

### **[Research.md](./Research.md)** - Research & Market Analysis
- RWA market landscape
- Competitive analysis (Nansen, Glassnode, RWA.xyz)
- Technology choices and justifications
- ML/NLP model strategy
- Data architecture rationale

---

## 📂 Documentation Location

All documentation files are located in:
```
/Users/richedwards/AI-Dev-Projects/RWA_Prime/
```

---

## 🎯 Project Status

**Current Phase**: Pre-Development / Planning Complete ✅

### What's Done:
- ✅ Product requirements defined
- ✅ Market research completed
- ✅ Technical architecture designed
- ✅ Comprehensive documentation generated

### What's Next:
1. Assemble development team
2. Set up infrastructure (AWS, Kubernetes)
3. Begin Phase 1 MVP development
4. Build data ingestion pipelines
5. Implement ML models

See **[TASKS_AND_TODO.md](./TASKS_AND_TODO.md)** for detailed roadmap.

---

## 🏗️ Quick Start for Different Roles

### For Developers
1. Read PROJECT_CONTEXT.md
2. Review ARCHITECTURE.md
3. Follow DEVELOPMENT_GUIDE.md for setup
4. Check TASKS_AND_TODO.md for current priorities
5. Follow CLAUDE_INSTRUCTIONS.md for coding standards

### For AI Assistants (Claude)
1. **Always** read CLAUDE_INSTRUCTIONS.md first
2. Reference PROJECT_CONTEXT.md for context
3. Use CODEBASE_MAP.md to navigate
4. Consult ARCHITECTURE_DECISION_RECORDS.md before questioning design decisions
5. Use ERROR_CODES_AND_HANDLING.md for consistent error handling
6. Check DATA_DICTIONARY.md when working with database
7. Follow SECURITY_GUIDELINES.md for secure coding
8. Use TROUBLESHOOTING.md to resolve common issues
9. Follow development guidelines strictly
10. Ask user when uncertain

### For Project Managers
1. Review PRD.md for product requirements
2. Check TASKS_AND_TODO.md for roadmap
3. See Research.md for market context
4. Reference DEPENDENCIES.md for cost estimates

### For QA Engineers
1. Read TESTING_GUIDE.md for strategy
2. Check coverage requirements (80% min, 95% critical paths)
3. Review API_REFERENCE.md for endpoint testing
4. Follow test examples in TESTING_GUIDE.md

---

## 🎨 Technology Stack Summary

### Backend
- **Language**: Python 3.11+
- **Framework**: FastAPI
- **Database**: PostgreSQL 15+ (relational) + TimescaleDB (time-series)
- **ML/AI**: PyTorch, scikit-learn, Transformers (BERT)
- **Data**: Apache Kafka, Apache Spark

### Frontend
- **Framework**: React 18+ with TypeScript
- **Styling**: Tailwind CSS
- **Charts**: D3.js, Recharts
- **State**: Redux Toolkit

### Infrastructure
- **Cloud**: AWS (EKS, RDS, MSK, S3)
- **Orchestration**: Kubernetes
- **IaC**: Terraform
- **CI/CD**: GitHub Actions

---

## 🔗 Key External Dependencies

### Critical Data Sources (See DEPENDENCIES.md for details):
- **CoinAPI** - Real-time crypto price data
- **Amberdata** - Blockchain data API
- **Bitquery** - RWA-specific blockchain data
- **RWA.io** - Off-chain fundamental data
- **Trading Economics** - Macroeconomic indicators
- **NewsAPI.ai** - News aggregation & sentiment

**Estimated Monthly Cost**: ~$2,054/month for APIs + ~$2,500/month for AWS infrastructure

---

## ⚠️ Important Notes

### Files That Should Never Be Modified (Without Permission):
- `docker-compose.yml` - Core infrastructure
- `infrastructure/terraform/**` - Cloud infrastructure
- `infrastructure/kubernetes/**` - K8s configs
- `.github/workflows/**` - CI/CD pipelines
- Any production secrets or keys

### Before Making Changes:
1. ✅ Read the relevant file completely
2. ✅ Check CLAUDE_INSTRUCTIONS.md for guidelines
3. ✅ Understand dependencies and relationships
4. ✅ Plan minimal, targeted modifications
5. ✅ Write tests for new functionality
6. ✅ Update documentation if needed

---

## 📞 Getting Help

### Documentation Issues
- Check if there's a more specific guide (API_REFERENCE, TESTING_GUIDE, etc.)
- Review CLAUDE_INSTRUCTIONS.md for development patterns
- Consult CODEBASE_MAP.md for file locations

### Technical Questions
- ARCHITECTURE.md - System design questions
- DEVELOPMENT_GUIDE.md - Setup and tooling
- TESTING_GUIDE.md - Testing approaches

### Product Questions
- PRD.md - Feature specifications
- Research.md - Technical decisions and rationale
- PROJECT_CONTEXT.md - Business context

---

## 🎓 Learning Path

**New to the project?** Follow this learning path:

**Week 1**: Understanding
- Day 1-2: Read PROJECT_CONTEXT.md and PRD.md
- Day 3-4: Study ARCHITECTURE.md
- Day 5: Review Research.md

**Week 2**: Getting Ready
- Day 1-2: Go through DEVELOPMENT_GUIDE.md
- Day 3-4: Explore CODEBASE_MAP.md
- Day 5: Read CLAUDE_INSTRUCTIONS.md and TESTING_GUIDE.md

**Week 3**: Development
- Start contributing following TASKS_AND_TODO.md priorities

---

## 📊 Project Metrics

| Metric | Target |
|--------|--------|
| Test Coverage | 80% minimum, 95% critical paths |
| Dashboard Load Time | < 2 seconds |
| Data Freshness | < 1 minute latency |
| API Response Time | < 500ms |
| Uptime SLA | 99.9% |

---

## 🚦 Current Priorities

See **[TASKS_AND_TODO.md](./TASKS_AND_TODO.md)** for complete list. Top priorities:

1. **Infrastructure Setup** - AWS, Kubernetes, Terraform
2. **Backend Foundation** - FastAPI, database, authentication
3. **Data Ingestion** - Kafka, microservices for price/on-chain/news data
4. **ML Models** - ARIMA for MVP, LSTM for Phase 2
5. **Frontend** - React dashboard, asset screener, portfolio tracker

---

## 📝 Documentation Maintenance

This documentation should be updated when:
- ✅ New features are added
- ✅ Architecture changes
- ✅ Dependencies are added/updated
- ✅ New APIs are implemented
- ✅ Testing strategies evolve

**Last Updated**: October 23, 2025
**Version**: 1.0
**Status**: Pre-Development - Ready for Implementation

---

**Ready to start? Begin with [PROJECT_CONTEXT.md](./PROJECT_CONTEXT.md)** →
