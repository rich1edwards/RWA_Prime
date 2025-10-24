# API_REFERENCE.md

## API Overview

**Base URL**: `https://api.rwa-prime.com/api/v1`  
**Authentication**: JWT Bearer Token  
**Content-Type**: `application/json`

## Authentication

### POST /auth/register

Register a new user account.

**Request Body**:
```json
{
  "email": "user@example.com",
  "password": "SecurePassword123!",
  "tier": "explorer"
}
```

**Response (201 Created)**:
```json
{
  "user_id": "uuid-here",
  "email": "user@example.com",
  "tier": "explorer",
  "message": "Please check your email to verify your account"
}
```

---

### POST /auth/login

Authenticate user and receive JWT tokens.

**Request Body**:
```json
{
  "email": "user@example.com",
  "password": "SecurePassword123!"
}
```

**Response (200 OK)**:
```json
{
  "message": "2FA required. Please provide TOTP code",
  "temp_token": "temp-jwt-token"
}
```

---

### POST /auth/verify-2fa

Complete authentication with 2FA code.

**Headers**: `Authorization: Bearer {temp_token}`

**Request Body**:
```json
{
  "totp_code": "123456"
}
```

**Response (200 OK)**:
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "bearer",
  "expires_in": 900
}
```

---

### POST /auth/refresh

Refresh access token using refresh token.

**Request Body**:
```json
{
  "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**Response (200 OK)**:
```json
{
  "access_token": "new-access-token",
  "token_type": "bearer",
  "expires_in": 900
}
```

---

## Assets

### GET /assets

List all available RWA assets with pagination.

**Query Parameters**:
- `page` (int, default: 1)
- `limit` (int, default: 50, max: 100)
- `asset_class` (string, optional): Filter by asset class
- `blockchain` (string, optional): Filter by blockchain

**Response (200 OK)**:
```json
{
  "total": 250,
  "page": 1,
  "limit": 50,
  "assets": [
    {
      "asset_id": "uuid",
      "symbol": "BUIDL",
      "name": "BlackRock USD Institutional Digital Liquidity Fund",
      "asset_class": "tokenized_treasury",
      "blockchain_network": "ethereum",
      "market_cap": 500000000,
      "current_price": 1.00,
      "price_change_24h": 0.01,
      "risk_score": 15
    }
  ]
}
```

---

### GET /assets/{asset_id}

Get detailed information for a specific asset.

**Response (200 OK)**:
```json
{
  "asset_id": "uuid",
  "symbol": "BUIDL",
  "name": "BlackRock USD Institutional Digital Liquidity Fund",
  "asset_class": "tokenized_treasury",
  "blockchain_network": "ethereum",
  "contract_address": "0x...",
  "issuer_name": "BlackRock",
  "current_price": 1.00,
  "market_cap": 500000000,
  "volume_24h": 10000000,
  "holder_count": 1250,
  "risk_score": 15,
  "underlying_asset_details": {
    "asset_type": "US Treasury Bills",
    "maturity_range": "1-3 months",
    "custodian": "BNY Mellon"
  },
  "created_at": "2024-03-15T10:00:00Z"
}
```

---

### POST /assets/screener

Advanced asset screening with multiple filters.

**Request Body**:
```json
{
  "filters": {
    "asset_class": ["tokenized_treasury", "private_credit"],
    "blockchain_network": ["ethereum", "polygon"],
    "market_cap_min": 1000000,
    "market_cap_max": 1000000000,
    "risk_score_max": 50,
    "apy_min": 3.0
  },
  "sort_by": "market_cap",
  "order": "desc",
  "page": 1,
  "limit": 20
}
```

**Response (200 OK)**: Same structure as GET /assets

---

## Predictions

### GET /predictions/{asset_id}

Get latest price prediction for an asset.

**Query Parameters**:
- `forecast_horizon` (int, optional): 7 or 30 days (default: 7)

**Response (200 OK)**:
```json
{
  "asset_id": "uuid",
  "asset_symbol": "BUIDL",
  "forecast_horizon": 7,
  "predictions": [
    {
      "date": "2025-10-24",
      "predicted_price": 1.0005,
      "confidence_lower": 0.9995,
      "confidence_upper": 1.0015
    },
    // ... 6 more days
  ],
  "generated_at": "2025-10-23T12:00:00Z",
  "model_version": "ensemble_v1.2"
}
```

---

### GET /predictions/{asset_id}/drivers

Get explainable AI insights for prediction.

**Response (200 OK)**:
```json
{
  "asset_id": "uuid",
  "positive_drivers": [
    {
      "factor": "Strong institutional backing",
      "impact_score": 0.35,
      "description": "Recent $100M inflow from major institutions"
    },
    {
      "factor": "Rising US Treasury yields",
      "impact_score": 0.25,
      "description": "10-year Treasury yield up 15 bps this week"
    }
  ],
  "negative_drivers": [
    {
      "factor": "Decreased on-chain activity",
      "impact_score": -0.15,
      "description": "7-day transaction volume down 12%"
    }
  ],
  "overall_sentiment": "positive",
  "confidence": 0.78
}
```

---

## Risk Scores

### GET /risk/{asset_id}

Get composite risk score and breakdown.

**Response (200 OK)**:
```json
{
  "asset_id": "uuid",
  "asset_symbol": "BUIDL",
  "composite_score": 15,
  "risk_level": "low",
  "breakdown": {
    "market_risk": {
      "score": 20,
      "factors": ["High liquidity", "Low volatility"]
    },
    "credit_risk": {
      "score": 5,
      "factors": ["AAA sovereign backing", "Short maturity"]
    },
    "regulatory_risk": {
      "score": 15,
      "factors": ["Regulated issuer", "US jurisdiction"]
    },
    "technical_risk": {
      "score": 20,
      "factors": ["Audited smart contracts", "Centralized oracle dependency"]
    }
  },
  "calculated_at": "2025-10-23T12:00:00Z"
}
```

---

## Portfolio

### GET /portfolio

Get user's portfolio holdings.

**Response (200 OK)**:
```json
{
  "total_value": 15000.50,
  "total_cost_basis": 14500.00,
  "total_pnl": 500.50,
  "pnl_percentage": 3.45,
  "holdings": [
    {
      "asset_id": "uuid",
      "symbol": "BUIDL",
      "quantity": 10000,
      "avg_purchase_price": 0.99,
      "current_price": 1.00,
      "current_value": 10000,
      "pnl": 100,
      "pnl_percentage": 1.01,
      "allocation_percentage": 66.66
    }
  ],
  "last_updated": "2025-10-23T12:00:00Z"
}
```

---

### POST /portfolio/transaction

Add manual portfolio transaction.

**Request Body**:
```json
{
  "asset_id": "uuid",
  "transaction_type": "buy",
  "quantity": 1000,
  "price": 1.00,
  "transaction_date": "2025-10-20T14:30:00Z",
  "wallet_address": "0x..."
}
```

**Response (201 Created)**:
```json
{
  "transaction_id": "uuid",
  "message": "Transaction added successfully"
}
```

---

### POST /portfolio/sync-wallet

Sync portfolio from blockchain wallet.

**Request Body**:
```json
{
  "wallet_address": "0x...",
  "blockchain_network": "ethereum"
}
```

**Response (200 OK)**:
```json
{
  "synced_assets": 3,
  "new_transactions": 5,
  "message": "Wallet synced successfully"
}
```

---

## Alerts

### GET /alerts

List user's configured alerts.

**Response (200 OK)**:
```json
{
  "alerts": [
    {
      "alert_id": "uuid",
      "asset_id": "uuid",
      "asset_symbol": "BUIDL",
      "condition_type": "price_change",
      "condition_value": {
        "threshold": -5.0,
        "period": "24h"
      },
      "notification_method": "email",
      "is_active": true,
      "created_at": "2025-10-20T10:00:00Z"
    }
  ]
}
```

---

### POST /alerts

Create a new alert.

**Request Body**:
```json
{
  "asset_id": "uuid",
  "condition_type": "price_change",
  "condition_value": {
    "threshold": -5.0,
    "period": "24h",
    "direction": "down"
  },
  "notification_method": "telegram"
}
```

**Response (201 Created)**:
```json
{
  "alert_id": "uuid",
  "message": "Alert created successfully"
}
```

---

### DELETE /alerts/{alert_id}

Delete an alert.

**Response (200 OK)**:
```json
{
  "message": "Alert deleted successfully"
}
```

---

## Market Data

### GET /market/overview

Get RWA market overview statistics.

**Response (200 OK)**:
```json
{
  "total_market_cap": 232000000000,
  "total_volume_24h": 5000000000,
  "total_assets_tracked": 250,
  "asset_class_breakdown": {
    "stablecoins": 224900000000,
    "tokenized_treasuries": 5500000000,
    "private_credit": 558300000,
    "commodities": 1900000000,
    "real_estate": 50000000,
    "equities": 11400000
  },
  "top_performers_24h": [
    {"symbol": "XYZ", "change": 5.2}
  ],
  "worst_performers_24h": [
    {"symbol": "ABC", "change": -2.1}
  ]
}
```

---

## Reports (Enterprise Tier Only)

### POST /reports/asset/{asset_id}

Generate PDF report for an asset.

**Request Body**:
```json
{
  "include_sections": ["overview", "predictions", "risk_analysis", "on_chain_metrics"],
  "date_range": {
    "start": "2025-09-01",
    "end": "2025-10-23"
  }
}
```

**Response (200 OK)**:
```json
{
  "report_id": "uuid",
  "download_url": "https://s3.../reports/asset_report_uuid.pdf",
  "expires_at": "2025-10-30T00:00:00Z"
}
```

---

### POST /reports/portfolio

Generate PDF report for user's portfolio.

**Request Body**:
```json
{
  "include_sections": ["summary", "holdings", "performance", "risk_analysis"],
  "date_range": {
    "start": "2025-09-01",
    "end": "2025-10-23"
  }
}
```

**Response**: Same as asset report

---

## WebSocket API

**Connection URL**: `wss://api.rwa-prime.com/ws`

**Authentication**: Send JWT token on connection:
```json
{
  "type": "auth",
  "token": "your-jwt-token"
}
```

### Event Types

#### price_update
Real-time price updates for subscribed assets.

```json
{
  "event": "price_update",
  "data": {
    "asset_id": "uuid",
    "symbol": "BUIDL",
    "price": 1.0005,
    "timestamp": "2025-10-23T12:00:00Z"
  }
}
```

#### alert_triggered
Alert condition met.

```json
{
  "event": "alert_triggered",
  "data": {
    "alert_id": "uuid",
    "asset_symbol": "BUIDL",
    "condition": "Price dropped by 5%",
    "timestamp": "2025-10-23T12:00:00Z"
  }
}
```

#### portfolio_update
Portfolio value updated.

```json
{
  "event": "portfolio_update",
  "data": {
    "total_value": 15100.00,
    "pnl": 600.00,
    "pnl_percentage": 4.14
  }
}
```

---

## Error Responses

All API errors follow this format:

```json
{
  "error": {
    "code": "ASSET_NOT_FOUND",
    "message": "Asset with ID 'xyz' not found",
    "details": {},
    "timestamp": "2025-10-23T12:00:00Z"
  }
}
```

### Common Error Codes

| Code | HTTP Status | Description |
|------|-------------|-------------|
| `INVALID_CREDENTIALS` | 401 | Email or password incorrect |
| `TOKEN_EXPIRED` | 401 | JWT token has expired |
| `UNAUTHORIZED` | 401 | Missing or invalid authentication |
| `FORBIDDEN` | 403 | Insufficient permissions for tier |
| `ASSET_NOT_FOUND` | 404 | Asset does not exist |
| `VALIDATION_ERROR` | 422 | Request validation failed |
| `RATE_LIMIT_EXCEEDED` | 429 | Too many requests |
| `INTERNAL_SERVER_ERROR` | 500 | Server error |

---

## Rate Limiting

| Tier | Requests per Minute |
|------|---------------------|
| Explorer | 100 |
| Professional | 500 |
| Enterprise | Unlimited |

Rate limit headers:
```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1698076800
```

---

**Related Documentation**:
- [ARCHITECTURE.md](./ARCHITECTURE.md)
- [DEVELOPMENT_GUIDE.md](./DEVELOPMENT_GUIDE.md)
