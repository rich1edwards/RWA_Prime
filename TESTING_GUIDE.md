# TESTING_GUIDE.md

## Testing Philosophy

RWA-Prime follows a **comprehensive testing pyramid** approach:

```
        /\
       /  \      E2E Tests (5%)
      /____\
     /      \    Integration Tests (25%)
    /________\
   /          \  Unit Tests (70%)
  /____________\
```

**Coverage Requirements**:
- Minimum overall coverage: **80%**
- Critical paths (auth, payments, predictions): **95%+**
- New features must include tests before merge

## Testing Stack

### Backend
- **pytest**: Test framework
- **pytest-cov**: Coverage reporting
- **pytest-asyncio**: Async test support
- **httpx**: HTTP client for API testing
- **unittest.mock**: Mocking
- **testcontainers**: Docker containers for integration tests
- **faker**: Test data generation

### Frontend
- **Vitest**: Unit test framework
- **React Testing Library**: Component testing
- **MSW (Mock Service Worker)**: API mocking
- **Playwright**: E2E testing

## Backend Testing

### Unit Tests

**Location**: `backend/tests/unit/`

#### Example: Testing a CRUD function

```python
# backend/tests/unit/test_crud_asset.py
import pytest
from sqlalchemy.orm import Session
from unittest.mock import Mock

from api.crud import asset
from api.models.asset import AssetCreate

def test_create_asset(db: Session):
    """Test asset creation"""
    asset_data = AssetCreate(
        symbol="TEST",
        name="Test Asset",
        asset_class="tokenized_treasury",
        blockchain_network="ethereum"
    )
    
    created_asset = asset.create_asset(db, asset_data)
    
    assert created_asset.symbol == "TEST"
    assert created_asset.asset_class == "tokenized_treasury"

def test_get_asset_by_id(db: Session):
    """Test retrieving asset by ID"""
    # Setup: Create test asset
    asset_data = AssetCreate(symbol="TEST2", name="Test Asset 2", ...)
    created = asset.create_asset(db, asset_data)
    
    # Test
    retrieved = asset.get_asset(db, created.id)
    
    assert retrieved.id == created.id
    assert retrieved.symbol == "TEST2"

def test_get_asset_not_found(db: Session):
    """Test asset not found raises exception"""
    from api.core.exceptions import AssetNotFoundError
    
    with pytest.raises(AssetNotFoundError):
        asset.get_asset(db, "nonexistent-id")
```

#### Example: Testing API endpoints

```python
# backend/tests/unit/test_api_assets.py
from fastapi.testclient import TestClient
from api.main import app

client = TestClient(app)

def test_list_assets_unauthenticated():
    """Test listing assets without auth fails"""
    response = client.get("/api/v1/assets")
    assert response.status_code == 401

def test_list_assets_authenticated(auth_headers):
    """Test listing assets with valid token"""
    response = client.get("/api/v1/assets", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert "assets" in data
    assert isinstance(data["assets"], list)

def test_get_asset_detail(auth_headers):
    """Test getting specific asset"""
    response = client.get(
        "/api/v1/assets/test-asset-id", 
        headers=auth_headers
    )
    assert response.status_code == 200
    data = response.json()
    assert data["symbol"] == "BUIDL"
```

#### Example: Testing ML models

```python
# backend/tests/unit/test_ml_predictor.py
import torch
import numpy as np
from ml_service.models.lstm_model import LSTMPredictor

def test_lstm_prediction_shape():
    """Test LSTM model output shape"""
    model = LSTMPredictor(input_size=10, hidden_size=64)
    
    # Input: (batch_size=1, sequence_length=30, features=10)
    test_input = torch.randn(1, 30, 10)
    
    prediction = model(test_input)
    
    # Should predict 7 days ahead
    assert prediction.shape == (1, 7)

def test_prediction_values_valid():
    """Test predictions are reasonable"""
    from ml_service.inference.predictor import predict_price
    
    # Mock historical data
    historical_prices = np.array([1.00, 1.01, 0.99, 1.00, 1.02])
    
    predictions = predict_price(
        asset_id="test",
        historical_prices=historical_prices,
        forecast_horizon=7
    )
    
    # Predictions should be positive and within reasonable range
    assert len(predictions) == 7
    assert all(p > 0 for p in predictions)
    assert all(0.90 < p < 1.10 for p in predictions)  # ±10% range
```

