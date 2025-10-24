# Error Codes and Handling Guide

## Purpose

This document defines **standardized error codes**, error response formats, handling patterns, retry strategies, and user-facing messages for the RWA Prime platform. Consistent error handling improves debugging, user experience, and system reliability.

---

## Table of Contents

- [Error Response Format](#error-response-format)
- [Error Code Categories](#error-code-categories)
- [Authentication Errors (AUTH)](#authentication-errors-auth)
- [Authorization Errors (AUTHZ)](#authorization-errors-authz)
- [Asset Errors (ASSET)](#asset-errors-asset)
- [Prediction Errors (PRED)](#prediction-errors-pred)
- [Risk Scoring Errors (RISK)](#risk-scoring-errors-risk)
- [Portfolio Errors (PORT)](#portfolio-errors-port)
- [Alert Errors (ALERT)](#alert-errors-alert)
- [Data Ingestion Errors (INGEST)](#data-ingestion-errors-ingest)
- [External API Errors (EXT)](#external-api-errors-ext)
- [Database Errors (DB)](#database-errors-db)
- [Validation Errors (VAL)](#validation-errors-val)
- [Rate Limiting Errors (RATE)](#rate-limiting-errors-rate)
- [System Errors (SYS)](#system-errors-sys)
- [Error Handling Patterns](#error-handling-patterns)
- [Retry Strategies](#retry-strategies)
- [Logging Standards](#logging-standards)
- [Client Error Handling](#client-error-handling)

---

## Error Response Format

### Standard Error Response

All API errors follow this JSON format:

```json
{
  "error": {
    "code": "ERR_AUTH_001",
    "message": "Invalid or expired access token",
    "details": "The access token has expired. Please refresh your token.",
    "timestamp": "2025-10-24T12:34:56.789Z",
    "request_id": "req_1a2b3c4d5e6f",
    "documentation_url": "https://docs.rwa-prime.com/errors/auth-001"
  }
}
```

**Field Definitions**:
- `code` (string): Machine-readable error code (e.g., `ERR_AUTH_001`)
- `message` (string): Short human-readable error message
- `details` (string, optional): Longer explanation with context
- `timestamp` (string): ISO 8601 timestamp when error occurred
- `request_id` (string): Unique request ID for tracking/debugging
- `documentation_url` (string, optional): Link to error documentation

### HTTP Status Code Mapping

| HTTP Status | Category | When to Use |
|-------------|----------|-------------|
| **400** | Bad Request | Client error - invalid input, validation failure |
| **401** | Unauthorized | Missing or invalid authentication |
| **403** | Forbidden | Valid auth but insufficient permissions |
| **404** | Not Found | Resource does not exist |
| **409** | Conflict | Resource conflict (duplicate, state mismatch) |
| **422** | Unprocessable Entity | Valid syntax but semantic errors |
| **429** | Too Many Requests | Rate limit exceeded |
| **500** | Internal Server Error | Unhandled server error |
| **502** | Bad Gateway | External API failure |
| **503** | Service Unavailable | Service overload or maintenance |
| **504** | Gateway Timeout | External API timeout |

---

## Error Code Categories

Error codes follow the pattern: `ERR_{CATEGORY}_{NUMBER}`

| Category | Prefix | Description | HTTP Status |
|----------|--------|-------------|-------------|
| **Authentication** | `AUTH` | Login, token, session errors | 401 |
| **Authorization** | `AUTHZ` | Permission, tier restriction errors | 403 |
| **Asset** | `ASSET` | Asset not found, invalid asset errors | 404, 400 |
| **Prediction** | `PRED` | Prediction generation failures | 500, 503 |
| **Risk** | `RISK` | Risk scoring failures | 500, 503 |
| **Portfolio** | `PORT` | Portfolio management errors | 400, 404 |
| **Alert** | `ALERT` | Alert creation/management errors | 400, 404 |
| **Ingestion** | `INGEST` | Data ingestion failures | 502, 503 |
| **External API** | `EXT` | Third-party API errors | 502, 504 |
| **Database** | `DB` | Database connection/query errors | 500, 503 |
| **Validation** | `VAL` | Input validation errors | 400, 422 |
| **Rate Limit** | `RATE` | API rate limiting | 429 |
| **System** | `SYS` | General system errors | 500, 503 |

---

## Authentication Errors (AUTH)

### ERR_AUTH_001: Invalid or Expired Token
**HTTP Status**: 401
**Message**: "Invalid or expired access token"
**Details**: "The access token has expired or is malformed. Please refresh your token."
**Retry**: No (client must refresh token)
**User Action**: Refresh token using `/auth/refresh` endpoint

```python
# Example
raise HTTPException(
    status_code=401,
    detail={
        "code": "ERR_AUTH_001",
        "message": "Invalid or expired access token",
        "details": "Token expired at 2025-10-24T12:00:00Z",
        "timestamp": datetime.utcnow().isoformat(),
        "request_id": request_id
    }
)
```

### ERR_AUTH_002: Invalid Credentials
**HTTP Status**: 401
**Message**: "Invalid email or password"
**Details**: "The email or password you entered is incorrect."
**Retry**: No (user must provide correct credentials)
**User Action**: Re-enter credentials or reset password

### ERR_AUTH_003: Refresh Token Invalid
**HTTP Status**: 401
**Message**: "Invalid or revoked refresh token"
**Details**: "Your session has been revoked. Please log in again."
**Retry**: No (user must re-authenticate)
**User Action**: Redirect to login

### ERR_AUTH_004: Two-Factor Authentication Required
**HTTP Status**: 401
**Message**: "Two-factor authentication code required"
**Details**: "Please provide your 2FA code to continue."
**Retry**: No (user must provide 2FA code)
**User Action**: Prompt for 2FA code

### ERR_AUTH_005: Invalid 2FA Code
**HTTP Status**: 401
**Message**: "Invalid two-factor authentication code"
**Details**: "The 2FA code you entered is incorrect or expired."
**Retry**: Yes (max 3 attempts)
**User Action**: Re-enter 2FA code

### ERR_AUTH_006: Account Locked
**HTTP Status**: 403
**Message**: "Account temporarily locked"
**Details**: "Your account has been locked due to multiple failed login attempts. Try again in 15 minutes."
**Retry**: Yes (after lockout period)
**User Action**: Wait 15 minutes or contact support

### ERR_AUTH_007: Email Not Verified
**HTTP Status**: 403
**Message**: "Email address not verified"
**Details**: "Please verify your email address to continue."
**Retry**: No (user must verify email)
**User Action**: Resend verification email

---

## Authorization Errors (AUTHZ)

### ERR_AUTHZ_001: Insufficient Permissions
**HTTP Status**: 403
**Message**: "Insufficient permissions"
**Details**: "You do not have permission to perform this action."
**Retry**: No
**User Action**: Contact admin for permissions

### ERR_AUTHZ_002: Tier Restriction
**HTTP Status**: 403
**Message**: "Feature not available in your tier"
**Details**: "This feature requires a Professional or Enterprise tier subscription. You are currently on Explorer tier."
**Retry**: No
**User Action**: Upgrade to Professional/Enterprise tier

**Example**:
```json
{
  "code": "ERR_AUTHZ_002",
  "message": "Feature not available in your tier",
  "details": "30-day predictions require Professional tier. Current tier: Explorer",
  "required_tier": "professional",
  "current_tier": "explorer",
  "upgrade_url": "https://rwa-prime.com/upgrade"
}
```

### ERR_AUTHZ_003: API Access Not Enabled
**HTTP Status**: 403
**Message**: "API access not enabled"
**Details**: "API access requires an Enterprise tier subscription."
**Retry**: No
**User Action**: Upgrade to Enterprise tier

### ERR_AUTHZ_004: Resource Access Denied
**HTTP Status**: 403
**Message**: "You do not have access to this resource"
**Details**: "This portfolio belongs to another user."
**Retry**: No
**User Action**: Access only your own resources

---

## Asset Errors (ASSET)

### ERR_ASSET_001: Asset Not Found
**HTTP Status**: 404
**Message**: "Asset not found"
**Details**: "No asset found with symbol 'XYZ'."
**Retry**: No
**User Action**: Verify asset symbol

```python
# Example
if not asset:
    raise HTTPException(
        status_code=404,
        detail={
            "code": "ERR_ASSET_001",
            "message": "Asset not found",
            "details": f"No asset found with symbol '{symbol}'",
            "provided_symbol": symbol
        }
    )
```

### ERR_ASSET_002: Invalid Asset Symbol
**HTTP Status**: 400
**Message**: "Invalid asset symbol format"
**Details**: "Asset symbols must be 2-10 uppercase alphanumeric characters."
**Retry**: No
**User Action**: Provide valid asset symbol

### ERR_ASSET_003: Asset Not Supported
**HTTP Status**: 404
**Message**: "Asset not yet supported"
**Details**: "This asset is not yet supported by RWA Prime. Request support via feedback."
**Retry**: No
**User Action**: Request asset support

### ERR_ASSET_004: Multiple Assets Found
**HTTP Status**: 400
**Message**: "Multiple assets match query"
**Details**: "Multiple assets found matching 'USD'. Please be more specific."
**Retry**: No
**User Action**: Provide more specific search criteria

---

## Prediction Errors (PRED)

### ERR_PRED_001: Insufficient Historical Data
**HTTP Status**: 422
**Message**: "Insufficient historical data for prediction"
**Details**: "Asset requires at least 90 days of historical data. Current: 45 days."
**Retry**: Yes (check again later as data accumulates)
**User Action**: Check back when more data is available

```json
{
  "code": "ERR_PRED_001",
  "message": "Insufficient historical data for prediction",
  "details": "Predictions require 90 days of data. Asset has only 45 days.",
  "required_days": 90,
  "available_days": 45,
  "retry_after": "2025-11-15T00:00:00Z"
}
```

### ERR_PRED_002: Prediction Model Not Trained
**HTTP Status**: 503
**Message": "Prediction model not yet trained for this asset"
**Details**: "The ML model is still training for this asset. Try again in 2 hours."
**Retry**: Yes (exponential backoff)
**User Action**: Check back later

### ERR_PRED_003: Prediction Generation Failed
**HTTP Status**: 500
**Message**: "Failed to generate prediction"
**Details**: "An error occurred while generating the prediction. Our team has been notified."
**Retry**: Yes (exponential backoff, max 3 attempts)
**User Action**: Try again later or contact support

### ERR_PRED_004: Prediction Horizon Invalid
**HTTP Status**: 400
**Message**: "Invalid prediction horizon"
**Details**: "Prediction horizon must be 7 or 30 days. Provided: 15 days."
**Retry**: No
**User Action**: Use valid horizon (7 or 30)

### ERR_PRED_005: Stale Prediction Data
**HTTP Status**: 503
**Message**: "Prediction data is stale"
**Details**: "The latest prediction is older than 24 hours. Regenerating..."
**Retry**: Yes (after 5 minutes)
**User Action**: Wait for prediction regeneration

---

## Risk Scoring Errors (RISK)

### ERR_RISK_001: Risk Calculation Failed
**HTTP Status**: 500
**Message**: "Failed to calculate risk score"
**Details**: "An error occurred during risk calculation. Our team has been notified."
**Retry**: Yes (exponential backoff)
**User Action**: Try again later

### ERR_RISK_002: Missing Risk Factor Data
**HTTP Status**: 422
**Message**: "Incomplete risk factor data"
**Details**: "Missing data for credit risk calculation (collateralization ratio unavailable)."
**Retry**: Yes (data may become available)
**User Action**: Some risk factors unavailable

```json
{
  "code": "ERR_RISK_002",
  "message": "Incomplete risk factor data",
  "details": "Credit risk unavailable due to missing collateralization data",
  "available_factors": ["market_risk", "technical_risk"],
  "missing_factors": ["credit_risk", "regulatory_risk"],
  "overall_risk": "partial"
}
```

### ERR_RISK_003: Risk Model Not Configured
**HTTP Status**: 503
**Message": "Risk model not configured for this asset class"
**Details**: "Risk scoring for commodities is not yet supported."
**Retry**: No
**User Action**: Risk scoring unavailable for this asset class

---

## Portfolio Errors (PORT)

### ERR_PORT_001: Portfolio Not Found
**HTTP Status**: 404
**Message**: "Portfolio not found"
**Details**: "No portfolio found with ID 'abc123'."
**Retry**: No
**User Action**: Verify portfolio ID

### ERR_PORT_002: Portfolio Limit Reached
**HTTP Status**: 422
**Message**: "Portfolio limit reached"
**Details**: "Your plan allows up to 3 portfolios. Current: 3. Upgrade to create more."
**Retry**: No
**User Action**: Delete a portfolio or upgrade tier

```json
{
  "code": "ERR_PORT_002",
  "message": "Portfolio limit reached",
  "details": "Explorer tier allows 3 portfolios. You have 3.",
  "current_count": 3,
  "max_allowed": 3,
  "upgrade_tier": "professional"
}
```

### ERR_PORT_003: Invalid Wallet Address
**HTTP Status**: 400
**Message**: "Invalid blockchain wallet address"
**Details**: "The provided Ethereum address is invalid: '0x123'."
**Retry**: No
**User Action**: Provide valid wallet address

### ERR_PORT_004: Wallet Sync Failed
**HTTP Status**: 502
**Message**: "Failed to sync wallet"
**Details**: "Unable to connect to blockchain API. Try again in a few minutes."
**Retry**: Yes (exponential backoff)
**User Action**: Try again later

### ERR_PORT_005: Transaction Already Exists
**HTTP Status**: 409
**Message**: "Duplicate transaction"
**Details**: "This transaction has already been recorded."
**Retry**: No
**User Action**: Transaction already exists

### ERR_PORT_006: Invalid Transaction Amount
**HTTP Status**: 400
**Message**: "Invalid transaction amount"
**Details**: "Transaction amount must be greater than 0."
**Retry**: No
**User Action**: Provide valid amount

---

## Alert Errors (ALERT)

### ERR_ALERT_001: Alert Limit Reached
**HTTP Status**: 422
**Message**: "Alert limit reached"
**Details**: "Your plan allows up to 10 alerts. Current: 10. Delete an alert or upgrade."
**Retry**: No
**User Action**: Delete alert or upgrade tier

### ERR_ALERT_002: Invalid Alert Condition
**HTTP Status**: 400
**Message**: "Invalid alert condition"
**Details**: "Price threshold must be a positive number."
**Retry**: No
**User Action**: Provide valid alert condition

### ERR_ALERT_003: Alert Not Found
**HTTP Status**: 404
**Message**: "Alert not found"
**Details**: "No alert found with ID 'alert_123'."
**Retry**: No
**User Action**: Verify alert ID

### ERR_ALERT_004: Duplicate Alert
**HTTP Status**: 409
**Message**: "Duplicate alert"
**Details**: "You already have an alert for this asset with the same condition."
**Retry**: No
**User Action**: Alert already exists

---

## Data Ingestion Errors (INGEST)

### ERR_INGEST_001: External API Unreachable
**HTTP Status**: 502
**Message**: "External data source unreachable"
**Details**: "Unable to connect to CoinAPI. Data may be delayed."
**Retry**: Yes (exponential backoff)
**Logging**: Error level, alert operations team

### ERR_INGEST_002: Malformed Data Received
**HTTP Status**: 502
**Message**: "Invalid data format from external source"
**Details**: "Received malformed JSON from NewsAPI."
**Retry**: Yes (may be transient)
**Logging**: Error level, store raw data for debugging

### ERR_INGEST_003: Data Validation Failed
**HTTP Status**: 500
**Message**: "Data validation failed"
**Details**: "Price data failed validation (negative price detected)."
**Retry**: No (data quality issue)
**Logging**: Error level, alert data team

### ERR_INGEST_004: Rate Limited by External API
**HTTP Status**: 503
**Message**: "External API rate limit exceeded"
**Details**: "CoinAPI rate limit reached. Data ingestion paused until reset."
**Retry**: Yes (after rate limit reset)
**Logging**: Warning level

---

## External API Errors (EXT)

### ERR_EXT_001: External API Timeout
**HTTP Status**: 504
**Message**: "External API timeout"
**Details**: "Request to Amberdata timed out after 30 seconds."
**Retry**: Yes (exponential backoff, max 3 attempts)
**Logging**: Warning level

### ERR_EXT_002: External API Authentication Failed
**HTTP Status**: 502
**Message**: "External API authentication failed"
**Details**: "Invalid API key for CoinAPI. Check configuration."
**Retry**: No (configuration issue)
**Logging**: Error level, alert operations team

### ERR_EXT_003: External API Quota Exceeded
**HTTP Status**: 503
**Message**: "External API quota exceeded"
**Details**: "Monthly quota for Bitquery exceeded. Upgrade plan or wait for reset."
**Retry**: Yes (after quota reset)
**Logging**: Error level, alert finance team

---

## Database Errors (DB)

### ERR_DB_001: Database Connection Failed
**HTTP Status**: 503
**Message**: "Database unavailable"
**Details**: "Unable to connect to database. Please try again."
**Retry**: Yes (exponential backoff)
**Logging**: Error level, alert operations team

### ERR_DB_002: Query Timeout
**HTTP Status**: 504
**Message**: "Database query timeout"
**Details**: "Query took longer than 30 seconds and was terminated."
**Retry**: Yes (may be transient load)
**Logging**: Warning level, review slow query

### ERR_DB_003: Constraint Violation
**HTTP Status**: 409
**Message**: "Database constraint violation"
**Details**: "Unique constraint violated (duplicate email address)."
**Retry**: No (application logic issue)
**Logging**: Warning level

### ERR_DB_004: Deadlock Detected
**HTTP Status**: 500
**Message**: "Database deadlock"
**Details**: "Transaction deadlock detected. Please retry."
**Retry**: Yes (automatic retry, max 3 attempts)
**Logging**: Warning level

---

## Validation Errors (VAL)

### ERR_VAL_001: Missing Required Field
**HTTP Status**: 400
**Message**: "Missing required field"
**Details**: "Field 'email' is required but was not provided."
**Retry**: No
**User Action**: Provide required field

```json
{
  "code": "ERR_VAL_001",
  "message": "Missing required field",
  "details": "The following required fields are missing: email, password",
  "missing_fields": ["email", "password"]
}
```

### ERR_VAL_002: Invalid Field Format
**HTTP Status**: 400
**Message**: "Invalid field format"
**Details**: "Field 'email' must be a valid email address."
**Retry**: No
**User Action**: Provide valid format

### ERR_VAL_003: Field Value Out of Range
**HTTP Status**: 400
**Message**: "Field value out of range"
**Details**: "Field 'quantity' must be between 0.0001 and 1000000."
**Retry**: No
**User Action**: Provide value in valid range

### ERR_VAL_004: Invalid Date Format
**HTTP Status**: 400
**Message**: "Invalid date format"
**Details**: "Date must be in ISO 8601 format (YYYY-MM-DDTHH:MM:SSZ)."
**Retry**: No
**User Action**: Provide valid date format

---

## Rate Limiting Errors (RATE)

### ERR_RATE_001: Rate Limit Exceeded
**HTTP Status**: 429
**Message**: "Rate limit exceeded"
**Details**: "You have exceeded the rate limit of 100 requests per minute. Try again in 60 seconds."
**Retry**: Yes (after rate limit window)
**Response Headers**:
```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 0
X-RateLimit-Reset: 1698163200
Retry-After: 60
```

```json
{
  "code": "ERR_RATE_001",
  "message": "Rate limit exceeded",
  "details": "Explorer tier allows 100 requests/minute. You have made 101.",
  "limit": 100,
  "window": "1 minute",
  "retry_after_seconds": 60,
  "upgrade_tier": "professional"
}
```

### ERR_RATE_002: Concurrent Request Limit
**HTTP Status**: 429
**Message": "Too many concurrent requests"
**Details**: "You have exceeded the concurrent request limit of 5."
**Retry**: Yes (after current requests complete)
**User Action**: Reduce concurrent requests

---

## System Errors (SYS)

### ERR_SYS_001: Internal Server Error
**HTTP Status**: 500
**Message**: "Internal server error"
**Details**: "An unexpected error occurred. Our team has been notified."
**Retry**: Yes (may be transient)
**Logging**: Error level, alert operations team

### ERR_SYS_002: Service Unavailable
**HTTP Status**: 503
**Message**: "Service temporarily unavailable"
**Details**: "The service is undergoing maintenance. Try again in 10 minutes."
**Retry**: Yes (after maintenance window)
**Response Headers**:
```
Retry-After: 600
```

### ERR_SYS_003: Not Implemented
**HTTP Status**: 501
**Message**: "Feature not yet implemented"
**Details**: "PDF export is planned for Phase 3."
**Retry**: No
**User Action**: Feature not available yet

---

## Error Handling Patterns

### 1. Error Handler Decorator (Python)

```python
from functools import wraps
from fastapi import HTTPException, Request
import logging

logger = logging.getLogger(__name__)

def handle_errors(func):
    @wraps(func)
    async def wrapper(*args, **kwargs):
        request: Request = kwargs.get('request') or args[0]
        request_id = request.state.request_id

        try:
            return await func(*args, **kwargs)

        except HTTPException:
            # Re-raise HTTP exceptions (already formatted)
            raise

        except ValueError as e:
            # Validation errors
            logger.warning(f"Validation error: {e}", extra={"request_id": request_id})
            raise HTTPException(
                status_code=400,
                detail={
                    "code": "ERR_VAL_002",
                    "message": "Invalid input",
                    "details": str(e),
                    "request_id": request_id
                }
            )

        except ConnectionError as e:
            # Database/external API connection errors
            logger.error(f"Connection error: {e}", extra={"request_id": request_id})
            raise HTTPException(
                status_code=503,
                detail={
                    "code": "ERR_SYS_002",
                    "message": "Service temporarily unavailable",
                    "details": "Unable to connect to required service",
                    "request_id": request_id
                }
            )

        except Exception as e:
            # Unexpected errors
            logger.exception(f"Unexpected error: {e}", extra={"request_id": request_id})
            raise HTTPException(
                status_code=500,
                detail={
                    "code": "ERR_SYS_001",
                    "message": "Internal server error",
                    "details": "An unexpected error occurred",
                    "request_id": request_id
                }
            )

    return wrapper
```

**Usage**:
```python
@router.get("/assets/{symbol}")
@handle_errors
async def get_asset(symbol: str, request: Request):
    asset = await asset_service.get_by_symbol(symbol)
    if not asset:
        raise HTTPException(
            status_code=404,
            detail={
                "code": "ERR_ASSET_001",
                "message": "Asset not found",
                "details": f"No asset found with symbol '{symbol}'",
                "request_id": request.state.request_id
            }
        )
    return asset
```

### 2. Custom Exception Classes

```python
class RWAPrimeException(Exception):
    """Base exception for RWA Prime"""
    def __init__(self, code: str, message: str, details: str = None, status_code: int = 500):
        self.code = code
        self.message = message
        self.details = details
        self.status_code = status_code
        super().__init__(message)

class AssetNotFoundException(RWAPrimeException):
    def __init__(self, symbol: str):
        super().__init__(
            code="ERR_ASSET_001",
            message="Asset not found",
            details=f"No asset found with symbol '{symbol}'",
            status_code=404
        )

class InsufficientDataException(RWAPrimeException):
    def __init__(self, required_days: int, available_days: int):
        super().__init__(
            code="ERR_PRED_001",
            message="Insufficient historical data for prediction",
            details=f"Requires {required_days} days, available: {available_days}",
            status_code=422
        )

class TierRestrictionException(RWAPrimeException):
    def __init__(self, feature: str, required_tier: str, current_tier: str):
        super().__init__(
            code="ERR_AUTHZ_002",
            message="Feature not available in your tier",
            details=f"{feature} requires {required_tier} tier. Current: {current_tier}",
            status_code=403
        )
```

### 3. Global Exception Handler (FastAPI)

```python
from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
import traceback

app = FastAPI()

@app.exception_handler(RWAPrimeException)
async def rwa_exception_handler(request: Request, exc: RWAPrimeException):
    return JSONResponse(
        status_code=exc.status_code,
        content={
            "error": {
                "code": exc.code,
                "message": exc.message,
                "details": exc.details,
                "timestamp": datetime.utcnow().isoformat(),
                "request_id": request.state.request_id
            }
        }
    )

@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    # Log full traceback
    logger.exception(
        f"Unhandled exception: {exc}",
        extra={
            "request_id": request.state.request_id,
            "path": request.url.path,
            "traceback": traceback.format_exc()
        }
    )

    return JSONResponse(
        status_code=500,
        content={
            "error": {
                "code": "ERR_SYS_001",
                "message": "Internal server error",
                "details": "An unexpected error occurred",
                "timestamp": datetime.utcnow().isoformat(),
                "request_id": request.state.request_id
            }
        }
    )
```

---

## Retry Strategies

### Exponential Backoff

```python
import asyncio
from typing import TypeVar, Callable, Optional
import random

T = TypeVar('T')

async def retry_with_backoff(
    func: Callable[[], T],
    max_attempts: int = 3,
    initial_delay: float = 1.0,
    max_delay: float = 60.0,
    exponential_base: float = 2.0,
    jitter: bool = True,
    retryable_exceptions: tuple = (ConnectionError, TimeoutError)
) -> T:
    """
    Retry function with exponential backoff.

    Args:
        func: Async function to retry
        max_attempts: Maximum number of attempts
        initial_delay: Initial delay in seconds
        max_delay: Maximum delay in seconds
        exponential_base: Base for exponential backoff (2 = double each time)
        jitter: Add random jitter to prevent thundering herd
        retryable_exceptions: Tuple of exceptions to retry
    """
    for attempt in range(max_attempts):
        try:
            return await func()
        except retryable_exceptions as e:
            if attempt == max_attempts - 1:
                # Last attempt, raise exception
                raise

            # Calculate delay with exponential backoff
            delay = min(initial_delay * (exponential_base ** attempt), max_delay)

            # Add jitter (random 0-100% of delay)
            if jitter:
                delay = delay * (0.5 + random.random() * 0.5)

            logger.warning(
                f"Attempt {attempt + 1}/{max_attempts} failed: {e}. "
                f"Retrying in {delay:.2f} seconds..."
            )

            await asyncio.sleep(delay)
```

**Usage**:
```python
# Retry external API call with exponential backoff
prediction = await retry_with_backoff(
    lambda: ml_service.generate_prediction(asset_id),
    max_attempts=3,
    initial_delay=1.0,
    retryable_exceptions=(ConnectionError, TimeoutError, ExternalAPIException)
)
```

### Retry Decision Matrix

| Error Type | Retry? | Strategy | Max Attempts |
|------------|--------|----------|--------------|
| **External API Timeout** | ✅ Yes | Exponential backoff | 3 |
| **External API 5xx** | ✅ Yes | Exponential backoff | 3 |
| **External API Rate Limit (429)** | ✅ Yes | Wait until Retry-After | 1 |
| **Database Deadlock** | ✅ Yes | Immediate retry | 3 |
| **Database Timeout** | ✅ Yes | Exponential backoff | 2 |
| **Database Connection** | ✅ Yes | Exponential backoff | 3 |
| **Validation Error (4xx)** | ❌ No | N/A | 0 |
| **Authentication Error (401)** | ❌ No | N/A | 0 |
| **Not Found (404)** | ❌ No | N/A | 0 |
| **Insufficient Data** | ⚠️ Maybe | Check again later | 1 (after delay) |

---

## Logging Standards

### Log Levels

```python
import logging

# ERROR: System errors, external API failures, unhandled exceptions
logger.error("Database connection failed", extra={
    "error_code": "ERR_DB_001",
    "request_id": request_id,
    "database": "timescaledb"
})

# WARNING: Degraded performance, rate limits, retryable errors
logger.warning("External API rate limit reached", extra={
    "error_code": "ERR_EXT_003",
    "api": "CoinAPI",
    "reset_time": reset_time
})

# INFO: Business events, successful operations
logger.info("Prediction generated successfully", extra={
    "asset_id": asset_id,
    "horizon": "7d",
    "duration_ms": duration
})

# DEBUG: Detailed debugging information
logger.debug("Cache miss for prediction", extra={
    "asset_id": asset_id,
    "cache_key": cache_key
})
```

### Structured Logging Format

```json
{
  "timestamp": "2025-10-24T12:34:56.789Z",
  "level": "ERROR",
  "message": "Database connection failed",
  "error_code": "ERR_DB_001",
  "request_id": "req_1a2b3c4d",
  "user_id": "user_123",
  "trace_id": "trace_abc",
  "span_id": "span_xyz",
  "service": "api-service",
  "environment": "production",
  "version": "1.2.3",
  "extra": {
    "database": "timescaledb",
    "connection_pool_size": 10,
    "retry_attempt": 2
  }
}
```

---

## Client Error Handling

### React/TypeScript Example

```typescript
// API client with error handling
import axios, { AxiosError } from 'axios';

interface ErrorResponse {
  error: {
    code: string;
    message: string;
    details?: string;
    timestamp: string;
    request_id: string;
  };
}

class APIError extends Error {
  code: string;
  details?: string;
  statusCode: number;
  requestId: string;

  constructor(response: ErrorResponse, statusCode: number) {
    super(response.error.message);
    this.code = response.error.code;
    this.details = response.error.details;
    this.statusCode = statusCode;
    this.requestId = response.error.request_id;
  }
}

// Axios interceptor for error handling
axios.interceptors.response.use(
  (response) => response,
  async (error: AxiosError<ErrorResponse>) => {
    if (error.response) {
      const apiError = new APIError(
        error.response.data,
        error.response.status
      );

      // Handle specific error codes
      switch (apiError.code) {
        case 'ERR_AUTH_001':
          // Token expired, try refresh
          try {
            await refreshToken();
            return axios.request(error.config!); // Retry original request
          } catch {
            // Refresh failed, redirect to login
            window.location.href = '/login';
          }
          break;

        case 'ERR_AUTHZ_002':
          // Tier restriction, show upgrade modal
          showUpgradeModal(apiError.details);
          break;

        case 'ERR_RATE_001':
          // Rate limited, show toast
          const retryAfter = error.response.headers['retry-after'];
          showToast(`Rate limited. Try again in ${retryAfter} seconds.`);
          break;

        default:
          // Generic error handling
          showToast(apiError.message);
      }

      throw apiError;
    }

    // Network error (no response)
    throw new Error('Network error. Please check your connection.');
  }
);

// Usage in React component
const AssetDetails: React.FC = () => {
  const [asset, setAsset] = useState<Asset | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const fetchAsset = async () => {
      try {
        const response = await axios.get('/api/assets/USDC');
        setAsset(response.data);
      } catch (err) {
        if (err instanceof APIError) {
          // Handle specific error codes
          if (err.code === 'ERR_ASSET_001') {
            setError('Asset not found');
          } else if (err.code === 'ERR_AUTHZ_002') {
            setError('Upgrade to view this asset');
          } else {
            setError(err.message);
          }
        } else {
          setError('An unexpected error occurred');
        }
      }
    };

    fetchAsset();
  }, []);

  if (error) return <ErrorMessage message={error} />;
  if (!asset) return <Loader />;
  return <AssetDetailsView asset={asset} />;
};
```

---

**Last Updated**: October 24, 2025
**Version**: 1.0
**Total Error Codes**: 50+

---

**Remember**: Consistent error handling improves debugging, user experience, and system reliability. Always use standardized error codes! 🚨
