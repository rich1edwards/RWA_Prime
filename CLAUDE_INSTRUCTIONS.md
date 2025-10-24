# CLAUDE_INSTRUCTIONS.md

## Purpose

This document provides comprehensive guidelines for Claude (or any AI development assistant) to perform autonomous development tasks on the RWA-Prime project. It serves as a "how-to" guide for understanding the project, making changes, and maintaining code quality.

## Project Understanding

### What is RWA-Prime?

**RWA-Prime** is a predictive analytics SaaS platform for Real-World Assets (RWAs) in the crypto space. It bridges Traditional Finance (TradFi) and Decentralized Finance (DeFi) by:

1. Ingesting off-chain fundamental data, on-chain market metrics, and real-time sentiment
2. Running ML models (LSTM, ARIMA) to generate price predictions
3. Calculating composite risk scores
4. Providing explainable AI insights
5. Delivering all this through an intuitive web/mobile interface

### Project Status
**Pre-Development Phase** - Documentation complete, implementation has not yet started.

### Core Architecture

```
Data Sources → Ingestion Layer (Kafka) → Processing (Spark) → Storage (PostgreSQL + TimescaleDB)
                                                                      ↓
                                                          Analytics Engine (ML/NLP)
                                                                      ↓
                                                             Backend API (FastAPI)
                                                                      ↓
                                                             Frontend (React)
```

## Critical Documentation to Review

**Before making ANY changes**, Claude must review:

1. **PROJECT_CONTEXT.md** - Understand the project purpose, market, and goals
2. **ARCHITECTURE.md** - Understand system design and data flow
3. **CODEBASE_MAP.md** - Know where specific functionality lives
4. **DEVELOPMENT_GUIDE.md** - Setup and workflow
5. **TASKS_AND_TODO.md** - Current priorities and known issues

## Core Development Principles

### 1. Always Read Before Writing

**CRITICAL RULE**: Never modify a file without first reading it completely.

**Process**:
1. Use `Read` tool to understand existing code
2. Analyze dependencies and relationships
3. Plan your changes
4. Make minimal, targeted modifications
5. Verify changes don't break existing functionality

### 2. Follow the Architecture

**DO NOT** introduce new architectural patterns or technologies without explicit user approval.

**Current stack is fixed**:
- Backend: Python 3.11+, FastAPI, SQLAlchemy, PostgreSQL
- ML: PyTorch, scikit-learn, Transformers (BERT)
- Data: Kafka, Spark, TimescaleDB
- Frontend: React 18+, TypeScript, Tailwind CSS, D3.js
- Infrastructure: AWS, Kubernetes, Terraform

### 3. Maintain Code Style

**Python** (Backend):
- Follow PEP 8
- Use Black for formatting
- Type hints required for all functions
- Google-style docstrings

**TypeScript** (Frontend):
- Airbnb style guide
- Use Prettier
- Explicit interfaces for all props
- Functional components with hooks

### 4. Test-Driven Development

**Before marking a task complete**:
1. Write unit tests for new functionality
2. Run existing tests to ensure no regressions
3. Aim for 80%+ coverage, 95%+ for critical paths

### 5. Documentation Updates

When adding features, update:
- Code comments (inline documentation)
- API_REFERENCE.md (if adding endpoints)
- CODEBASE_MAP.md (if adding new files/modules)
- TASKS_AND_TODO.md (mark completed, add new issues)

## File Modification Guidelines

### Files Claude Can Modify

#### Backend Files
- `backend/api/routes/*.py` - API endpoints (add new routes)
- `backend/api/crud/*.py` - Database operations
- `backend/api/models/*.py` - Pydantic schemas
- `backend/ml_service/models/*.py` - ML models
- `backend/ml_service/training/*.py` - Model training scripts
- `backend/data_ingestion/*.py` - Data ingestion services
- `backend/tests/**/*.py` - Test files
- `backend/alembic/versions/*.py` - Database migrations (via Alembic)

#### Frontend Files
- `frontend/src/components/**/*.tsx` - React components
- `frontend/src/pages/*.tsx` - Page components
- `frontend/src/services/*.ts` - API service layer
- `frontend/src/hooks/*.ts` - Custom hooks
- `frontend/src/store/slices/*.ts` - State management
- `frontend/src/__tests__/**/*.test.tsx` - Test files

#### Configuration Files
- `.env.example` - Can add new environment variables (never commit actual `.env`)
- `requirements.txt` - Can add Python dependencies (with justification)
- `package.json` - Can add Node dependencies (with justification)