### Integration Tests

**Location**: `backend/tests/integration/`

#### Example: Database integration

```python
# backend/tests/integration/test_database.py
import pytest
from testcontainers.postgres import PostgresContainer
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

@pytest.fixture(scope="module")
def postgres_container():
    """Start PostgreSQL container for testing"""
    with PostgresContainer("postgres:15") as postgres:
        yield postgres

@pytest.fixture
def db_session(postgres_container):
    """Database session for tests"""
    engine = create_engine(postgres_container.get_connection_url())
    Base.metadata.create_all(engine)
    SessionLocal = sessionmaker(bind=engine)
    session = SessionLocal()
    yield session
    session.close()

def test_user_asset_relationship(db_session):
    """Test user can have multiple portfolio assets"""
    # Create user
    user = User(email="test@example.com")
    db_session.add(user)
    db_session.commit()
    
    # Add assets to portfolio
    asset1 = PortfolioItem(user_id=user.id, asset_id="asset1", quantity=100)
    asset2 = PortfolioItem(user_id=user.id, asset_id="asset2", quantity=200)
    db_session.add_all([asset1, asset2])
    db_session.commit()
    
    # Verify
    portfolio = db_session.query(PortfolioItem).filter_by(user_id=user.id).all()
    assert len(portfolio) == 2
```

#### Example: Kafka integration

```python
# backend/tests/integration/test_kafka.py
from testcontainers.kafka import KafkaContainer
import json
from common.kafka_producer import KafkaProducerService

@pytest.fixture(scope="module")
def kafka_container():
    with KafkaContainer() as kafka:
        yield kafka

def test_produce_consume_price_data(kafka_container):
    """Test producing and consuming price data"""
    producer = KafkaProducerService(
        bootstrap_servers=kafka_container.get_bootstrap_server()
    )
    
    # Produce message
    test_message = {
        "asset_id": "test-123",
        "price": 1.00,
        "timestamp": "2025-10-23T12:00:00Z"
    }
    producer.send("price-data-raw", test_message)
    
    # Consume message
    consumer = KafkaConsumer(
        "price-data-raw",
        bootstrap_servers=kafka_container.get_bootstrap_server(),
        value_deserializer=lambda m: json.loads(m.decode('utf-8'))
    )
    
    message = next(consumer)
    assert message.value["asset_id"] == "test-123"
    assert message.value["price"] == 1.00
```

### End-to-End Tests

**Location**: `backend/tests/e2e/`

#### Example: Full user flow

```python
# backend/tests/e2e/test_user_flow.py
from fastapi.testclient import TestClient

def test_complete_user_journey(client: TestClient):
    """Test: Register → Login → Add to portfolio → Check predictions"""
    
    # 1. Register
    register_response = client.post("/api/v1/auth/register", json={
        "email": "newuser@example.com",
        "password": "SecurePass123!",
        "tier": "explorer"
    })
    assert register_response.status_code == 201
    
    # 2. Login
    login_response = client.post("/api/v1/auth/login", json={
        "email": "newuser@example.com",
        "password": "SecurePass123!"
    })
    temp_token = login_response.json()["temp_token"]
    
    # 3. Verify 2FA (mock TOTP)
    verify_response = client.post(
        "/api/v1/auth/verify-2fa",
        headers={"Authorization": f"Bearer {temp_token}"},
        json={"totp_code": "123456"}  # Mocked in test
    )
    assert verify_response.status_code == 200
    access_token = verify_response.json()["access_token"]
    
    # 4. Add asset to portfolio
    portfolio_response = client.post(
        "/api/v1/portfolio/transaction",
        headers={"Authorization": f"Bearer {access_token}"},
        json={
            "asset_id": "buidl-uuid",
            "transaction_type": "buy",
            "quantity": 1000,
            "price": 1.00
        }
    )
    assert portfolio_response.status_code == 201
    
    # 5. Get predictions
    prediction_response = client.get(
        "/api/v1/predictions/buidl-uuid",
        headers={"Authorization": f"Bearer {access_token}"}
    )
    assert prediction_response.status_code == 200
    assert "predictions" in prediction_response.json()
```

