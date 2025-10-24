# Contributing to RWA Prime

Thank you for your interest in contributing to RWA Prime! This document provides guidelines and instructions for contributing.

---

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Coding Standards](#coding-standards)
- [Commit Message Guidelines](#commit-message-guidelines)
- [Pull Request Process](#pull-request-process)
- [Testing Requirements](#testing-requirements)
- [Documentation](#documentation)

---

## Code of Conduct

This project adheres to a code of conduct. By participating, you are expected to:

- Be respectful and inclusive
- Welcome newcomers and help them learn
- Focus on what is best for the community
- Show empathy towards other community members

---

## Getting Started

### Prerequisites

- **Python 3.11+**
- **Node.js 18+**
- **Docker & Docker Compose**
- **Git**

### Initial Setup

1. **Fork the repository** on GitHub

2. **Clone your fork**:
   ```bash
   git clone https://github.com/YOUR_USERNAME/RWA_Prime.git
   cd RWA_Prime
   ```

3. **Add upstream remote**:
   ```bash
   git remote add upstream https://github.com/ORIGINAL_OWNER/RWA_Prime.git
   ```

4. **Set up development environment**:
   ```bash
   make setup
   ```

5. **Install pre-commit hooks**:
   ```bash
   make install-pre-commit
   ```

6. **Start development services**:
   ```bash
   make dev
   ```

---

## Development Workflow

### Branching Strategy

We use **Git Flow** branching model:

- `main` - Production-ready code
- `develop` - Integration branch for features
- `feature/*` - New features
- `bugfix/*` - Bug fixes
- `hotfix/*` - Urgent production fixes
- `release/*` - Release preparation

### Creating a Feature Branch

```bash
# Update develop branch
git checkout develop
git pull upstream develop

# Create feature branch
git checkout -b feature/your-feature-name

# Make your changes
# ...

# Commit your changes
git add .
git commit -m "feat: add your feature"

# Push to your fork
git push origin feature/your-feature-name
```

### Branch Naming Convention

- `feature/add-price-prediction` - New features
- `bugfix/fix-authentication-error` - Bug fixes
- `hotfix/fix-critical-security-issue` - Urgent fixes
- `docs/update-api-reference` - Documentation updates
- `refactor/improve-database-queries` - Code refactoring
- `test/add-integration-tests` - Test additions

---

## Coding Standards

### Python

- **Style**: Follow [PEP 8](https://peps.python.org/pep-0008/)
- **Formatter**: Black (line length: 100)
- **Linter**: flake8, pylint
- **Type Hints**: Use type hints for all function signatures

**Example**:
```python
from typing import List, Optional
from pydantic import BaseModel

def calculate_risk_score(
    asset_id: str,
    timeframe: int = 30
) -> Optional[float]:
    """
    Calculate risk score for an asset.

    Args:
        asset_id: Unique asset identifier
        timeframe: Number of days to analyze (default: 30)

    Returns:
        Risk score between 0-100, or None if insufficient data
    """
    # Implementation
    pass
```

### TypeScript/React

- **Style**: Airbnb TypeScript Style Guide
- **Formatter**: Prettier (print width: 100)
- **Linter**: ESLint

**Example**:
```typescript
interface AssetProps {
  symbol: string;
  price: number;
  onUpdate?: (price: number) => void;
}

export const AssetCard: React.FC<AssetProps> = ({ symbol, price, onUpdate }) => {
  const [currentPrice, setCurrentPrice] = useState(price);

  const handlePriceChange = (newPrice: number): void => {
    setCurrentPrice(newPrice);
    onUpdate?.(newPrice);
  };

  return <div>{/* Component implementation */}</div>;
};
```

### General Rules

- **No commented-out code** - Delete instead of commenting
- **No console.log()** in production code (use logger)
- **No hardcoded values** - Use environment variables or constants
- **DRY** - Don't Repeat Yourself
- **KISS** - Keep It Simple, Stupid
- **YAGNI** - You Aren't Gonna Need It (don't over-engineer)

---

## Commit Message Guidelines

We follow [Conventional Commits](https://www.conventionalcommits.org/) specification.

### Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, missing semicolons, etc.)
- `refactor`: Code refactoring (no functional changes)
- `perf`: Performance improvements
- `test`: Adding or updating tests
- `chore`: Maintenance tasks (updating dependencies, etc.)
- `ci`: CI/CD changes

### Examples

```bash
# Simple feature
feat: add 30-day price prediction endpoint

# Feature with scope
feat(ml): implement LSTM model for price prediction

# Bug fix
fix(auth): resolve JWT token expiration issue

# Breaking change
feat(api)!: change portfolio response format

BREAKING CHANGE: Portfolio API now returns nested transactions array
instead of separate transaction_ids array.

# Documentation
docs: update API_REFERENCE with new endpoints

# Multiple changes
feat: add sentiment analysis and risk scoring

- Implement FinBERT sentiment analysis
- Add composite risk score calculation
- Update API documentation

Closes #123, #124
```

---

## Pull Request Process

### Before Submitting

1. **Update from upstream**:
   ```bash
   git checkout develop
   git pull upstream develop
   git checkout feature/your-feature
   git rebase develop
   ```

2. **Run tests**:
   ```bash
   make test
   ```

3. **Run linters**:
   ```bash
   make lint
   ```

4. **Check code formatting**:
   ```bash
   make format-check
   ```

5. **Update documentation** (if applicable):
   - Update relevant `.md` files
   - Update inline code comments
   - Add API documentation

### Creating Pull Request

1. **Push your branch** to your fork:
   ```bash
   git push origin feature/your-feature
   ```

2. **Open Pull Request** on GitHub:
   - Use the PR template (automatically loaded)
   - Fill in all sections
   - Link related issues

3. **PR Title Format**:
   ```
   feat: add 30-day price prediction endpoint
   ```

4. **Request Reviews**:
   - Tag relevant reviewers
   - Assign yourself to the PR

### PR Review Process

1. **Automated Checks** must pass:
   - ✅ Tests pass
   - ✅ Linting passes
   - ✅ Documentation validation passes
   - ✅ No security vulnerabilities

2. **Code Review**:
   - At least 1 approval required for features
   - At least 2 approvals required for breaking changes
   - Address all review comments

3. **Merge**:
   - Use "Squash and Merge" for feature branches
   - Use "Merge Commit" for release branches
   - Delete branch after merge

---

## Testing Requirements

### Coverage Requirements

- **Minimum**: 80% overall coverage
- **Critical Paths**: 95% coverage (auth, payments, predictions, risk scoring)

### Test Types

**Unit Tests** (70% of tests):
```python
def test_calculate_risk_score():
    asset = Asset(symbol="USDC", asset_class="stablecoin")
    score = calculate_risk_score(asset)
    assert 0 <= score <= 100
```

**Integration Tests** (25% of tests):
```python
@pytest.mark.integration
def test_price_prediction_endpoint(client):
    response = client.get("/predictions/USDC?horizon=7d")
    assert response.status_code == 200
    assert "predicted_price" in response.json()
```

**E2E Tests** (5% of tests):
```typescript
test('user can create portfolio and add assets', async ({ page }) => {
  await page.goto('/portfolios');
  await page.click('text=New Portfolio');
  // ... test flow
});
```

### Running Tests

```bash
# All tests
make test

# Unit tests only
make test-unit

# Integration tests only
make test-integration

# E2E tests
make test-e2e

# With coverage report
make test-coverage
```

---

## Documentation

### When to Update Documentation

Update documentation when you:

- Add a new feature
- Change an API endpoint
- Modify database schema
- Change environment variables
- Add/remove dependencies
- Change development workflow

### Which Files to Update

| Change Type | Documentation Files |
|-------------|-------------------|
| **New Feature** | ARCHITECTURE.md, API_REFERENCE.md, TASKS_AND_TODO.md |
| **New API Endpoint** | API_REFERENCE.md |
| **Database Change** | DATA_DICTIONARY.md, ARCHITECTURE.md |
| **New Dependency** | DEPENDENCIES.md |
| **New Error Code** | ERROR_CODES_AND_HANDLING.md |
| **Security Change** | SECURITY_GUIDELINES.md |

### Documentation Standards

- Use clear, concise language
- Include code examples
- Add diagrams (Mermaid) where helpful
- Keep line length < 120 characters
- Use proper markdown formatting

---

## Questions?

- **Documentation**: Read [00_START_HERE.md](./00_START_HERE.md)
- **Issues**: Create a [GitHub Issue](https://github.com/YOUR_USERNAME/RWA_Prime/issues)
- **Discussions**: Use [GitHub Discussions](https://github.com/YOUR_USERNAME/RWA_Prime/discussions)

---

**Thank you for contributing to RWA Prime!** 🚀