### Files Claude Should NEVER Modify Without Permission

- `docker-compose.yml` - Core infrastructure
- `infrastructure/terraform/**` - Cloud infrastructure
- `infrastructure/kubernetes/**` - K8s configs
- `alembic/env.py` - Database migration engine config
- `.github/workflows/**` - CI/CD pipelines
- Any production secrets or keys

### Files That Don't Exist Yet (Pre-Development)

Since this is a pre-development project, Claude will need to **create** the entire codebase structure. Follow the structure defined in `CODEBASE_MAP.md` exactly.

## Common Development Tasks

### Task 1: Add a New API Endpoint

**Checklist**:
1. Read `backend/api/routes/` to find appropriate route file
2. Define Pydantic request/response models in `backend/api/models/`
3. Implement database CRUD operations in `backend/api/crud/`
4. Add route handler in `backend/api/routes/`
5. Register route in `backend/api/main.py`
6. Write unit tests in `backend/tests/unit/test_routes_*.py`
7. Write integration tests in `backend/tests/integration/`
8. Update `API_REFERENCE.md` with new endpoint documentation

**Example**:
```python
# backend/api/models/alert.py
from pydantic import BaseModel
from typing import Dict

class AlertCreate(BaseModel):
    asset_id: str
    condition_type: str
    condition_value: Dict
    notification_method: str

# backend/api/routes/alerts.py
from fastapi import APIRouter, Depends
from api.models.alert import AlertCreate
from api.crud import alert

router = APIRouter()

@router.post("/", response_model=AlertResponse)
def create_alert(
    alert_data: AlertCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Create a new alert for the current user."""
    return alert.create_alert(db, alert_data, current_user.id)

# backend/api/main.py
from api.routes import alerts
app.include_router(alerts.router, prefix="/api/v1/alerts", tags=["alerts"])
```

### Task 2: Add a New React Component

**Checklist**:
1. Create component file in `frontend/src/components/`
2. Define TypeScript props interface
3. Implement functional component with hooks
4. Add styling (Tailwind CSS classes)
5. Export from appropriate `index.ts`
6. Write unit tests in `__tests__/`
7. Update parent component to use new component

**Example**:
```typescript
// frontend/src/components/RiskGauge.tsx
import React from 'react';

interface RiskGaugeProps {
  score: number; // 1-100
  size?: 'small' | 'medium' | 'large';
}

export const RiskGauge: React.FC<RiskGaugeProps> = ({
  score,
  size = 'medium'
}) => {
  const getRiskColor = (score: number): string => {
    if (score < 30) return 'text-green-500';
    if (score < 60) return 'text-yellow-500';
    return 'text-red-500';
  };

  return (
    <div className={`risk-gauge ${size}`}>
      <div className={`score ${getRiskColor(score)}`}>
        {score}
      </div>
      <div className="label">Risk Score</div>
    </div>
  );
};

// frontend/src/__tests__/RiskGauge.test.tsx
import { render, screen } from '@testing-library/react';
import { RiskGauge } from '../components/RiskGauge';

describe('RiskGauge', () => {
  it('renders low risk as green', () => {
    render(<RiskGauge score={20} />);
    const scoreElement = screen.getByText('20');
    expect(scoreElement).toHaveClass('text-green-500');
  });

  it('renders high risk as red', () => {
    render(<RiskGauge score={80} />);
    const scoreElement = screen.getByText('80');
    expect(scoreElement).toHaveClass('text-red-500');
  });
});
```

### Task 3: Add a Database Migration

**Checklist**:
1. Define SQLAlchemy model in `backend/api/database/models.py`
2. Create Alembic migration: `alembic revision --autogenerate -m "description"`
3. Review generated migration file
4. Test migration: `alembic upgrade head`
5. Test rollback: `alembic downgrade -1`
6. Commit migration file
7. Update CRUD operations

### Task 4: Implement an ML Model

**Checklist**:
1. Research model architecture (LSTM, ARIMA, etc.)
2. Create model file in `backend/ml_service/models/`
3. Implement training script in `backend/ml_service/training/`
4. Create inference script in `backend/ml_service/inference/`
5. Add model evaluation in `backend/ml_service/evaluation/`
6. Write tests for model functions
7. Document model parameters and hyperparameters
8. Create model versioning strategy

### Task 5: Add Data Ingestion Source