### Running Backend Tests

```bash
# All tests
pytest

# With coverage
pytest --cov=api --cov=ml_service --cov-report=html

# Specific test file
pytest tests/unit/test_auth.py

# Tests matching pattern
pytest -k "prediction"

# Verbose output
pytest -v

# Stop on first failure
pytest -x

# Run only unit tests
pytest tests/unit/

# Run only integration tests (slower)
pytest tests/integration/ -v
```

## Frontend Testing

### Unit Tests (Components)

**Location**: `frontend/src/__tests__/`

#### Example: Component test

```typescript
// frontend/src/__tests__/AssetCard.test.tsx
import { render, screen, fireEvent } from '@testing-library/react';
import { AssetCard } from '../components/AssetCard';

describe('AssetCard', () => {
  const mockAsset = {
    id: '123',
    symbol: 'BUIDL',
    name: 'BlackRock USD Institutional Digital Liquidity Fund',
    price: 1.00,
    riskScore: 15
  };

  it('renders asset information correctly', () => {
    render(<AssetCard asset={mockAsset} />);
    
    expect(screen.getByText('BUIDL')).toBeInTheDocument();
    expect(screen.getByText(/BlackRock/)).toBeInTheDocument();
    expect(screen.getByText('$1.00')).toBeInTheDocument();
  });

  it('calls onSelect when clicked', () => {
    const handleSelect = vi.fn();
    render(<AssetCard asset={mockAsset} onSelect={handleSelect} />);
    
    fireEvent.click(screen.getByRole('button'));
    
    expect(handleSelect).toHaveBeenCalledWith('123');
  });

  it('does not show risk score when showRiskScore is false', () => {
    render(<AssetCard asset={mockAsset} showRiskScore={false} />);
    
    expect(screen.queryByTestId('risk-gauge')).not.toBeInTheDocument();
  });
});
```

#### Example: Hook test

```typescript
// frontend/src/__tests__/useAssets.test.ts
import { renderHook, waitFor } from '@testing-library/react';
import { useAssets } from '../hooks/useAssets';
import { server } from '../mocks/server';
import { rest } from 'msw';

describe('useAssets', () => {
  it('fetches assets successfully', async () => {
    const { result } = renderHook(() => useAssets());
    
    await waitFor(() => expect(result.current.loading).toBe(false));
    
    expect(result.current.assets).toHaveLength(5);
    expect(result.current.error).toBeNull();
  });

  it('handles API error', async () => {
    server.use(
      rest.get('/api/v1/assets', (req, res, ctx) => {
        return res(ctx.status(500), ctx.json({ error: 'Server error' }));
      })
    );

    const { result } = renderHook(() => useAssets());
    
    await waitFor(() => expect(result.current.error).toBeTruthy());
  });
});
```

### Integration Tests (API Mocking)

#### Example: MSW setup

```typescript
// frontend/src/mocks/handlers.ts
import { rest } from 'msw';

export const handlers = [
  rest.get('/api/v1/assets', (req, res, ctx) => {
    return res(
      ctx.json({
        assets: [
          { id: '1', symbol: 'BUIDL', name: 'BlackRock...', price: 1.00 },
          { id: '2', symbol: 'OUSG', name: 'Ondo...', price: 102.50 }
        ]
      })
    );
  }),

  rest.post('/api/v1/auth/login', (req, res, ctx) => {
    const { email, password } = req.body as any;
    
    if (email === 'test@example.com' && password === 'password') {
      return res(ctx.json({ temp_token: 'mock-token' }));
    }
    
    return res(ctx.status(401), ctx.json({ error: 'Invalid credentials' }));
  })
];
```

### E2E Tests (Playwright)

**Location**: `frontend/tests/e2e/`

