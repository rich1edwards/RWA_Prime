# Security Guidelines

## Purpose

This document provides comprehensive security guidelines, threat model, secure coding practices, and security checklist for the RWA Prime platform. Security is critical for protecting user funds, personal data, and platform integrity.

---

## Table of Contents

- [Security Principles](#security-principles)
- [Threat Model](#threat-model)
- [Authentication and Authorization](#authentication-and-authorization)
- [Input Validation and Sanitization](#input-validation-and-sanitization)
- [SQL Injection Prevention](#sql-injection-prevention)
- [XSS Prevention](#xss-prevention)
- [CSRF Prevention](#csrf-prevention)
- [API Security](#api-security)
- [Secrets Management](#secrets-management)
- [Cryptography](#cryptography)
- [Rate Limiting](#rate-limiting)
- [Session Management](#session-management)
- [Error Handling and Logging](#error-handling-and-logging)
- [Dependency Management](#dependency-management)
- [Infrastructure Security](#infrastructure-security)
- [OWASP Top 10 Mitigations](#owasp-top-10-mitigations)
- [Security Checklist](#security-checklist)
- [Incident Response](#incident-response)

---

## Security Principles

### Defense in Depth

**Principle**: Multiple layers of security controls to protect against failures.

**Application**:
1. **Network Layer**: VPC isolation, security groups, NACLs
2. **Application Layer**: Authentication, authorization, input validation
3. **Data Layer**: Encryption at rest, encryption in transit
4. **Monitoring**: Intrusion detection, anomaly detection, audit logging

### Principle of Least Privilege

**Principle**: Grant minimum permissions required for a role.

**Application**:
- Database users have specific permissions (read-only, read-write)
- API keys are scoped to specific services
- IAM roles follow least privilege (no wildcard permissions)
- Service accounts cannot escalate privileges

### Fail Securely

**Principle**: Default to secure state when errors occur.

**Application**:
- Authentication failures deny access (don't leak information)
- Authorization checks default to deny
- Database transaction failures rollback (don't commit partial data)
- Error messages don't expose sensitive information

### Security by Design

**Principle**: Security is built in, not bolted on.

**Application**:
- Security requirements in every user story
- Threat modeling during design phase
- Security testing in CI/CD pipeline
- Security code reviews required

---

## Threat Model

### Assets to Protect

| Asset | Sensitivity | Impact if Compromised |
|-------|-------------|----------------------|
| **User Credentials** | Critical | Account takeover, data theft |
| **Portfolio Data** | High | Privacy violation, financial loss |
| **API Keys (External)** | Critical | Service disruption, cost overruns |
| **ML Models** | Medium | IP theft, prediction manipulation |
| **Database** | Critical | Complete platform compromise |
| **JWT Secrets** | Critical | Authentication bypass |
| **User PII** | High | Privacy violation, regulatory penalties |

### Threat Actors

| Actor | Motivation | Capabilities | Likely Attacks |
|-------|------------|--------------|----------------|
| **Script Kiddies** | Curiosity, fame | Low | Automated scans, known exploits |
| **Hacktivists** | Ideology | Medium | DDoS, defacement, data leaks |
| **Competitors** | Market advantage | High | API scraping, model theft |
| **Organized Crime** | Financial gain | Very High | Account takeover, fraud, ransomware |
| **Nation States** | Espionage | Very High | APT, zero-days, supply chain attacks |

### Attack Vectors

1. **Web Application**: SQL injection, XSS, CSRF, authentication bypass
2. **API**: API abuse, credential stuffing, rate limit bypass
3. **Infrastructure**: Misconfigured S3, exposed databases, vulnerable dependencies
4. **Social Engineering**: Phishing, impersonation, insider threats
5. **Supply Chain**: Compromised dependencies, malicious packages

---

## Authentication and Authorization

### Authentication Requirements

**Password Policy**:
```python
# Minimum requirements
MIN_PASSWORD_LENGTH = 12
REQUIRE_UPPERCASE = True
REQUIRE_LOWERCASE = True
REQUIRE_DIGIT = True
REQUIRE_SPECIAL_CHAR = True

# Password validation
import re

def validate_password(password: str) -> bool:
    if len(password) < MIN_PASSWORD_LENGTH:
        return False
    if not re.search(r'[A-Z]', password):
        return False
    if not re.search(r'[a-z]', password):
        return False
    if not re.search(r'\d', password):
        return False
    if not re.search(r'[!@#$%^&*(),.?":{}|<>]', password):
        return False
    return True
```

**Password Hashing**:
```python
from passlib.context import CryptContext

# Use bcrypt with 12 rounds (balance security and performance)
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def hash_password(password: str) -> str:
    return pwd_context.hash(password)

def verify_password(plain_password: str, hashed_password: str) -> bool:
    return pwd_context.verify(plain_password, hashed_password)
```

**⚠️ Never**:
- Store passwords in plain text
- Use weak hashing algorithms (MD5, SHA1)
- Use same salt for all passwords (bcrypt handles this)
- Log passwords (even hashed)

### Two-Factor Authentication (2FA)

**Requirement**: Mandatory for Enterprise tier, optional for Explorer/Professional.

**Implementation** (TOTP):
```python
import pyotp

def generate_2fa_secret() -> str:
    """Generate TOTP secret for user"""
    return pyotp.random_base32()

def generate_qr_code_url(email: str, secret: str) -> str:
    """Generate QR code URL for authenticator apps"""
    return pyotp.totp.TOTP(secret).provisioning_uri(
        name=email,
        issuer_name="RWA Prime"
    )

def verify_2fa_code(secret: str, code: str) -> bool:
    """Verify 6-digit TOTP code"""
    totp = pyotp.TOTP(secret)
    return totp.verify(code, valid_window=1)  # Allow 30-second window
```

**⚠️ Security Considerations**:
- Store 2FA secret encrypted in database
- Provide backup codes (one-time use, hashed)
- Rate limit 2FA verification attempts (5 per 15 minutes)
- Require 2FA re-verification for sensitive operations (password change, add payment method)

### JWT Token Security

**Access Token Configuration**:
```python
# Short-lived access tokens
ACCESS_TOKEN_EXPIRE_MINUTES = 15

# Asymmetric signing (RS256)
ALGORITHM = "RS256"

# Token payload
{
    "sub": "user_id",              # Subject (user ID)
    "email": "user@example.com",   # User email
    "tier": "professional",         # SaaS tier
    "permissions": ["read:assets", "write:portfolio"],
    "iat": 1698163200,             # Issued at
    "exp": 1698164100,             # Expiry (15 minutes)
    "jti": "unique_token_id"       # JWT ID (for revocation)
}
```

**Refresh Token Configuration**:
```python
# Long-lived refresh tokens (stored in Redis)
REFRESH_TOKEN_EXPIRE_DAYS = 7

# Store in Redis with user_id as key
redis_client.setex(
    f"refresh_token:{user_id}:{jti}",
    timedelta(days=7),
    refresh_token_hash  # SHA-256 hash
)
```

**Token Validation**:
```python
from jose import jwt, JWTError

def validate_access_token(token: str) -> dict:
    try:
        # Verify signature and expiry
        payload = jwt.decode(
            token,
            PUBLIC_KEY,
            algorithms=[ALGORITHM],
            options={"verify_aud": False}
        )

        # Check if token is in revocation list (Redis)
        jti = payload.get("jti")
        if redis_client.exists(f"revoked_token:{jti}"):
            raise HTTPException(status_code=401, detail="Token has been revoked")

        return payload

    except JWTError:
        raise HTTPException(status_code=401, detail="Invalid token")
```

**⚠️ Security Considerations**:
- Use asymmetric keys (RS256) not symmetric (HS256) for microservices
- Never store access tokens in localStorage (use HttpOnly cookies for web)
- Implement token rotation (new refresh token on each refresh)
- Revoke all tokens on password change
- Rotate signing keys every 90 days

### Authorization Patterns

**Role-Based Access Control (RBAC)**:
```python
from enum import Enum
from fastapi import Depends, HTTPException

class Permission(str, Enum):
    READ_ASSETS = "read:assets"
    WRITE_PORTFOLIO = "write:portfolio"
    ACCESS_API = "access:api"
    ADMIN = "admin"

# Tier-based permissions
TIER_PERMISSIONS = {
    "explorer": [Permission.READ_ASSETS, Permission.WRITE_PORTFOLIO],
    "professional": [Permission.READ_ASSETS, Permission.WRITE_PORTFOLIO],
    "enterprise": [
        Permission.READ_ASSETS,
        Permission.WRITE_PORTFOLIO,
        Permission.ACCESS_API
    ]
}

def require_permission(required_permission: Permission):
    async def permission_checker(current_user: dict = Depends(get_current_user)):
        user_permissions = TIER_PERMISSIONS.get(current_user["tier"], [])

        if required_permission not in user_permissions:
            raise HTTPException(
                status_code=403,
                detail={
                    "code": "ERR_AUTHZ_002",
                    "message": "Insufficient permissions",
                    "required_permission": required_permission,
                    "current_tier": current_user["tier"]
                }
            )
        return current_user

    return permission_checker

# Usage
@router.get("/api/v1/predictions")
async def get_predictions(
    user: dict = Depends(require_permission(Permission.ACCESS_API))
):
    # Only Enterprise tier can access this endpoint
    pass
```

**Resource-Level Authorization**:
```python
async def verify_portfolio_ownership(portfolio_id: UUID, user_id: UUID) -> bool:
    """Ensure user owns the portfolio they're accessing"""
    portfolio = await db.query(Portfolio).filter(
        Portfolio.id == portfolio_id,
        Portfolio.user_id == user_id
    ).first()

    if not portfolio:
        raise HTTPException(
            status_code=403,
            detail={
                "code": "ERR_AUTHZ_004",
                "message": "You do not have access to this resource"
            }
        )

    return True
```

---

## Input Validation and Sanitization

### Pydantic Models for Validation

```python
from pydantic import BaseModel, EmailStr, constr, conint, validator
from typing import Optional
from decimal import Decimal

class UserRegistration(BaseModel):
    email: EmailStr  # Validates email format
    password: constr(min_length=12, max_length=128)  # Length constraint
    full_name: constr(min_length=1, max_length=255, strip_whitespace=True)

    @validator('password')
    def validate_password_strength(cls, v):
        if not validate_password(v):  # Custom validation
            raise ValueError('Password does not meet requirements')
        return v

    @validator('full_name')
    def sanitize_name(cls, v):
        # Remove potential XSS vectors
        import bleach
        return bleach.clean(v, tags=[], strip=True)

class TransactionCreate(BaseModel):
    asset_id: UUID
    transaction_type: Literal["buy", "sell", "transfer_in", "transfer_out"]
    quantity: Decimal
    price_per_token_usd: Decimal
    transaction_date: datetime

    @validator('quantity', 'price_per_token_usd')
    def validate_positive(cls, v):
        if v <= 0:
            raise ValueError('Value must be positive')
        return v

    @validator('transaction_date')
    def validate_date_not_future(cls, v):
        if v > datetime.utcnow():
            raise ValueError('Transaction date cannot be in the future')
        return v
```

**⚠️ Always Validate**:
- Email addresses (format and existence)
- UUIDs (valid format)
- Dates (not in future, within reasonable range)
- Numeric values (positive, within range)
- String lengths (prevent DoS via large inputs)
- Enum values (must be in allowed set)

### Sanitization for Output

**HTML Content** (user-generated descriptions, notes):
```python
import bleach

ALLOWED_TAGS = ['b', 'i', 'u', 'a', 'p', 'br', 'strong', 'em']
ALLOWED_ATTRIBUTES = {'a': ['href', 'title']}

def sanitize_html(content: str) -> str:
    """Remove potentially malicious HTML tags"""
    return bleach.clean(
        content,
        tags=ALLOWED_TAGS,
        attributes=ALLOWED_ATTRIBUTES,
        strip=True
    )
```

**SQL Parameters** (always use parameterized queries):
```python
# ✅ GOOD: Parameterized query
symbol = request.args.get('symbol')
query = "SELECT * FROM assets WHERE symbol = %s"
result = db.execute(query, (symbol,))

# ❌ BAD: String concatenation (SQL injection risk)
query = f"SELECT * FROM assets WHERE symbol = '{symbol}'"
result = db.execute(query)
```

---

## SQL Injection Prevention

### Always Use ORM or Parameterized Queries

**SQLAlchemy (ORM)**:
```python
from sqlalchemy import select

# ✅ SAFE: ORM automatically parameterizes
symbol = request.args.get('symbol')
stmt = select(Asset).where(Asset.symbol == symbol)
result = await db.execute(stmt)

# ✅ SAFE: Parameterized raw query
query = text("SELECT * FROM assets WHERE symbol = :symbol")
result = await db.execute(query, {"symbol": symbol})

# ❌ UNSAFE: String formatting
query = text(f"SELECT * FROM assets WHERE symbol = '{symbol}'")  # DON'T DO THIS
```

**Dynamic Queries** (use whitelisting):
```python
# When sorting by user-provided column
ALLOWED_SORT_COLUMNS = {'name', 'created_at', 'price', 'market_cap'}

def get_assets(sort_by: str = 'name'):
    # Whitelist validation
    if sort_by not in ALLOWED_SORT_COLUMNS:
        raise ValueError(f"Invalid sort column: {sort_by}")

    # Safe to use in query
    query = text(f"SELECT * FROM assets ORDER BY {sort_by}")
    return db.execute(query)
```

---

## XSS Prevention

### Content Security Policy (CSP)

**HTTP Header**:
```python
from fastapi.middleware.trustedhost import TrustedHostMiddleware
from fastapi.middleware.cors import CORSMiddleware

@app.middleware("http")
async def add_security_headers(request: Request, call_next):
    response = await call_next(request)

    # Content Security Policy
    response.headers["Content-Security-Policy"] = (
        "default-src 'self'; "
        "script-src 'self' 'unsafe-inline' https://cdn.jsdelivr.net; "
        "style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; "
        "img-src 'self' data: https:; "
        "font-src 'self' https://fonts.gstatic.com; "
        "connect-src 'self' https://api.rwa-prime.com wss://api.rwa-prime.com; "
        "frame-ancestors 'none';"
    )

    # Other security headers
    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["X-Frame-Options"] = "DENY"
    response.headers["X-XSS-Protection"] = "1; mode=block"
    response.headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains"

    return response
```

### React XSS Prevention

**Escape User Content**:
```typescript
import DOMPurify from 'dompurify';

// Sanitize HTML before rendering
const sanitizeHTML = (html: string): string => {
  return DOMPurify.sanitize(html, {
    ALLOWED_TAGS: ['b', 'i', 'u', 'a', 'p', 'br'],
    ALLOWED_ATTR: ['href', 'title']
  });
};

// Usage in React
const AssetDescription: React.FC<{ description: string }> = ({ description }) => {
  return (
    <div
      dangerouslySetInnerHTML={{ __html: sanitizeHTML(description) }}
    />
  );
};
```

**⚠️ Never**:
- Use `dangerouslySetInnerHTML` without sanitization
- Trust user input in `eval()`, `setTimeout(code)`, `Function(code)`
- Insert user input directly into DOM (use textContent, not innerHTML)

---

## CSRF Prevention

### CSRF Token Implementation

**Backend (FastAPI)**:
```python
from fastapi_csrf_protect import CsrfProtect
from pydantic import BaseModel

class CsrfSettings(BaseModel):
    secret_key: str = os.getenv("CSRF_SECRET_KEY")
    cookie_samesite: str = "strict"
    cookie_secure: bool = True  # Require HTTPS
    cookie_httponly: bool = True

@CsrfProtect.load_config
def get_csrf_config():
    return CsrfSettings()

# Generate and set CSRF token
@app.post("/auth/login")
async def login(response: Response, csrf_protect: CsrfProtect = Depends()):
    # Generate CSRF token
    csrf_token = csrf_protect.generate_csrf()

    # Set CSRF cookie
    response.set_cookie(
        key="csrf_token",
        value=csrf_token,
        httponly=True,
        secure=True,
        samesite="strict"
    )

    return {"access_token": "..."}

# Validate CSRF token on state-changing operations
@app.post("/portfolio/transaction")
async def create_transaction(
    request: Request,
    csrf_protect: CsrfProtect = Depends()
):
    # Validate CSRF token from header
    await csrf_protect.validate_csrf(request)

    # Process transaction
    pass
```

**Frontend (React)**:
```typescript
// Include CSRF token in requests
const createTransaction = async (data: TransactionData) => {
  const csrfToken = getCookie('csrf_token');

  const response = await axios.post('/api/portfolio/transaction', data, {
    headers: {
      'X-CSRF-Token': csrfToken
    }
  });

  return response.data;
};
```

### SameSite Cookie Attribute

```python
# Set cookies with SameSite=Strict or Lax
response.set_cookie(
    key="session",
    value=session_id,
    httponly=True,
    secure=True,
    samesite="strict"  # Prevents CSRF attacks
)
```

---

## API Security

### API Key Management

**API Key Generation**:
```python
import secrets

def generate_api_key() -> str:
    """Generate cryptographically secure API key"""
    return f"rwa_{''.join(secrets.token_urlsafe(32))}"

# Example: rwa_k7L9mN3pQ5rT8vX0yZ2aB4cD6eF1gH3
```

**API Key Storage**:
```python
# Store hash of API key, not plaintext
import hashlib

def hash_api_key(api_key: str) -> str:
    return hashlib.sha256(api_key.encode()).hexdigest()

# On API key creation
api_key = generate_api_key()
api_key_hash = hash_api_key(api_key)
db.execute(
    "INSERT INTO api_keys (user_id, key_hash, created_at) VALUES (%s, %s, %s)",
    (user_id, api_key_hash, datetime.utcnow())
)

# Show key to user ONCE (they must save it)
return {"api_key": api_key}  # Never show again

# On API request
provided_key_hash = hash_api_key(request.headers.get("X-API-Key"))
api_key_record = db.query(APIKey).filter(APIKey.key_hash == provided_key_hash).first()
```

**API Key Rotation**:
- Expire API keys after 1 year
- Allow users to generate new keys and deprecate old ones
- Support multiple active keys per user (for zero-downtime rotation)

### Rate Limiting

**Implementation with Redis**:
```python
from fastapi import HTTPException
import redis

redis_client = redis.Redis(host='localhost', port=6379, db=0)

async def rate_limit(
    user_id: str,
    limit: int = 100,
    window_seconds: int = 60
):
    """
    Rate limit using sliding window algorithm.

    Args:
        user_id: User identifier
        limit: Max requests allowed in window
        window_seconds: Time window in seconds
    """
    key = f"rate_limit:{user_id}"
    current_time = int(time.time())
    window_start = current_time - window_seconds

    # Remove old requests outside window
    redis_client.zremrangebyscore(key, 0, window_start)

    # Count requests in current window
    request_count = redis_client.zcard(key)

    if request_count >= limit:
        # Rate limited
        raise HTTPException(
            status_code=429,
            detail={
                "code": "ERR_RATE_001",
                "message": "Rate limit exceeded",
                "limit": limit,
                "window": f"{window_seconds} seconds",
                "retry_after": window_seconds
            },
            headers={"Retry-After": str(window_seconds)}
        )

    # Add current request
    redis_client.zadd(key, {str(current_time): current_time})
    redis_client.expire(key, window_seconds)

    return True
```

**Tiered Rate Limits**:
```python
RATE_LIMITS = {
    "explorer": {"requests": 100, "window": 60},       # 100 req/min
    "professional": {"requests": 500, "window": 60},   # 500 req/min
    "enterprise": {"requests": 10000, "window": 60}    # 10K req/min
}

@app.middleware("http")
async def rate_limit_middleware(request: Request, call_next):
    user = get_current_user(request)
    tier = user.get("tier", "explorer")

    limits = RATE_LIMITS[tier]
    await rate_limit(user["id"], limits["requests"], limits["window"])

    response = await call_next(request)

    # Add rate limit headers
    response.headers["X-RateLimit-Limit"] = str(limits["requests"])
    response.headers["X-RateLimit-Remaining"] = str(remaining)

    return response
```

---

## Secrets Management

### Environment Variables

**⚠️ Never Commit Secrets to Git**:
```bash
# .env file (never commit)
DATABASE_URL=postgresql://user:password@localhost/rwa_prime
JWT_PRIVATE_KEY_PATH=/secrets/jwt_private_key.pem
JWT_PUBLIC_KEY_PATH=/secrets/jwt_public_key.pem
COINAPI_KEY=your_coinapi_key_here
REDIS_URL=redis://localhost:6379
ENCRYPTION_KEY=your_32_byte_encryption_key
```

**Load Secrets from AWS Secrets Manager** (Production):
```python
import boto3
import json

def get_secret(secret_name: str) -> dict:
    """Retrieve secret from AWS Secrets Manager"""
    client = boto3.client('secretsmanager', region_name='us-east-1')

    try:
        response = client.get_secret_value(SecretId=secret_name)
        return json.loads(response['SecretString'])
    except Exception as e:
        logger.error(f"Failed to retrieve secret: {e}")
        raise

# Usage
db_credentials = get_secret("rwa-prime/database")
DATABASE_URL = db_credentials["url"]
```

### Encryption at Rest

**Encrypt Sensitive Fields**:
```python
from cryptography.fernet import Fernet

# Generate encryption key (store in AWS Secrets Manager)
encryption_key = Fernet.generate_key()

cipher = Fernet(encryption_key)

def encrypt_field(plaintext: str) -> str:
    """Encrypt sensitive field"""
    return cipher.encrypt(plaintext.encode()).decode()

def decrypt_field(ciphertext: str) -> str:
    """Decrypt sensitive field"""
    return cipher.decrypt(ciphertext.encode()).decode()

# Usage: Encrypt 2FA secret before storing
user.two_factor_secret = encrypt_field(totp_secret)
db.add(user)
db.commit()

# Decrypt when needed
totp_secret = decrypt_field(user.two_factor_secret)
```

**Fields to Encrypt**:
- 2FA secrets
- API keys (hash is better, but if storing for third-party APIs, encrypt)
- Wallet private keys (if ever stored - discouraged)
- Backup codes

---

## Cryptography

### Use Strong Algorithms

**✅ Recommended**:
- **Hashing**: bcrypt (passwords), SHA-256 (API keys, tokens)
- **Symmetric Encryption**: AES-256-GCM (Fernet uses AES-128-CBC with HMAC)
- **Asymmetric Encryption**: RSA-2048+ (JWT signing), Ed25519 (digital signatures)
- **Key Derivation**: PBKDF2, bcrypt, Argon2

**❌ Never Use**:
- MD5, SHA1 (broken)
- DES, 3DES (weak)
- RSA-1024 (too weak)
- ECB mode (insecure)
- Custom encryption algorithms

### Secure Random Number Generation

```python
import secrets

# ✅ GOOD: Cryptographically secure
random_token = secrets.token_urlsafe(32)
random_hex = secrets.token_hex(16)

# ❌ BAD: Not cryptographically secure
import random
random_token = random.randint(1000, 9999)  # DON'T USE FOR SECURITY
```

---

## Rate Limiting

See [API Security](#api-security) section for implementation.

**Where to Apply**:
- Login endpoint (5 attempts per 15 minutes per IP)
- Password reset (3 requests per hour per email)
- 2FA verification (5 attempts per 15 minutes per user)
- API endpoints (tiered limits)
- WebSocket connections (10 concurrent per user)

---

## Session Management

### Session Configuration

```python
from fastapi import FastAPI, Request
from starlette.middleware.sessions import SessionMiddleware

app = FastAPI()

# Session middleware
app.add_middleware(
    SessionMiddleware,
    secret_key=os.getenv("SESSION_SECRET_KEY"),
    session_cookie="session",
    max_age=3600,  # 1 hour
    same_site="strict",
    https_only=True
)
```

### Session Invalidation

**On Security Events**:
- Password change → Revoke all sessions
- 2FA enabled/disabled → Revoke all sessions
- Suspicious activity → Revoke all sessions
- User logout → Revoke specific session

```python
async def revoke_all_user_sessions(user_id: UUID):
    """Revoke all active sessions for a user"""
    # Delete all refresh tokens from Redis
    pattern = f"refresh_token:{user_id}:*"
    for key in redis_client.scan_iter(match=pattern):
        redis_client.delete(key)

    # Invalidate all JWTs (add to revocation list)
    active_tokens = await db.query(UserSession).filter(
        UserSession.user_id == user_id,
        UserSession.is_revoked == False
    ).all()

    for session in active_tokens:
        # Add JWT ID to revocation list (expires with token)
        redis_client.setex(
            f"revoked_token:{session.jti}",
            timedelta(minutes=15),  # Access token TTL
            "1"
        )

        # Mark session as revoked
        session.is_revoked = True

    await db.commit()
```

---

## Error Handling and Logging

### Secure Error Messages

**❌ Bad (Exposes Information)**:
```python
# Don't do this
raise HTTPException(status_code=500, detail=str(exception))
# Error: "Database connection failed: password authentication failed for user 'admin'"
```

**✅ Good (Generic Message, Log Details)**:
```python
# Do this
logger.error(f"Database connection failed: {exception}", extra={
    "user_id": user_id,
    "request_id": request_id
})

raise HTTPException(
    status_code=500,
    detail={
        "code": "ERR_DB_001",
        "message": "Database unavailable",
        "request_id": request_id
    }
)
```

### Logging Security Events

```python
# Log authentication failures
logger.warning("Failed login attempt", extra={
    "email": email,
    "ip_address": request.client.host,
    "user_agent": request.headers.get("user-agent"),
    "timestamp": datetime.utcnow()
})

# Log authorization failures
logger.warning("Unauthorized access attempt", extra={
    "user_id": user_id,
    "resource": resource_id,
    "required_permission": permission,
    "user_tier": user_tier
})

# Log sensitive operations
logger.info("Password changed", extra={
    "user_id": user_id,
    "ip_address": request.client.host
})
```

**⚠️ Never Log**:
- Passwords (plain or hashed)
- API keys
- JWT tokens
- Credit card numbers
- Social Security Numbers
- Private keys

---

## Dependency Management

### Regularly Update Dependencies

```bash
# Check for vulnerabilities
pip install safety
safety check

# Update dependencies
pip list --outdated
pip install --upgrade <package>
```

**Automated Scanning**:
- **Dependabot** (GitHub): Automated PR for dependency updates
- **Snyk**: Vulnerability scanning
- **OWASP Dependency-Check**: CVE scanning

### Pin Dependency Versions

```
# requirements.txt
fastapi==0.104.1  # Pinned version
pydantic==2.4.2
sqlalchemy==2.0.23

# requirements-dev.txt
pytest==7.4.3
black==23.11.0
```

### Review Third-Party Packages

**Before Adding a Dependency**:
1. ✅ Check GitHub stars and activity
2. ✅ Review security advisories
3. ✅ Check last update date (avoid abandoned packages)
4. ✅ Review permissions required
5. ✅ Consider package size (large packages = more attack surface)

---

## Infrastructure Security

### Network Security

**VPC Isolation**:
- Public subnet: Load balancers only
- Private subnet: Application servers, databases
- No direct internet access for private resources

**Security Groups** (Firewall Rules):
```yaml
# API Service Security Group
Ingress:
  - Port 443: From Load Balancer SG
  - Port 8000: From Load Balancer SG (internal)
Egress:
  - Port 5432: To Database SG
  - Port 6379: To Redis SG
  - Port 443: To Internet (external APIs)

# Database Security Group
Ingress:
  - Port 5432: From API Service SG only
Egress:
  - None (database doesn't need outbound)
```

### AWS Security Best Practices

**IAM Policies** (Least Privilege):
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject"
      ],
      "Resource": "arn:aws:s3:::rwa-prime-data/*"
    }
  ]
}
```

**S3 Bucket Security**:
```python
# Block public access
block_public_acls = True
block_public_policy = True
ignore_public_acls = True
restrict_public_buckets = True

# Enable versioning (protect against deletions)
versioning = True

# Enable encryption at rest
encryption = "AES256"

# Enable access logging
logging = {
    "target_bucket": "rwa-prime-logs",
    "target_prefix": "s3-access/"
}
```

### Container Security

**Dockerfile Best Practices**:
```dockerfile
# Use specific version (not latest)
FROM python:3.11.6-slim

# Run as non-root user
RUN useradd -m -u 1000 appuser
USER appuser

# Copy only necessary files
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY --chown=appuser:appuser ./app /app

# Don't expose unnecessary ports
EXPOSE 8000

# Use exec form for signals
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

**Scan Images for Vulnerabilities**:
```bash
# Trivy scanner
trivy image rwa-prime-api:latest

# AWS ECR scanning
aws ecr start-image-scan --repository-name rwa-prime-api --image-id imageTag=latest
```

---

## OWASP Top 10 Mitigations

| OWASP Risk | Mitigation |
|------------|------------|
| **A01 Broken Access Control** | RBAC, resource-level authorization checks, principle of least privilege |
| **A02 Cryptographic Failures** | TLS 1.3, bcrypt for passwords, AES-256 for data at rest, secure key management |
| **A03 Injection** | Parameterized queries, ORM, input validation, output encoding |
| **A04 Insecure Design** | Threat modeling, security by design, secure defaults |
| **A05 Security Misconfiguration** | Disable debug in production, remove default credentials, security headers |
| **A06 Vulnerable Components** | Dependency scanning (Snyk, Dependabot), regular updates |
| **A07 Authentication Failures** | Strong passwords, 2FA, account lockout, JWT expiry, session management |
| **A08 Software and Data Integrity** | Code signing, SRI for CDN resources, verified dependencies |
| **A09 Logging & Monitoring** | Centralized logging (CloudWatch), audit logs, security alerts |
| **A10 SSRF** | Whitelist external APIs, validate URLs, network segmentation |

---

## Security Checklist

### Pre-Deployment Checklist

**Authentication & Authorization**:
- [ ] Password hashing uses bcrypt (12 rounds minimum)
- [ ] JWT tokens use RS256 (asymmetric)
- [ ] Access tokens expire in ≤15 minutes
- [ ] 2FA implemented for Enterprise tier
- [ ] RBAC implemented for all endpoints
- [ ] Resource-level authorization checks in place

**Input Validation**:
- [ ] All user input validated with Pydantic
- [ ] SQL queries use parameterization or ORM
- [ ] File uploads restricted by type and size
- [ ] Rate limiting enabled on all endpoints

**Security Headers**:
- [ ] Content-Security-Policy configured
- [ ] X-Frame-Options: DENY
- [ ] X-Content-Type-Options: nosniff
- [ ] Strict-Transport-Security enabled
- [ ] CORS configured (restrict origins)

**Secrets Management**:
- [ ] No secrets in code or environment variables (production)
- [ ] Secrets stored in AWS Secrets Manager
- [ ] Encryption keys rotated every 90 days
- [ ] 2FA secrets encrypted at rest

**Infrastructure**:
- [ ] VPC configured with public/private subnets
- [ ] Security groups follow least privilege
- [ ] S3 buckets have public access blocked
- [ ] RDS has encryption at rest enabled
- [ ] CloudWatch logging enabled
- [ ] AWS GuardDuty enabled

**Monitoring**:
- [ ] Failed login attempts logged
- [ ] Authorization failures logged
- [ ] Anomalous activity alerts configured
- [ ] Error monitoring (Sentry) configured

**Dependencies**:
- [ ] All dependencies scanned for vulnerabilities
- [ ] Dependabot enabled for automatic updates
- [ ] No known critical CVEs in dependencies

### Code Review Security Checklist

**For Every PR**:
- [ ] No hardcoded secrets (API keys, passwords)
- [ ] SQL queries use parameterization
- [ ] User input is validated and sanitized
- [ ] Authorization checks present
- [ ] Sensitive operations logged
- [ ] Error messages don't expose sensitive info
- [ ] No use of `eval()`, `exec()`, or dangerous functions
- [ ] File paths validated (prevent path traversal)

---

## Incident Response

### Security Incident Procedure

**1. Detection**:
- Anomaly detected by monitoring
- User reports suspicious activity
- Vulnerability disclosed

**2. Containment**:
- Revoke compromised credentials
- Block malicious IPs
- Take affected services offline if necessary

**3. Investigation**:
- Review audit logs
- Identify scope of breach
- Preserve evidence

**4. Remediation**:
- Patch vulnerabilities
- Rotate secrets
- Restore from backups if needed

**5. Communication**:
- Notify affected users (if PII compromised)
- Comply with breach notification laws (GDPR, CCPA)
- Publish post-mortem (internally)

**6. Post-Incident**:
- Update security procedures
- Add monitoring for similar attacks
- Conduct security training

### Breach Notification Timeline

**GDPR**: 72 hours to notify authorities
**CCPA**: "Without unreasonable delay"

---

**Last Updated**: October 24, 2025
**Security Policy Version**: 1.0
**Next Security Audit**: January 2026

---

**Remember**: Security is not a feature, it's a requirement. Review this guide regularly and stay updated on emerging threats! 🔒