**Checklist**:
1. Get API key for data source
2. Create client wrapper in `backend/data_ingestion/api_clients/`
3. Implement ingestion service in `backend/data_ingestion/`
4. Define Kafka topic for raw data
5. Add error handling and retry logic
6. Create unit tests with mocked API responses
7. Update `.env.example` with new API key variable
8. Document in `DEPENDENCIES.md`

## Decision-Making Framework

### When to Ask the User

Claude should **STOP and ask the user** for guidance when:

1. **Architectural changes**: Adding new services, changing database schema significantly
2. **External dependencies**: Adding new Python/Node packages or external APIs
3. **Breaking changes**: Modifying existing API contracts that could break clients
4. **Security concerns**: Implementing authentication, handling sensitive data
5. **Multiple valid approaches**: When there are 2+ equally good solutions
6. **Unclear requirements**: When task description is ambiguous
7. **Infrastructure changes**: Modifying Terraform, K8s configs, or CI/CD
8. **Cost implications**: Changes that significantly affect cloud costs

### When to Proceed Autonomously

Claude can proceed **without asking** when:

1. **Bug fixes**: Fixing obvious bugs with clear solutions
2. **Adding features**: Implementing well-defined features from `TASKS_AND_TODO.md`
3. **Refactoring**: Improving code quality without changing behavior
4. **Writing tests**: Adding or updating test coverage
5. **Documentation updates**: Improving or fixing documentation
6. **Code style fixes**: Applying linting/formatting fixes
7. **Minor optimizations**: Small performance improvements

## Testing Requirements

### Before Submitting Code

Run these commands and **ensure they all pass**:

**Backend**:
```bash
cd backend
black .  # Format code
flake8  # Lint
mypy .  # Type check
pytest --cov --cov-report=term  # Tests with coverage
```

**Frontend**:
```bash
cd frontend
npm run lint  # ESLint
npm run type-check  # TypeScript
npm test -- --coverage  # Tests
```

### Test Coverage Requirements

- **New code**: 80%+ coverage
- **Critical paths** (auth, payments, predictions, risk scoring): 95%+ coverage
- **Integration tests**: Required for new API endpoints
- **E2E tests**: Required for new user-facing features

## Error Handling

### Logging

Always add appropriate logging:

**Python**:
```python
import logging
logger = logging.getLogger(__name__)

try:
    result = perform_operation()
    logger.info(f"Operation succeeded: {result}")
except Exception as e:
    logger.error(f"Operation failed: {str(e)}", exc_info=True)
    raise
```

**TypeScript**:
```typescript
try {
  const result = await apiCall();
  console.log('API call succeeded:', result);
} catch (error) {
  console.error('API call failed:', error);
  throw error;
}
```

### Error Responses

**API errors** must follow standard format (see `API_REFERENCE.md`):
```python
from fastapi import HTTPException

raise HTTPException(
    status_code=404,
    detail={
        "code": "ASSET_NOT_FOUND",
        "message": "Asset with ID 'xyz' not found",
        "details": {}
    }
)
```

## Security Checklist

Before committing code, verify:

- [ ] No hardcoded secrets, API keys, or passwords
- [ ] All user inputs are validated (Pydantic models, Zod schemas)
- [ ] SQL injection prevention (use SQLAlchemy ORM, no raw SQL)
- [ ] XSS prevention (React default escaping, CSP headers)
- [ ] Authentication required for protected endpoints
- [ ] Authorization checks (user can only access their own data)
- [ ] Rate limiting applied to public endpoints
- [ ] HTTPS enforced in production
- [ ] Sensitive data encrypted at rest and in transit

## Performance Guidelines

### Database Queries

- Use database indexes for frequently queried columns
- Avoid N+1 queries (use `joinedload` or `selectinload`)
- Paginate large result sets
- Cache expensive queries in Redis

### API Responses

- Keep response payloads small (<100KB ideal)
- Use pagination for lists
- Implement ETags for caching
- Compress responses (gzip)

### ML Models

- Cache model outputs in Redis (predictions valid for 1 hour)
- Use batch inference when possible
- Load models once at startup, not per request
- Monitor inference latency (<500ms target)

## Git Workflow

### Commit Messages

Follow Conventional Commits:

```
feat(api): add risk score breakdown endpoint
fix(frontend): resolve chart rendering bug on mobile
docs: update API reference for alerts
refactor(ml): optimize LSTM model inference
test: add unit tests for portfolio CRUD
```

### Branch Strategy

**Do not create branches** - Claude operates in current working directory.
User manages Git branching.

### What to Commit

**DO commit**:
- Source code files
- Test files
- Documentation updates
- Configuration examples (`.env.example`)
- Database migrations