```typescript
// frontend/tests/e2e/user-flow.spec.ts
import { test, expect } from '@playwright/test';

test('user can login and view dashboard', async ({ page }) => {
  // Navigate to login
  await page.goto('http://localhost:3000/login');

  // Fill login form
  await page.fill('input[name="email"]', 'test@example.com');
  await page.fill('input[name="password"]', 'password123');
  await page.click('button[type="submit"]');

  // 2FA page
  await expect(page).toHaveURL('/verify-2fa');
  await page.fill('input[name="totp"]', '123456');
  await page.click('button[type="submit"]');

  // Should redirect to dashboard
  await expect(page).toHaveURL('/dashboard');
  await expect(page.locator('h1')).toContainText('Dashboard');

  // Check widgets are visible
  await expect(page.locator('[data-testid="market-overview"]')).toBeVisible();
  await expect(page.locator('[data-testid="portfolio-summary"]')).toBeVisible();
});

test('user can filter assets in screener', async ({ page }) => {
  await page.goto('http://localhost:3000/screener');

  // Apply filter
  await page.selectOption('select[name="asset_class"]', 'tokenized_treasury');
  await page.click('button:has-text("Apply Filters")');

  // Wait for results
  await page.waitForSelector('[data-testid="asset-card"]');

  // Check all results match filter
  const assetClasses = await page.$$eval(
    '[data-testid="asset-class"]',
    elements => elements.map(el => el.textContent)
  );

  expect(assetClasses.every(cls => cls === 'Tokenized Treasury')).toBeTruthy();
});
```

### Running Frontend Tests

```bash
# Unit tests (watch mode)
npm test

# With coverage
npm test -- --coverage

# E2E tests
npx playwright test

# E2E tests with UI
npx playwright test --ui

# Specific test file
npm test AssetCard.test.tsx
```

## Test Data Management

### Fixtures

```python
# backend/tests/fixtures/users.py
import pytest
from api.models.user import User
from api.core.security import get_password_hash

@pytest.fixture
def test_user(db_session):
    """Create a test user"""
    user = User(
        email="test@example.com",
        password_hash=get_password_hash("password123"),
        tier="explorer"
    )
    db_session.add(user)
    db_session.commit()
    return user

@pytest.fixture
def auth_headers(test_user):
    """Get auth headers with valid JWT"""
    from api.core.auth import create_access_token
    token = create_access_token({"sub": test_user.id})
    return {"Authorization": f"Bearer {token}"}
```

### Factories

```python
# backend/tests/factories.py
from faker import Faker
from api.models.asset import Asset

fake = Faker()

class AssetFactory:
    @staticmethod
    def create(**kwargs):
        defaults = {
            "symbol": fake.lexify(text="????").upper(),
            "name": fake.company(),
            "asset_class": "tokenized_treasury",
            "blockchain_network": "ethereum",
            "market_cap": fake.random_int(min=1000000, max=1000000000)
        }
        defaults.update(kwargs)
        return Asset(**defaults)
```

## Continuous Integration

### GitHub Actions Workflow

```yaml
# .github/workflows/test.yml
name: Tests

on: [push, pull_request]

jobs:
  backend-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.11'
      - name: Install dependencies
        run: |
          cd backend
          pip install -r requirements-dev.txt
      - name: Run tests
        run: |
          cd backend
          pytest --cov --cov-report=xml
      - name: Upload coverage
        uses: codecov/codecov-action@v3

  frontend-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Set up Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'
      - name: Install dependencies
        run: |
          cd frontend
          npm ci
      - name: Run tests
        run: |
          cd frontend
          npm test -- --coverage
```

## Test Best Practices

1. **AAA Pattern**: Arrange, Act, Assert
2. **One assertion per test** (when possible)
3. **Clear test names**: `test_what_when_expected()`
4. **Mock external dependencies** (APIs, databases in unit tests)
5. **Use fixtures** for common setup
6. **Don't test implementation details**, test behavior
7. **Keep tests fast** (unit tests < 1s each)
8. **Isolate tests** (no dependencies between tests)
9. **Test edge cases** and error conditions
10. **Update tests** when requirements change

---

**Related Documentation**:
- [DEVELOPMENT_GUIDE.md](./DEVELOPMENT_GUIDE.md)
- [ARCHITECTURE.md](./ARCHITECTURE.md)
