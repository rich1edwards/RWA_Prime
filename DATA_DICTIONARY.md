# Data Dictionary

## Purpose

This document provides a comprehensive data dictionary for all database tables, columns, relationships, and business rules in the RWA Prime platform. It serves as the single source of truth for understanding data structures, constraints, and lineage.

---

## Table of Contents

- [Database Architecture](#database-architecture)
- [PostgreSQL Tables (Relational Data)](#postgresql-tables-relational-data)
  - [users](#users)
  - [assets](#assets)
  - [portfolios](#portfolios)
  - [portfolio_assets](#portfolio_assets)
  - [transactions](#transactions)
  - [predictions](#predictions)
  - [risk_scores](#risk_scores)
  - [alerts](#alerts)
  - [user_sessions](#user_sessions)
- [TimescaleDB Hypertables (Time-Series Data)](#timescaledb-hypertables-time-series-data)
  - [price_data](#price_data)
  - [onchain_metrics](#onchain_metrics)
  - [sentiment_scores](#sentiment_scores)
  - [volume_data](#volume_data)
- [Enumerations (ENUMs)](#enumerations-enums)
- [Indexes](#indexes)
- [Constraints and Business Rules](#constraints-and-business-rules)
- [Data Lineage](#data-lineage)
- [Retention Policies](#retention-policies)

---

## Database Architecture

### Database Types

**PostgreSQL 15+**: Relational data (users, assets, portfolios, transactions)
**TimescaleDB Extension**: Time-series data (price history, on-chain metrics, sentiment)

### Schema Organization

```
rwa_prime_db
├── public (schema)
│   ├── users
│   ├── assets
│   ├── portfolios
│   ├── portfolio_assets
│   ├── transactions
│   ├── predictions
│   ├── risk_scores
│   ├── alerts
│   └── user_sessions
└── timeseries (schema)
    ├── price_data (hypertable)
    ├── onchain_metrics (hypertable)
    ├── sentiment_scores (hypertable)
    └── volume_data (hypertable)
```

---

## PostgreSQL Tables (Relational Data)

### users

**Purpose**: Stores user account information for authentication and authorization.

**Business Context**: Represents individual users (investors, traders, analysts) who use the RWA Prime platform.

| Column | Type | Nullable | Default | Description | Business Rules |
|--------|------|----------|---------|-------------|----------------|
| `id` | UUID | NO | `gen_random_uuid()` | Primary key, unique user identifier | Auto-generated on insert |
| `email` | VARCHAR(255) | NO | - | User's email address | Must be unique, valid email format |
| `password_hash` | VARCHAR(255) | NO | - | Bcrypt hashed password | Hashed with bcrypt, salt rounds: 12 |
| `full_name` | VARCHAR(255) | NO | - | User's full name | 1-255 characters |
| `tier` | user_tier | NO | `'explorer'` | SaaS subscription tier | See `user_tier` enum |
| `is_verified` | BOOLEAN | NO | `false` | Email verification status | Must verify email to access features |
| `is_active` | BOOLEAN | NO | `true` | Account active status | Set to false to soft-delete |
| `two_factor_enabled` | BOOLEAN | NO | `false` | 2FA enabled status | Enterprise tier enforces this |
| `two_factor_secret` | VARCHAR(32) | YES | NULL | TOTP secret for 2FA | Encrypted at rest |
| `failed_login_attempts` | INTEGER | NO | `0` | Count of failed login attempts | Reset on successful login, lock account at 5 |
| `locked_until` | TIMESTAMP | YES | NULL | Account lock expiry time | Account locked for 15 minutes after 5 failed attempts |
| `last_login_at` | TIMESTAMP | YES | NULL | Timestamp of last successful login | Updated on each login |
| `created_at` | TIMESTAMP | NO | `NOW()` | Account creation timestamp | Immutable |
| `updated_at` | TIMESTAMP | NO | `NOW()` | Last update timestamp | Auto-updated on row change |

**Indexes**:
- `PRIMARY KEY (id)`
- `UNIQUE INDEX idx_users_email ON users(email)`
- `INDEX idx_users_tier ON users(tier)`

**Relationships**:
- `portfolios.user_id → users.id` (one-to-many)
- `alerts.user_id → users.id` (one-to-many)
- `user_sessions.user_id → users.id` (one-to-many)

---

### assets

**Purpose**: Stores information about Real-World Assets (RWAs) available on the platform.

**Business Context**: Represents tokenized real-world assets (treasuries, real estate, commodities) that users can analyze and track.

| Column | Type | Nullable | Default | Description | Business Rules |
|--------|------|----------|---------|-------------|----------------|
| `id` | UUID | NO | `gen_random_uuid()` | Primary key, unique asset identifier | Auto-generated |
| `symbol` | VARCHAR(20) | NO | - | Asset ticker symbol (e.g., 'USDC', 'USDY') | Uppercase, 2-10 characters, unique |
| `name` | VARCHAR(255) | NO | - | Full asset name | Human-readable name |
| `asset_class` | asset_class | NO | - | Classification of asset type | See `asset_class` enum |
| `blockchain_network` | blockchain_network | NO | - | Blockchain where asset is deployed | See `blockchain_network` enum |
| `contract_address` | VARCHAR(42) | YES | NULL | Smart contract address | Ethereum: 0x + 40 hex chars |
| `issuer` | VARCHAR(255) | YES | NULL | Asset issuer/sponsor | Company or entity name |
| `website_url` | VARCHAR(500) | YES | NULL | Official website URL | Valid HTTPS URL |
| `whitepaper_url` | VARCHAR(500) | YES | NULL | Whitepaper URL | PDF or webpage |
| `description` | TEXT | YES | NULL | Asset description | Markdown supported |
| `launch_date` | DATE | YES | NULL | Asset launch/deployment date | Cannot be in future |
| `total_supply` | NUMERIC(30, 10) | YES | NULL | Total token supply | Positive number |
| `circulating_supply` | NUMERIC(30, 10) | YES | NULL | Circulating token supply | ≤ total_supply |
| `decimals` | INTEGER | NO | `18` | Token decimal places | Typically 18 for ERC-20 |
| `is_active` | BOOLEAN | NO | `true` | Asset is actively tracked | Inactive assets hidden from screener |
| `created_at` | TIMESTAMP | NO | `NOW()` | Record creation timestamp | Immutable |
| `updated_at` | TIMESTAMP | NO | `NOW()` | Last update timestamp | Auto-updated |

**Indexes**:
- `PRIMARY KEY (id)`
- `UNIQUE INDEX idx_assets_symbol ON assets(symbol)`
- `INDEX idx_assets_class ON assets(asset_class)`
- `INDEX idx_assets_blockchain ON assets(blockchain_network)`
- `INDEX idx_assets_active ON assets(is_active) WHERE is_active = true`

**Relationships**:
- `price_data.asset_id → assets.id` (one-to-many)
- `predictions.asset_id → assets.id` (one-to-many)
- `risk_scores.asset_id → assets.id` (one-to-many)
- `portfolio_assets.asset_id → assets.id` (one-to-many)

---

### portfolios

**Purpose**: Stores user-created portfolios for tracking asset holdings.

**Business Context**: Represents investment portfolios that users create to track their RWA holdings and performance.

| Column | Type | Nullable | Default | Description | Business Rules |
|--------|------|----------|---------|-------------|----------------|
| `id` | UUID | NO | `gen_random_uuid()` | Primary key, unique portfolio ID | Auto-generated |
| `user_id` | UUID | NO | - | Owner of the portfolio | Foreign key to users.id |
| `name` | VARCHAR(100) | NO | - | Portfolio name | User-defined, 1-100 characters |
| `description` | TEXT | YES | NULL | Portfolio description | Optional notes |
| `sync_method` | sync_method | NO | `'manual'` | How portfolio is updated | See `sync_method` enum |
| `wallet_address` | VARCHAR(42) | YES | NULL | Blockchain wallet address | Required if sync_method = 'wallet_sync' |
| `blockchain_network` | blockchain_network | YES | NULL | Network for wallet sync | Required if sync_method = 'wallet_sync' |
| `total_value_usd` | NUMERIC(20, 2) | NO | `0.00` | Total portfolio value in USD | Calculated field, updated daily |
| `cost_basis_usd` | NUMERIC(20, 2) | NO | `0.00` | Total cost basis in USD | Sum of all purchase prices |
| `pnl_usd` | NUMERIC(20, 2) | NO | `0.00` | Profit/Loss in USD | total_value_usd - cost_basis_usd |
| `pnl_percentage` | NUMERIC(10, 4) | NO | `0.0000` | Profit/Loss percentage | (pnl_usd / cost_basis_usd) * 100 |
| `last_synced_at` | TIMESTAMP | YES | NULL | Last wallet sync timestamp | Updated on each sync |
| `is_default` | BOOLEAN | NO | `false` | Is this the default portfolio | Only one default per user |
| `created_at` | TIMESTAMP | NO | `NOW()` | Portfolio creation timestamp | Immutable |
| `updated_at` | TIMESTAMP | NO | `NOW()` | Last update timestamp | Auto-updated |

**Indexes**:
- `PRIMARY KEY (id)`
- `INDEX idx_portfolios_user ON portfolios(user_id)`
- `INDEX idx_portfolios_user_default ON portfolios(user_id, is_default) WHERE is_default = true`

**Constraints**:
- `FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE`
- `CHECK (total_value_usd >= 0)`
- `CHECK (cost_basis_usd >= 0)`
- Portfolio limit per tier: Explorer (3), Professional (10), Enterprise (unlimited)

**Relationships**:
- `portfolio_assets.portfolio_id → portfolios.id` (one-to-many)
- `transactions.portfolio_id → portfolios.id` (one-to-many)

---

### portfolio_assets

**Purpose**: Join table linking portfolios to assets with quantity and cost basis.

**Business Context**: Represents individual asset holdings within a portfolio.

| Column | Type | Nullable | Default | Description | Business Rules |
|--------|------|----------|---------|-------------|----------------|
| `id` | UUID | NO | `gen_random_uuid()` | Primary key | Auto-generated |
| `portfolio_id` | UUID | NO | - | Portfolio this asset belongs to | Foreign key to portfolios.id |
| `asset_id` | UUID | NO | - | Asset being held | Foreign key to assets.id |
| `quantity` | NUMERIC(30, 10) | NO | - | Amount of asset held | Must be > 0 |
| `average_cost_usd` | NUMERIC(20, 10) | NO | - | Average purchase price per token | Must be ≥ 0 |
| `total_cost_usd` | NUMERIC(20, 2) | NO | - | Total cost basis | quantity * average_cost_usd |
| `current_price_usd` | NUMERIC(20, 10) | YES | NULL | Latest price per token | Updated from price_data |
| `current_value_usd` | NUMERIC(20, 2) | YES | NULL | Current total value | quantity * current_price_usd |
| `pnl_usd` | NUMERIC(20, 2) | YES | NULL | Profit/loss | current_value_usd - total_cost_usd |
| `pnl_percentage` | NUMERIC(10, 4) | YES | NULL | Profit/loss percentage | (pnl_usd / total_cost_usd) * 100 |
| `first_acquired_at` | TIMESTAMP | NO | `NOW()` | When first purchased | From first transaction |
| `last_updated_at` | TIMESTAMP | NO | `NOW()` | Last price update | Updated when current_price changes |

**Indexes**:
- `PRIMARY KEY (id)`
- `UNIQUE INDEX idx_portfolio_assets_unique ON portfolio_assets(portfolio_id, asset_id)`
- `INDEX idx_portfolio_assets_portfolio ON portfolio_assets(portfolio_id)`
- `INDEX idx_portfolio_assets_asset ON portfolio_assets(asset_id)`

**Constraints**:
- `FOREIGN KEY (portfolio_id) REFERENCES portfolios(id) ON DELETE CASCADE`
- `FOREIGN KEY (asset_id) REFERENCES assets(id) ON DELETE RESTRICT`
- `CHECK (quantity > 0)`
- `CHECK (average_cost_usd >= 0)`

---

### transactions

**Purpose**: Records all portfolio transactions (buy, sell, transfer).

**Business Context**: Audit trail of all portfolio activity for performance calculation and reporting.

| Column | Type | Nullable | Default | Description | Business Rules |
|--------|------|----------|---------|-------------|----------------|
| `id` | UUID | NO | `gen_random_uuid()` | Primary key | Auto-generated |
| `portfolio_id` | UUID | NO | - | Portfolio this transaction belongs to | Foreign key to portfolios.id |
| `asset_id` | UUID | NO | - | Asset being transacted | Foreign key to assets.id |
| `transaction_type` | transaction_type | NO | - | Type of transaction | See `transaction_type` enum |
| `quantity` | NUMERIC(30, 10) | NO | - | Amount transacted | Must be > 0 |
| `price_per_token_usd` | NUMERIC(20, 10) | NO | - | Price per token at transaction | Must be ≥ 0 |
| `total_value_usd` | NUMERIC(20, 2) | NO | - | Total transaction value | quantity * price_per_token_usd |
| `fee_usd` | NUMERIC(20, 2) | NO | `0.00` | Transaction fees | Gas fees, exchange fees |
| `transaction_hash` | VARCHAR(66) | YES | NULL | Blockchain transaction hash | 0x + 64 hex chars for Ethereum |
| `notes` | TEXT | YES | NULL | User notes | Optional description |
| `transaction_date` | TIMESTAMP | NO | - | When transaction occurred | User-provided or synced |
| `created_at` | TIMESTAMP | NO | `NOW()` | Record creation timestamp | Immutable |

**Indexes**:
- `PRIMARY KEY (id)`
- `INDEX idx_transactions_portfolio ON transactions(portfolio_id, transaction_date DESC)`
- `INDEX idx_transactions_asset ON transactions(asset_id)`
- `UNIQUE INDEX idx_transactions_hash ON transactions(transaction_hash) WHERE transaction_hash IS NOT NULL`

**Constraints**:
- `FOREIGN KEY (portfolio_id) REFERENCES portfolios(id) ON DELETE CASCADE`
- `FOREIGN KEY (asset_id) REFERENCES assets(id) ON DELETE RESTRICT`
- `CHECK (quantity > 0)`
- `CHECK (price_per_token_usd >= 0)`
- `CHECK (fee_usd >= 0)`

---

### predictions

**Purpose**: Stores ML-generated price predictions for assets.

**Business Context**: AI-generated price forecasts used in asset analysis and alerts.

| Column | Type | Nullable | Default | Description | Business Rules |
|--------|------|----------|---------|-------------|----------------|
| `id` | UUID | NO | `gen_random_uuid()` | Primary key | Auto-generated |
| `asset_id` | UUID | NO | - | Asset being predicted | Foreign key to assets.id |
| `prediction_horizon` | prediction_horizon | NO | - | Forecast timeframe | See `prediction_horizon` enum (7d, 30d) |
| `predicted_price` | NUMERIC(20, 10) | NO | - | Predicted price in USD | Must be > 0 |
| `confidence_lower` | NUMERIC(20, 10) | NO | - | Lower bound of 95% confidence interval | Must be > 0 |
| `confidence_upper` | NUMERIC(20, 10) | NO | - | Upper bound of 95% confidence interval | Must be > 0 |
| `confidence_score` | NUMERIC(5, 4) | NO | - | Model confidence (0-1) | 0 = low confidence, 1 = high |
| `model_version` | VARCHAR(50) | NO | - | ML model version used | e.g., 'lstm_v2.1', 'arima_v1.3' |
| `feature_importance` | JSONB | YES | NULL | Top features driving prediction | JSON object with feature names and weights |
| `prediction_date` | TIMESTAMP | NO | `NOW()` | When prediction was generated | Immutable |
| `target_date` | DATE | NO | - | Date being predicted | prediction_date + horizon |
| `actual_price` | NUMERIC(20, 10) | YES | NULL | Actual price on target_date | Filled after target_date for accuracy tracking |
| `prediction_error` | NUMERIC(10, 4) | YES | NULL | Percentage error | ((actual - predicted) / actual) * 100 |

**Indexes**:
- `PRIMARY KEY (id)`
- `INDEX idx_predictions_asset_date ON predictions(asset_id, prediction_date DESC)`
- `INDEX idx_predictions_horizon ON predictions(prediction_horizon)`
- `INDEX idx_predictions_target ON predictions(target_date) WHERE actual_price IS NULL`

**Constraints**:
- `FOREIGN KEY (asset_id) REFERENCES assets(id) ON DELETE CASCADE`
- `CHECK (predicted_price > 0)`
- `CHECK (confidence_lower > 0 AND confidence_lower < predicted_price)`
- `CHECK (confidence_upper > predicted_price)`
- `CHECK (confidence_score >= 0 AND confidence_score <= 1)`

---

### risk_scores

**Purpose**: Stores composite risk scores and component breakdowns for assets.

**Business Context**: Multi-factor risk assessment used for investment decision support.

| Column | Type | Nullable | Default | Description | Business Rules |
|--------|------|----------|---------|-------------|----------------|
| `id` | UUID | NO | `gen_random_uuid()` | Primary key | Auto-generated |
| `asset_id` | UUID | NO | - | Asset being scored | Foreign key to assets.id |
| `overall_risk_score` | NUMERIC(5, 2) | NO | - | Composite risk score (0-100) | Weighted average of components |
| `market_risk` | NUMERIC(5, 2) | YES | NULL | Market volatility risk (0-100) | Higher = more volatile |
| `credit_risk` | NUMERIC(5, 2) | YES | NULL | Default/credit risk (0-100) | Higher = higher default risk |
| `technical_risk` | NUMERIC(5, 2) | YES | NULL | Smart contract risk (0-100) | Based on audits, exploits |
| `regulatory_risk` | NUMERIC(5, 2) | YES | NULL | Regulatory compliance risk (0-100) | Based on jurisdiction, compliance |
| `risk_level` | risk_level | NO | - | Categorized risk level | See `risk_level` enum |
| `calculation_date` | TIMESTAMP | NO | `NOW()` | When score was calculated | Updated daily |
| `model_version` | VARCHAR(50) | NO | - | Risk model version | e.g., 'risk_v1.2' |

**Indexes**:
- `PRIMARY KEY (id)`
- `INDEX idx_risk_scores_asset_date ON risk_scores(asset_id, calculation_date DESC)`
- `INDEX idx_risk_scores_level ON risk_scores(risk_level)`

**Constraints**:
- `FOREIGN KEY (asset_id) REFERENCES assets(id) ON DELETE CASCADE`
- `CHECK (overall_risk_score >= 0 AND overall_risk_score <= 100)`
- `CHECK (market_risk IS NULL OR (market_risk >= 0 AND market_risk <= 100))`
- `CHECK (credit_risk IS NULL OR (credit_risk >= 0 AND credit_risk <= 100))`
- `CHECK (technical_risk IS NULL OR (technical_risk >= 0 AND technical_risk <= 100))`
- `CHECK (regulatory_risk IS NULL OR (regulatory_risk >= 0 AND regulatory_risk <= 100))`

---

### alerts

**Purpose**: User-configured alerts for price, risk, and sentiment changes.

**Business Context**: Notification system for monitoring asset conditions.

| Column | Type | Nullable | Default | Description | Business Rules |
|--------|------|----------|---------|-------------|----------------|
| `id` | UUID | NO | `gen_random_uuid()` | Primary key | Auto-generated |
| `user_id` | UUID | NO | - | Alert owner | Foreign key to users.id |
| `asset_id` | UUID | NO | - | Asset to monitor | Foreign key to assets.id |
| `alert_type` | alert_type | NO | - | Type of alert | See `alert_type` enum |
| `condition` | alert_condition | NO | - | Trigger condition | See `alert_condition` enum |
| `threshold_value` | NUMERIC(20, 10) | NO | - | Threshold to trigger alert | Depends on alert_type |
| `is_active` | BOOLEAN | NO | `true` | Alert is currently active | User can pause alerts |
| `notification_method` | notification_method | NO | `'email'` | How to notify user | See `notification_method` enum |
| `last_triggered_at` | TIMESTAMP | YES | NULL | Last time alert fired | Reset when re-triggered |
| `trigger_count` | INTEGER | NO | `0` | Number of times triggered | Reset when alert modified |
| `created_at` | TIMESTAMP | NO | `NOW()` | Alert creation timestamp | Immutable |
| `updated_at` | TIMESTAMP | NO | `NOW()` | Last update timestamp | Auto-updated |

**Indexes**:
- `PRIMARY KEY (id)`
- `INDEX idx_alerts_user ON alerts(user_id, is_active)`
- `INDEX idx_alerts_asset ON alerts(asset_id, is_active) WHERE is_active = true`

**Constraints**:
- `FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE`
- `FOREIGN KEY (asset_id) REFERENCES assets(id) ON DELETE CASCADE`
- Alert limit per tier: Explorer (10), Professional (50), Enterprise (unlimited)

---

### user_sessions

**Purpose**: Stores active user sessions for authentication and JWT refresh tokens.

**Business Context**: Enables secure session management and token revocation.

| Column | Type | Nullable | Default | Description | Business Rules |
|--------|------|----------|---------|-------------|----------------|
| `id` | UUID | NO | `gen_random_uuid()` | Primary key | Auto-generated |
| `user_id` | UUID | NO | - | Session owner | Foreign key to users.id |
| `refresh_token_hash` | VARCHAR(255) | NO | - | Hashed refresh token | SHA-256 hash |
| `device_info` | VARCHAR(500) | YES | NULL | User agent / device info | For security monitoring |
| `ip_address` | INET | YES | NULL | Client IP address | For security monitoring |
| `expires_at` | TIMESTAMP | NO | - | Session expiry time | 7 days from creation |
| `is_revoked` | BOOLEAN | NO | `false` | Session has been revoked | Revoke on logout or security event |
| `created_at` | TIMESTAMP | NO | `NOW()` | Session creation timestamp | Immutable |

**Indexes**:
- `PRIMARY KEY (id)`
- `INDEX idx_sessions_user ON user_sessions(user_id, is_revoked) WHERE is_revoked = false`
- `INDEX idx_sessions_expires ON user_sessions(expires_at) WHERE is_revoked = false`
- `UNIQUE INDEX idx_sessions_token ON user_sessions(refresh_token_hash)`

**Constraints**:
- `FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE`
- `CHECK (expires_at > created_at)`

**Cleanup**: Expired and revoked sessions are deleted after 30 days.

---

## TimescaleDB Hypertables (Time-Series Data)

### price_data

**Purpose**: Real-time and historical price data for all assets.

**Business Context**: Core time-series data powering price charts, predictions, and analytics.

| Column | Type | Nullable | Default | Description | Business Rules |
|--------|------|----------|---------|-------------|----------------|
| `time` | TIMESTAMPTZ | NO | - | Timestamp of price observation | Partitioned by time (1 day chunks) |
| `asset_id` | UUID | NO | - | Asset being priced | Foreign key to assets.id |
| `price_usd` | NUMERIC(20, 10) | NO | - | Price in USD | Must be > 0 |
| `source` | VARCHAR(50) | NO | - | Data source | e.g., 'coinapi', 'amberdata' |
| `volume_24h` | NUMERIC(30, 2) | YES | NULL | 24-hour trading volume | Optional |

**Hypertable Configuration**:
- **Partitioning**: 1-day chunks on `time` column
- **Compression**: Enabled (compress after 7 days, 20x compression ratio)
- **Retention**: 5 years (raw data), continuous aggregates retained indefinitely

**Indexes**:
- `PRIMARY KEY (time, asset_id)` (composite)
- `INDEX idx_price_asset_time ON price_data(asset_id, time DESC)`

**Constraints**:
- `FOREIGN KEY (asset_id) REFERENCES assets(id) ON DELETE CASCADE`
- `CHECK (price_usd > 0)`

**Continuous Aggregates** (materialized views):
```sql
-- 1-hour candles
CREATE MATERIALIZED VIEW price_1h
WITH (timescaledb.continuous) AS
SELECT asset_id,
       time_bucket('1 hour', time) AS bucket,
       FIRST(price_usd, time) AS open,
       MAX(price_usd) AS high,
       MIN(price_usd) AS low,
       LAST(price_usd, time) AS close,
       AVG(price_usd) AS avg_price
FROM price_data
GROUP BY asset_id, bucket;

-- 1-day candles
CREATE MATERIALIZED VIEW price_1d
WITH (timescaledb.continuous) AS
SELECT asset_id,
       time_bucket('1 day', time) AS bucket,
       FIRST(price_usd, time) AS open,
       MAX(price_usd) AS high,
       MIN(price_usd) AS low,
       LAST(price_usd, time) AS close,
       AVG(price_usd) AS avg_price,
       SUM(volume_24h) AS total_volume
FROM price_data
GROUP BY asset_id, bucket;
```

---

### onchain_metrics

**Purpose**: On-chain blockchain metrics (transaction count, active addresses, TVL).

**Business Context**: On-chain activity metrics for RWA protocol health assessment.

| Column | Type | Nullable | Default | Description | Business Rules |
|--------|------|----------|---------|-------------|----------------|
| `time` | TIMESTAMPTZ | NO | - | Timestamp of metric observation | Partitioned by time |
| `asset_id` | UUID | NO | - | Asset being measured | Foreign key to assets.id |
| `transaction_count_24h` | INTEGER | YES | NULL | 24-hour transaction count | ≥ 0 |
| `active_addresses_24h` | INTEGER | YES | NULL | 24-hour unique active addresses | ≥ 0 |
| `total_value_locked` | NUMERIC(30, 2) | YES | NULL | Total Value Locked (TVL) in USD | ≥ 0 |
| `market_cap` | NUMERIC(30, 2) | YES | NULL | Market capitalization in USD | ≥ 0 |
| `holder_count` | INTEGER | YES | NULL | Number of token holders | ≥ 0 |
| `source` | VARCHAR(50) | NO | - | Data source | e.g., 'amberdata', 'bitquery' |

**Hypertable Configuration**:
- **Partitioning**: 7-day chunks on `time`
- **Compression**: Enabled (compress after 30 days)
- **Retention**: 3 years

**Indexes**:
- `PRIMARY KEY (time, asset_id)`
- `INDEX idx_onchain_asset_time ON onchain_metrics(asset_id, time DESC)`

---

### sentiment_scores

**Purpose**: Sentiment analysis scores from news articles and social media.

**Business Context**: Market sentiment tracking for risk assessment and predictions.

| Column | Type | Nullable | Default | Description | Business Rules |
|--------|------|----------|---------|-------------|----------------|
| `time` | TIMESTAMPTZ | NO | - | Timestamp of sentiment observation | Partitioned by time |
| `asset_id` | UUID | NO | - | Asset being analyzed | Foreign key to assets.id |
| `sentiment_score` | NUMERIC(5, 4) | NO | - | Sentiment score (-1 to +1) | -1 = very negative, +1 = very positive |
| `article_count` | INTEGER | NO | - | Number of articles analyzed | ≥ 1 |
| `source` | VARCHAR(50) | NO | - | Data source | 'newsapi', 'twitter', 'reddit' |
| `model_version` | VARCHAR(50) | NO | - | Sentiment model version | e.g., 'finbert_v1.0' |

**Hypertable Configuration**:
- **Partitioning**: 1-day chunks
- **Compression**: Enabled (compress after 30 days)
- **Retention**: 2 years

**Indexes**:
- `PRIMARY KEY (time, asset_id, source)`
- `INDEX idx_sentiment_asset_time ON sentiment_scores(asset_id, time DESC)`

**Constraints**:
- `CHECK (sentiment_score >= -1 AND sentiment_score <= 1)`
- `CHECK (article_count >= 1)`

---

### volume_data

**Purpose**: Trading volume data across exchanges.

**Business Context**: Liquidity tracking for market analysis.

| Column | Type | Nullable | Default | Description | Business Rules |
|--------|------|----------|---------|-------------|----------------|
| `time` | TIMESTAMPTZ | NO | - | Timestamp of volume observation | Partitioned by time |
| `asset_id` | UUID | NO | - | Asset being traded | Foreign key to assets.id |
| `volume_usd` | NUMERIC(30, 2) | NO | - | Trading volume in USD | ≥ 0 |
| `exchange` | VARCHAR(100) | NO | - | Exchange name | e.g., 'Uniswap', 'Curve' |
| `source` | VARCHAR(50) | NO | - | Data source | e.g., 'coinapi' |

**Hypertable Configuration**:
- **Partitioning**: 1-day chunks
- **Compression**: Enabled (compress after 14 days)
- **Retention**: 1 year

---

## Enumerations (ENUMs)

### user_tier
```sql
CREATE TYPE user_tier AS ENUM (
    'explorer',      -- $29/month - 3 portfolios, 10 alerts, 7-day predictions
    'professional',  -- $149/month - 10 portfolios, 50 alerts, 30-day predictions
    'enterprise'     -- Custom - unlimited portfolios/alerts, API access
);
```

### asset_class
```sql
CREATE TYPE asset_class AS ENUM (
    'tokenized_treasury',    -- T-bills, bonds (e.g., OUSG, BENJI)
    'tokenized_real_estate', -- Real estate tokens (e.g., RealT)
    'tokenized_commodity',   -- Gold, silver tokens
    'tokenized_equity',      -- Equity tokens
    'stablecoin',            -- Fiat-backed stablecoins (USDC, USDT)
    'yield_bearing',         -- Yield-bearing stablecoins (USDY, sUSDe)
    'other'                  -- Other RWA types
);
```

### blockchain_network
```sql
CREATE TYPE blockchain_network AS ENUM (
    'ethereum',
    'polygon',
    'arbitrum',
    'optimism',
    'avalanche',
    'solana',
    'stellar',
    'other'
);
```

### sync_method
```sql
CREATE TYPE sync_method AS ENUM (
    'manual',       -- User manually enters transactions
    'wallet_sync'   -- Automated sync from blockchain wallet
);
```

### transaction_type
```sql
CREATE TYPE transaction_type AS ENUM (
    'buy',          -- Purchase of asset
    'sell',         -- Sale of asset
    'transfer_in',  -- Transfer into portfolio
    'transfer_out'  -- Transfer out of portfolio
);
```

### prediction_horizon
```sql
CREATE TYPE prediction_horizon AS ENUM (
    '7d',   -- 7-day forecast
    '30d'   -- 30-day forecast
);
```

### risk_level
```sql
CREATE TYPE risk_level AS ENUM (
    'very_low',    -- 0-20
    'low',         -- 21-40
    'moderate',    -- 41-60
    'high',        -- 61-80
    'very_high'    -- 81-100
);
```

### alert_type
```sql
CREATE TYPE alert_type AS ENUM (
    'price',           -- Price threshold alert
    'price_change',    -- Percentage change alert
    'risk_score',      -- Risk score threshold
    'sentiment',       -- Sentiment score threshold
    'volume',          -- Volume threshold
    'prediction'       -- Prediction change alert
);
```

### alert_condition
```sql
CREATE TYPE alert_condition AS ENUM (
    'above',          -- Trigger when value goes above threshold
    'below',          -- Trigger when value goes below threshold
    'crosses_above',  -- Trigger once when crossing above
    'crosses_below'   -- Trigger once when crossing below
);
```

### notification_method
```sql
CREATE TYPE notification_method AS ENUM (
    'email',          -- Email notification
    'sms',            -- SMS notification (Enterprise only)
    'push',           -- Mobile push notification
    'webhook'         -- Webhook (Enterprise only)
);
```

---

## Indexes

### Composite Indexes

```sql
-- Users
CREATE INDEX idx_users_tier_active ON users(tier, is_active) WHERE is_active = true;

-- Assets
CREATE INDEX idx_assets_class_active ON assets(asset_class, is_active) WHERE is_active = true;

-- Portfolios
CREATE INDEX idx_portfolios_user_updated ON portfolios(user_id, updated_at DESC);

-- Predictions
CREATE INDEX idx_predictions_asset_horizon_date ON predictions(asset_id, prediction_horizon, prediction_date DESC);

-- Risk Scores
CREATE INDEX idx_risk_asset_level_date ON risk_scores(asset_id, risk_level, calculation_date DESC);

-- Price Data (Hypertable)
CREATE INDEX idx_price_time_asset ON price_data(time DESC, asset_id);
```

---

## Constraints and Business Rules

### Portfolio Limits by Tier

| Tier | Max Portfolios | Max Alerts | Max API Calls/Day |
|------|----------------|------------|-------------------|
| Explorer | 3 | 10 | N/A (no API access) |
| Professional | 10 | 50 | N/A (no API access) |
| Enterprise | Unlimited | Unlimited | 100,000 |

**Enforcement**: Application-level checks before INSERT.

### Data Quality Rules

**Price Data**:
- Price cannot change by >50% in 1 minute (outlier detection)
- Price must be > 0
- Timestamp cannot be in the future

**Transactions**:
- `transaction_date` cannot be in the future
- `sell` quantity cannot exceed portfolio holdings
- `transaction_hash` must be unique (if provided)

**Predictions**:
- `confidence_lower < predicted_price < confidence_upper`
- `target_date = prediction_date + horizon`
- `confidence_score` must be between 0 and 1

### Calculated Fields

**Portfolio Performance**:
```sql
-- PnL calculation
pnl_usd = total_value_usd - cost_basis_usd
pnl_percentage = (pnl_usd / cost_basis_usd) * 100

-- Total value calculation
total_value_usd = SUM(portfolio_assets.current_value_usd)
```

**Risk Level Categorization**:
```sql
CASE
    WHEN overall_risk_score BETWEEN 0 AND 20 THEN 'very_low'
    WHEN overall_risk_score BETWEEN 21 AND 40 THEN 'low'
    WHEN overall_risk_score BETWEEN 41 AND 60 THEN 'moderate'
    WHEN overall_risk_score BETWEEN 61 AND 80 THEN 'high'
    WHEN overall_risk_score BETWEEN 81 AND 100 THEN 'very_high'
END
```

---

## Data Lineage

### Price Data Pipeline

```
External APIs (CoinAPI, Amberdata)
    ↓
Kafka Topic: price-updates
    ↓
Spark Streaming (Bronze → Silver)
    ↓
TimescaleDB: price_data (raw 1-minute data)
    ↓
Continuous Aggregates:
    - price_1h (1-hour candles)
    - price_1d (1-day candles)
    ↓
ML Models (Predictions)
    ↓
PostgreSQL: predictions table
```

### Sentiment Data Pipeline

```
NewsAPI.ai / Twitter API
    ↓
Kafka Topic: news-updates
    ↓
NLP Service (FinBERT sentiment analysis)
    ↓
Kafka Topic: sentiment-scores
    ↓
Spark Streaming (Bronze → Silver)
    ↓
TimescaleDB: sentiment_scores
    ↓
Risk Scoring Model
    ↓
PostgreSQL: risk_scores table
```

---

## Retention Policies

### PostgreSQL Tables

| Table | Retention | Cleanup Strategy |
|-------|-----------|------------------|
| `users` | Indefinite | Soft delete (is_active = false) |
| `assets` | Indefinite | Soft delete (is_active = false) |
| `portfolios` | 1 year after user deletion | Hard delete after 1 year |
| `transactions` | Indefinite (audit trail) | Never delete |
| `predictions` | 2 years | Delete records older than 2 years |
| `risk_scores` | 1 year | Delete records older than 1 year |
| `alerts` | 90 days after deactivation | Delete inactive alerts |
| `user_sessions` | 30 days after expiry/revocation | Delete expired sessions |

### TimescaleDB Hypertables

```sql
-- Price data: compress after 7 days, retain raw data for 5 years
SELECT add_retention_policy('price_data', INTERVAL '5 years');
SELECT add_compression_policy('price_data', INTERVAL '7 days');

-- On-chain metrics: compress after 30 days, retain for 3 years
SELECT add_retention_policy('onchain_metrics', INTERVAL '3 years');
SELECT add_compression_policy('onchain_metrics', INTERVAL '30 days');

-- Sentiment scores: compress after 30 days, retain for 2 years
SELECT add_retention_policy('sentiment_scores', INTERVAL '2 years');
SELECT add_compression_policy('sentiment_scores', INTERVAL '30 days');

-- Volume data: compress after 14 days, retain for 1 year
SELECT add_retention_policy('volume_data', INTERVAL '1 year');
SELECT add_compression_policy('volume_data', INTERVAL '14 days');
```

---

**Last Updated**: October 24, 2025
**Database Version**: PostgreSQL 15.4 + TimescaleDB 2.11
**Schema Version**: 1.0

---

**Remember**: The data dictionary is the single source of truth for data structures. Update this document whenever schema changes occur! 📊