**DO NOT commit**:
- `.env` file with actual secrets
- `node_modules/` or `venv/`
- `__pycache__/`, `.pytest_cache/`
- IDE-specific files (`.vscode/`, `.idea/`)
- Build artifacts (`dist/`, `build/`)
- Logs or temporary files

## Troubleshooting Common Issues

### Issue: Tests Failing

**Steps**:
1. Read test output carefully
2. Check if recent changes broke existing functionality
3. Run specific failing test with `-v` flag for details
4. Check test fixtures and mocks are correct
5. Verify database schema matches models

### Issue: Import Errors

**Steps**:
1. Check `requirements.txt` or `package.json` dependencies
2. Verify file paths are correct
3. Check for circular imports
4. Ensure `__init__.py` files exist in Python packages

### Issue: Database Migration Errors

**Steps**:
1. Check if database is running: `docker-compose ps`
2. Verify connection string in `.env`
3. Review migration file for errors
4. Try manual migration: `alembic downgrade -1` then `alembic upgrade head`

## Communication with User

### Progress Updates

When working on a task, provide **clear, concise updates**:

```
✅ Completed: Created AlertCreate Pydantic model
🔄 In Progress: Implementing create_alert CRUD function
⏳ Next: Writing unit tests for alert creation
```

### When Blocked

If blocked, clearly state:
1. What you were trying to do
2. What the error/issue is
3. What you've tried
4. What information you need to proceed

### Final Summary

After completing a task, provide:
1. List of files modified/created
2. Brief description of changes
3. Test results (coverage %, passing tests)
4. Any follow-up items or recommendations

## Quality Checklist

Before marking a task complete:

- [ ] Code follows project style guidelines
- [ ] All new functions have type hints (Python) or TypeScript types
- [ ] Docstrings/comments added for complex logic
- [ ] Unit tests written and passing
- [ ] Integration tests written (if applicable)
- [ ] No linting errors
- [ ] No type checking errors
- [ ] Coverage requirements met (80%+ overall, 95%+ for critical paths)
- [ ] Documentation updated (API reference, README, etc.)
- [ ] No hardcoded secrets or sensitive data
- [ ] Error handling implemented
- [ ] Logging added for important operations
- [ ] Performance considerations addressed
- [ ] User-facing changes are intuitive and match design
- [ ] TASKS_AND_TODO.md updated

## Project-Specific Considerations

### RWA Data Handling

- **Off-chain data** is truth source for fundamentals (from RWA.io API)
- **On-chain data** reflects market dynamics (from Amberdata/Bitquery)
- **Predictions** combine both + sentiment, use dynamic weighting by asset class
- **Risk scores** must include: Market, Credit, Regulatory, Technical risks

### Asset Class Differences

Different RWA types require different treatment:

- **Tokenized Treasuries**: Heavily weighted on macroeconomic data (interest rates)
- **Private Credit**: Focus on on-chain pool health and default rates
- **Real Estate**: Property fundamentals + on-chain liquidity
- **Commodities**: Underlying commodity price + proof of reserves

Ensure models and UI adapt to asset class context.

### User Tier Restrictions

Enforce tier-based access:
- **Explorer**: Basic features only
- **Professional**: Advanced analytics, automated portfolio
- **Enterprise**: Full features, API access

Check `current_user.tier` in backend before serving premium features.

---

## Summary

**Claude's primary responsibilities**:

1. **Understand the project** by reading all documentation
2. **Follow established architecture** and patterns
3. **Write high-quality code** with tests and documentation
4. **Ask when uncertain** rather than making assumptions
5. **Maintain security** and performance best practices
6. **Communicate clearly** with the user throughout

**Remember**: This is a complex financial application. Accuracy, security, and reliability are paramount. When in doubt, ask the user.

---

**Related Documentation**:
- [PROJECT_CONTEXT.md](./PROJECT_CONTEXT.md) - Project overview
- [ARCHITECTURE.md](./ARCHITECTURE.md) - System architecture
- [DEVELOPMENT_GUIDE.md](./DEVELOPMENT_GUIDE.md) - Setup and workflow
- [CODEBASE_MAP.md](./CODEBASE_MAP.md) - File structure
- [TASKS_AND_TODO.md](./TASKS_AND_TODO.md) - Current priorities
- [TESTING_GUIDE.md](./TESTING_GUIDE.md) - Testing strategy
- [API_REFERENCE.md](./API_REFERENCE.md) - API documentation
- [DEPENDENCIES.md](./DEPENDENCIES.md) - External dependencies
