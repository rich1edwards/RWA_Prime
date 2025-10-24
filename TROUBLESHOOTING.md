# Troubleshooting Guide

## Purpose

This document provides solutions to common issues, error patterns, debugging strategies, and performance problems encountered in the RWA Prime platform. Use this guide to diagnose and resolve issues quickly without waiting for human assistance.

---

## Table of Contents

- [Quick Diagnostics](#quick-diagnostics)
- [Application Startup Issues](#application-startup-issues)
- [Database Connection Issues](#database-connection-issues)
- [Kafka/Message Queue Issues](#kafkamessage-queue-issues)
- [Redis/Caching Issues](#rediscaching-issues)
- [ML Model Issues](#ml-model-issues)
- [External API Issues](#external-api-issues)
- [Authentication Issues](#authentication-issues)
- [Performance Issues](#performance-issues)
- [WebSocket Issues](#websocket-issues)
- [Docker/Kubernetes Issues](#dockerkubernetes-issues)
- [Data Pipeline Issues](#data-pipeline-issues)
- [Frontend Issues](#frontend-issues)
- [Common Error Messages](#common-error-messages)
- [Debugging Tools and Commands](#debugging-tools-and-commands)
- [Performance Monitoring](#performance-monitoring)

---

## Quick Diagnostics

### Health Check Endpoints

```bash
# API health
curl http://localhost:8000/health

# Database connectivity
curl http://localhost:8000/health/db

# Redis connectivity
curl http://localhost:8000/health/redis

# Kafka connectivity
curl http://localhost:8000/health/kafka

# All services
curl http://localhost:8000/health/detailed
```

**Expected Response**:
```json
{
  "status": "healthy",
  "timestamp": "2025-10-24T12:34:56.789Z",
  "services": {
    "database": "healthy",
    "redis": "healthy",
    "kafka": "healthy"
  },
  "version": "1.0.0"
}
```

### System Resources Check

```bash
# CPU usage
top -o cpu

# Memory usage
free -h

# Disk usage
df -h

# Docker container stats
docker stats

# Kubernetes pod resources
kubectl top pods -n rwa-prime
```

---

## Application Startup Issues

### Issue: "Address already in use" (Port Conflict)

**Symptom**:
```
Error: [Errno 48] Address already in use
uvicorn.error: Error binding to 0.0.0.0:8000
```

**Diagnosis**:
```bash
# Find process using port 8000
lsof -i :8000

# Or using netstat
netstat -anv | grep 8000
```

**Solution 1**: Kill the process
```bash
# Kill process by PID
kill -9 <PID>

# Or kill all processes on port 8000
lsof -ti :8000 | xargs kill -9
```

**Solution 2**: Change port
```bash
# Use different port
uvicorn app.main:app --host 0.0.0.0 --port 8001
```

**Root Cause**: Previous instance not properly terminated, or another service using the port.

---

### Issue: "ModuleNotFoundError" (Missing Dependencies)

**Symptom**:
```
ModuleNotFoundError: No module named 'fastapi'
```

**Diagnosis**:
```bash
# Check installed packages
pip list | grep fastapi

# Check Python version
python --version

# Check virtual environment
which python
```

**Solution**:
```bash
# Activate virtual environment
source venv/bin/activate  # Unix/Mac
venv\Scripts\activate     # Windows

# Install dependencies
pip install -r requirements.txt

# Verify installation
pip show fastapi
```

**Root Cause**: Virtual environment not activated, or dependencies not installed.

---

### Issue: Environment Variables Not Loaded

**Symptom**:
```
KeyError: 'DATABASE_URL'
Settings validation error: field required (type=value_error.missing)
```

**Diagnosis**:
```bash
# Check if .env file exists
ls -la .env

# Print environment variable
echo $DATABASE_URL

# Check all env vars
env | grep DATABASE
```

**Solution**:
```bash
# Load .env file manually
export $(cat .env | xargs)

# Or use python-dotenv
pip install python-dotenv

# In code
from dotenv import load_dotenv
load_dotenv()
```

**Root Cause**: `.env` file missing, not loaded, or variables not exported.

---

## Database Connection Issues

### Issue: "Connection Refused" (PostgreSQL)

**Symptom**:
```
sqlalchemy.exc.OperationalError: (psycopg2.OperationalError)
could not connect to server: Connection refused
Is the server running on host "localhost" and accepting TCP/IP connections on port 5432?
```

**Diagnosis**:
```bash
# Check if PostgreSQL is running
pg_isready -h localhost -p 5432

# Check Docker container (if using Docker)
docker ps | grep postgres

# Check PostgreSQL logs
docker logs postgres-container

# Test connection
psql -h localhost -U postgres -d rwa_prime
```

**Solution 1**: Start PostgreSQL
```bash
# macOS (Homebrew)
brew services start postgresql

# Linux (systemd)
sudo systemctl start postgresql

# Docker
docker start postgres-container

# Docker Compose
docker-compose up -d postgres
```

**Solution 2**: Check connection string
```python
# Correct format
DATABASE_URL = "postgresql://user:password@localhost:5432/rwa_prime"

# Common mistakes:
# ❌ postgresql://localhost/rwa_prime (missing user/password)
# ❌ postgres://... (should be postgresql://)
# ❌ Wrong port (5433 instead of 5432)
```

**Root Cause**: PostgreSQL not running, wrong connection string, or firewall blocking port 5432.

---

### Issue: "Too Many Connections"

**Symptom**:
```
sqlalchemy.exc.OperationalError: FATAL: too many connections for role "postgres"
```

**Diagnosis**:
```sql
-- Check active connections
SELECT count(*) FROM pg_stat_activity;

-- Check max connections
SHOW max_connections;

-- Check connections by database
SELECT datname, count(*)
FROM pg_stat_activity
GROUP BY datname;
```

**Solution 1**: Increase max connections (PostgreSQL config)
```ini
# postgresql.conf
max_connections = 200  # Increase from default 100
```

**Solution 2**: Fix connection pool settings
```python
# SQLAlchemy connection pool
from sqlalchemy import create_engine

engine = create_engine(
    DATABASE_URL,
    pool_size=10,          # Max 10 connections per worker
    max_overflow=20,       # Allow 20 extra connections temporarily
    pool_recycle=3600,     # Recycle connections after 1 hour
    pool_pre_ping=True     # Verify connections before use
)
```

**Solution 3**: Close idle connections
```bash
# Kill idle connections older than 10 minutes
psql -U postgres -c "
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE datname = 'rwa_prime'
  AND state = 'idle'
  AND state_change < current_timestamp - INTERVAL '10 minutes';
"
```

**Root Cause**: Connection leak (not closing connections), pool size too large, or misconfigured connection pool.

---

### Issue: Slow Query Performance

**Symptom**:
```
Request timeout after 30 seconds
Query took 45 seconds to execute
```

**Diagnosis**:
```sql
-- Find slow queries
SELECT pid, now() - pg_stat_activity.query_start AS duration, query
FROM pg_stat_activity
WHERE (now() - pg_stat_activity.query_start) > interval '5 seconds'
  AND state = 'active';

-- Check missing indexes
SELECT schemaname, tablename, attname, n_distinct, correlation
FROM pg_stats
WHERE schemaname = 'public'
  AND tablename = 'price_data'
ORDER BY abs(correlation) DESC;

-- EXPLAIN query
EXPLAIN ANALYZE
SELECT * FROM price_data
WHERE asset_id = '123...' AND time > NOW() - INTERVAL '30 days';
```

**Solution 1**: Add missing index
```sql
-- Add index on frequently queried columns
CREATE INDEX idx_price_data_asset_time
ON price_data(asset_id, time DESC);

-- Verify index is used
EXPLAIN SELECT * FROM price_data WHERE asset_id = '...';
-- Should show "Index Scan using idx_price_data_asset_time"
```

**Solution 2**: Optimize query
```sql
-- ❌ BAD: Fetching all columns
SELECT * FROM price_data WHERE asset_id = '...';

-- ✅ GOOD: Fetch only needed columns
SELECT time, price_usd FROM price_data WHERE asset_id = '...';

-- ❌ BAD: Using OR in WHERE clause
SELECT * FROM price_data WHERE asset_id = '...' OR asset_id = '...';

-- ✅ GOOD: Use IN clause
SELECT * FROM price_data WHERE asset_id IN ('...', '...');
```

**Solution 3**: Use TimescaleDB features
```sql
-- Use continuous aggregates for pre-computed aggregations
CREATE MATERIALIZED VIEW price_1h
WITH (timescaledb.continuous) AS
SELECT time_bucket('1 hour', time) AS bucket,
       asset_id,
       FIRST(price_usd, time) AS open,
       LAST(price_usd, time) AS close,
       MAX(price_usd) AS high,
       MIN(price_usd) AS low
FROM price_data
GROUP BY bucket, asset_id;

-- Query the aggregate instead
SELECT * FROM price_1h WHERE asset_id = '...' AND bucket > NOW() - INTERVAL '30 days';
```

**Root Cause**: Missing indexes, inefficient query, or fetching too much data.

---

## Kafka/Message Queue Issues

### Issue: Kafka Consumer Lag

**Symptom**:
```
Consumer group 'price-consumer' is lagging behind by 10000 messages
Data ingestion delayed by 5 minutes
```

**Diagnosis**:
```bash
# Check consumer lag
kafka-consumer-groups.sh --bootstrap-server localhost:9092 \
  --describe --group price-consumer

# Expected output shows LAG column
# GROUP           TOPIC      PARTITION  CURRENT-OFFSET  LOG-END-OFFSET  LAG
# price-consumer  prices     0          5000            15000           10000
```

**Solution 1**: Scale consumers
```python
# Increase number of consumer instances
# Before: 1 consumer, 3 partitions
# After: 3 consumers, 3 partitions (1:1 mapping)

# Kubernetes: scale deployment
kubectl scale deployment price-consumer --replicas=3 -n rwa-prime
```

**Solution 2**: Optimize consumer processing
```python
# ❌ BAD: Processing messages one by one
for message in consumer:
    process_message(message.value)

# ✅ GOOD: Batch processing
batch = []
for message in consumer:
    batch.append(message.value)
    if len(batch) >= 100:
        process_batch(batch)  # Process 100 messages at once
        batch = []
        consumer.commit()
```

**Solution 3**: Increase partition count
```bash
# Increase partitions to allow more parallel consumers
kafka-topics.sh --bootstrap-server localhost:9092 \
  --alter --topic prices --partitions 6
```

**Root Cause**: Consumer too slow, not enough consumer instances, or sudden spike in messages.

---

### Issue: Kafka Connection Refused

**Symptom**:
```
kafka.errors.NoBrokersAvailable: NoBrokersAvailable
```

**Diagnosis**:
```bash
# Check if Kafka is running
docker ps | grep kafka

# Check Kafka logs
docker logs kafka-container

# Test connection
kafka-broker-api-versions.sh --bootstrap-server localhost:9092
```

**Solution**:
```bash
# Start Kafka (Docker Compose)
docker-compose up -d kafka

# Check Kafka advertised listeners
# In docker-compose.yml or server.properties:
KAFKA_ADVERTISED_LISTENERS=PLAINTEXT://localhost:9092

# Ensure correct bootstrap server
KAFKA_BOOTSTRAP_SERVERS=localhost:9092  # Not kafka:9092 from host
```

**Root Cause**: Kafka not running, wrong bootstrap server, or advertised listeners misconfigured.

---

## Redis/Caching Issues

### Issue: Redis Connection Refused

**Symptom**:
```
redis.exceptions.ConnectionError: Error 61 connecting to localhost:6379. Connection refused.
```

**Diagnosis**:
```bash
# Check if Redis is running
redis-cli ping
# Should return: PONG

# Check Docker container
docker ps | grep redis

# Check Redis logs
docker logs redis-container
```

**Solution**:
```bash
# Start Redis
# macOS (Homebrew)
brew services start redis

# Linux (systemd)
sudo systemctl start redis

# Docker
docker start redis-container

# Docker Compose
docker-compose up -d redis
```

**Root Cause**: Redis not running or wrong connection configuration.

---

### Issue: Cache Miss Rate Too High

**Symptom**:
```
Cache hit rate: 20% (expected >80%)
Database queries increased by 5x
```

**Diagnosis**:
```bash
# Check Redis stats
redis-cli INFO stats | grep keyspace

# Check cache hit/miss ratio
redis-cli INFO stats | grep -E 'keyspace_hits|keyspace_misses'

# Calculate hit rate
# hit_rate = keyspace_hits / (keyspace_hits + keyspace_misses)
```

**Solution 1**: Increase cache TTL
```python
# Before: 1 minute TTL
redis_client.setex("prediction:123", 60, prediction_data)

# After: 1 hour TTL
redis_client.setex("prediction:123", 3600, prediction_data)
```

**Solution 2**: Warm cache proactively
```python
# Preload frequently accessed data
async def warm_cache():
    top_assets = await get_top_100_assets()
    for asset in top_assets:
        prediction = await generate_prediction(asset.id)
        redis_client.setex(f"prediction:{asset.id}", 3600, prediction)
```

**Solution 3**: Increase Redis memory
```bash
# Check current memory
redis-cli INFO memory | grep used_memory_human

# Increase max memory (redis.conf)
maxmemory 2gb

# Set eviction policy
maxmemory-policy allkeys-lru  # Evict least recently used keys
```

**Root Cause**: TTL too short, cache not preloaded, or insufficient Redis memory causing evictions.

---

## ML Model Issues

### Issue: Prediction Generation Fails

**Symptom**:
```
ERR_PRED_003: Failed to generate prediction
RuntimeError: CUDA out of memory
```

**Diagnosis**:
```python
# Check available GPU memory
import torch
print(torch.cuda.memory_summary())

# Check model size
import sys
model_size_mb = sys.getsizeof(model) / (1024 * 1024)
print(f"Model size: {model_size_mb:.2f} MB")

# Check input data shape
print(f"Input shape: {X.shape}")
```

**Solution 1**: Reduce batch size
```python
# Before: Batch size 128
predictions = model.predict(X, batch_size=128)

# After: Batch size 32
predictions = model.predict(X, batch_size=32)
```

**Solution 2**: Clear GPU cache
```python
import torch

# Clear GPU cache after each prediction
torch.cuda.empty_cache()
```

**Solution 3**: Use CPU for inference
```python
# Move model to CPU
device = torch.device('cpu')
model = model.to(device)

# Run inference on CPU
predictions = model.predict(X)
```

**Root Cause**: GPU memory exhausted, batch size too large, or memory leak in model.

---

### Issue: Insufficient Historical Data

**Symptom**:
```
ERR_PRED_001: Insufficient historical data for prediction
Required: 90 days, Available: 45 days
```

**Diagnosis**:
```sql
-- Check data availability for asset
SELECT COUNT(*), MIN(time), MAX(time)
FROM price_data
WHERE asset_id = '123...';

-- Check data gaps
SELECT time
FROM generate_series(
  (SELECT MIN(time) FROM price_data WHERE asset_id = '...'),
  (SELECT MAX(time) FROM price_data WHERE asset_id = '...'),
  '1 day'::interval
) AS expected_time
WHERE NOT EXISTS (
  SELECT 1 FROM price_data
  WHERE asset_id = '...' AND time::date = expected_time::date
);
```

**Solution 1**: Backfill historical data
```python
# Backfill from external API
from datetime import datetime, timedelta

end_date = datetime.utcnow()
start_date = end_date - timedelta(days=365)

# Fetch historical data
historical_data = fetch_historical_prices(
    asset_symbol="USDC",
    start_date=start_date,
    end_date=end_date
)

# Insert into database
bulk_insert_prices(historical_data)
```

**Solution 2**: Use fallback model
```python
# Use ARIMA (requires less data) instead of LSTM
if historical_days < 90:
    prediction = arima_model.predict(asset_id)  # Works with 30 days
else:
    prediction = lstm_model.predict(asset_id)   # Requires 90 days
```

**Root Cause**: New asset without sufficient history, or data ingestion failure.

---

### Issue: Model Accuracy Degradation

**Symptom**:
```
MAPE increased from 12% to 25%
Prediction error doubled in last week
```

**Diagnosis**:
```sql
-- Check recent prediction accuracy
SELECT
    DATE_TRUNC('day', prediction_date) AS day,
    AVG(ABS(prediction_error)) AS avg_error
FROM predictions
WHERE prediction_date > NOW() - INTERVAL '30 days'
  AND actual_price IS NOT NULL
GROUP BY day
ORDER BY day DESC;

-- Compare to historical accuracy
SELECT
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY ABS(prediction_error)) AS median_error
FROM predictions
WHERE actual_price IS NOT NULL;
```

**Solution**: Retrain model
```python
# Trigger model retraining
from app.ml_service.train import retrain_lstm_model

# Retrain with latest data
retrain_lstm_model(
    asset_id=asset_id,
    start_date=datetime.utcnow() - timedelta(days=365),
    end_date=datetime.utcnow()
)

# Deploy new model version
deploy_model(model_path="models/lstm_v2.2.pkl")
```

**Root Cause**: Market regime change, model drift, or outdated training data.

---

## External API Issues

### Issue: CoinAPI Rate Limit Exceeded

**Symptom**:
```
ERR_EXT_003: External API quota exceeded
CoinAPI: 429 Too Many Requests
```

**Diagnosis**:
```bash
# Check API usage
curl -H "X-CoinAPI-Key: YOUR_KEY" \
  https://rest.coinapi.io/v1/usage

# Check Redis rate limiter
redis-cli GET "rate_limit:coinapi:requests"
```

**Solution 1**: Implement caching
```python
# Cache price data to reduce API calls
@cache(ttl=60)  # Cache for 1 minute
async def get_price(symbol: str):
    response = await coinapi_client.get_price(symbol)
    return response
```

**Solution 2**: Use batch requests
```python
# ❌ BAD: 100 API calls
for symbol in symbols:
    price = await get_price(symbol)

# ✅ GOOD: 1 API call
prices = await get_prices_batch(symbols)  # Fetch all at once
```

**Solution 3**: Upgrade API plan
```
Explorer Plan: 10K requests/day → Professional Plan: 100K requests/day
```

**Root Cause**: Too many API calls, no caching, or insufficient API quota.

---

### Issue: External API Timeout

**Symptom**:
```
ERR_EXT_001: External API timeout
Request to Amberdata timed out after 30 seconds
```

**Diagnosis**:
```python
# Check API latency
import time

start = time.time()
response = await external_api.get_data()
latency = time.time() - start
print(f"API latency: {latency:.2f}s")
```

**Solution 1**: Increase timeout
```python
# Before: 10 second timeout
response = await httpx.get(url, timeout=10.0)

# After: 30 second timeout
response = await httpx.get(url, timeout=30.0)
```

**Solution 2**: Implement retry with exponential backoff
```python
from tenacity import retry, stop_after_attempt, wait_exponential

@retry(
    stop=stop_after_attempt(3),
    wait=wait_exponential(multiplier=1, min=2, max=10)
)
async def fetch_with_retry():
    return await external_api.get_data()
```

**Root Cause**: External API slow, network latency, or timeout too short.

---

## Authentication Issues

### Issue: "Invalid or Expired Token"

**Symptom**:
```
ERR_AUTH_001: Invalid or expired access token
401 Unauthorized
```

**Diagnosis**:
```python
# Decode JWT to check expiry
from jose import jwt

try:
    payload = jwt.decode(token, PUBLIC_KEY, algorithms=["RS256"])
    print(f"Token expires at: {payload['exp']}")
    print(f"Current time: {int(time.time())}")
except jwt.ExpiredSignatureError:
    print("Token expired")
except jwt.JWTError as e:
    print(f"Invalid token: {e}")
```

**Solution 1**: Refresh token
```typescript
// React: Refresh access token
const refreshAccessToken = async () => {
  const refreshToken = getRefreshToken();

  const response = await axios.post('/auth/refresh', {
    refresh_token: refreshToken
  });

  setAccessToken(response.data.access_token);
};
```

**Solution 2**: Implement automatic token refresh
```typescript
// Axios interceptor for automatic refresh
axios.interceptors.response.use(
  (response) => response,
  async (error) => {
    if (error.response?.status === 401 && error.config && !error.config.__isRetry) {
      error.config.__isRetry = true;

      try {
        await refreshAccessToken();
        return axios(error.config);  // Retry original request
      } catch {
        // Refresh failed, redirect to login
        window.location.href = '/login';
      }
    }
    return Promise.reject(error);
  }
);
```

**Root Cause**: Access token expired (15 minute TTL), or token corrupted.

---

## Performance Issues

### Issue: Slow API Response Time

**Symptom**:
```
API response time: 3500ms (target: <500ms)
/assets endpoint slow
```

**Diagnosis**:
```python
# Add timing middleware
import time

@app.middleware("http")
async def add_process_time_header(request: Request, call_next):
    start_time = time.time()
    response = await call_next(request)
    process_time = (time.time() - start_time) * 1000
    response.headers["X-Process-Time"] = f"{process_time:.2f}ms"

    if process_time > 500:
        logger.warning(f"Slow request: {request.url.path} took {process_time:.2f}ms")

    return response
```

**Solution 1**: Add database indexes
```sql
-- Identify missing indexes
EXPLAIN ANALYZE SELECT * FROM assets WHERE asset_class = 'tokenized_treasury';

-- Add index
CREATE INDEX idx_assets_class ON assets(asset_class);
```

**Solution 2**: Implement caching
```python
from functools import lru_cache
from fastapi_cache.decorator import cache

@router.get("/assets")
@cache(expire=60)  # Cache for 1 minute
async def get_assets():
    return await db.query(Asset).all()
```

**Solution 3**: Use pagination
```python
# ❌ BAD: Fetch all assets (1000+)
@router.get("/assets")
async def get_assets():
    return await db.query(Asset).all()

# ✅ GOOD: Paginate results
@router.get("/assets")
async def get_assets(skip: int = 0, limit: int = 20):
    return await db.query(Asset).offset(skip).limit(limit).all()
```

**Root Cause**: Missing indexes, no caching, fetching too much data, or N+1 query problem.

---

### Issue: High Memory Usage

**Symptom**:
```
Memory usage: 8GB / 8GB (100%)
OOMKilled: Container killed due to out of memory
```

**Diagnosis**:
```python
# Check memory usage
import psutil

process = psutil.Process()
mem_info = process.memory_info()
print(f"Memory usage: {mem_info.rss / 1024 / 1024:.2f} MB")

# Profile memory
from memory_profiler import profile

@profile
def memory_intensive_function():
    # Function to profile
    pass
```

**Solution 1**: Fix memory leaks
```python
# ❌ BAD: Accumulating data in memory
global_cache = {}  # Never cleared

@router.get("/data")
async def get_data():
    global_cache[uuid.uuid4()] = large_data  # Memory leak
    return large_data

# ✅ GOOD: Use limited-size cache
from cachetools import LRUCache

cache = LRUCache(maxsize=1000)  # Limit to 1000 items

@router.get("/data")
async def get_data():
    cache[key] = large_data  # Automatically evicts old items
    return large_data
```

**Solution 2**: Use generators for large datasets
```python
# ❌ BAD: Load all data into memory
async def get_all_prices():
    prices = await db.query(PriceData).all()  # Loads millions of rows
    return prices

# ✅ GOOD: Stream data
async def get_all_prices():
    async for price in db.stream(select(PriceData)):
        yield price
```

**Solution 3**: Increase container memory
```yaml
# Kubernetes deployment
resources:
  limits:
    memory: "4Gi"  # Increase from 2Gi
  requests:
    memory: "2Gi"
```

**Root Cause**: Memory leak, loading too much data, or insufficient memory allocation.

---

## WebSocket Issues

### Issue: WebSocket Connection Drops

**Symptom**:
```
WebSocket closed unexpectedly
Connection lost every 60 seconds
```

**Diagnosis**:
```javascript
// Client-side logging
const ws = new WebSocket('wss://api.rwa-prime.com/ws');

ws.onclose = (event) => {
  console.log(`WebSocket closed: Code ${event.code}, Reason: ${event.reason}`);
};

ws.onerror = (error) => {
  console.error('WebSocket error:', error);
};
```

**Solution 1**: Implement ping/pong heartbeat
```python
# Backend (FastAPI)
@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    await websocket.accept()

    try:
        while True:
            # Send ping every 30 seconds
            await asyncio.sleep(30)
            await websocket.send_json({"type": "ping"})

            # Wait for pong (with timeout)
            try:
                message = await asyncio.wait_for(
                    websocket.receive_json(),
                    timeout=10
                )
                if message.get("type") != "pong":
                    # Handle other messages
                    pass
            except asyncio.TimeoutError:
                # Client didn't respond to ping
                break

    except WebSocketDisconnect:
        logger.info("Client disconnected")
```

**Solution 2**: Auto-reconnect on client
```typescript
class WebSocketClient {
  private reconnectAttempts = 0;
  private maxReconnectAttempts = 5;

  connect() {
    this.ws = new WebSocket('wss://api.rwa-prime.com/ws');

    this.ws.onclose = () => {
      if (this.reconnectAttempts < this.maxReconnectAttempts) {
        const delay = Math.min(1000 * Math.pow(2, this.reconnectAttempts), 30000);
        setTimeout(() => this.connect(), delay);
        this.reconnectAttempts++;
      }
    };

    this.ws.onopen = () => {
      this.reconnectAttempts = 0;  // Reset on successful connection
    };
  }
}
```

**Root Cause**: Network timeout, load balancer timeout, or client not responding to ping.

---

## Docker/Kubernetes Issues

### Issue: Docker Container Won't Start

**Symptom**:
```
Error: Container exited with code 1
Container rwa-prime-api is unhealthy
```

**Diagnosis**:
```bash
# Check container logs
docker logs rwa-prime-api

# Inspect container
docker inspect rwa-prime-api

# Check container health
docker ps --filter "name=rwa-prime-api"
```

**Solution**:
```bash
# Run container interactively to debug
docker run -it --rm rwa-prime-api:latest /bin/bash

# Check environment variables
docker exec rwa-prime-api env | grep DATABASE_URL

# Rebuild container (clear cache)
docker build --no-cache -t rwa-prime-api:latest .
```

**Root Cause**: Missing environment variables, failed health check, or startup command error.

---

### Issue: Kubernetes Pod CrashLoopBackOff

**Symptom**:
```
NAME                        READY   STATUS             RESTARTS   AGE
api-deployment-abc123-xyz   0/1     CrashLoopBackOff   5          5m
```

**Diagnosis**:
```bash
# Check pod logs
kubectl logs api-deployment-abc123-xyz -n rwa-prime

# Check previous container logs
kubectl logs api-deployment-abc123-xyz -n rwa-prime --previous

# Describe pod
kubectl describe pod api-deployment-abc123-xyz -n rwa-prime

# Check events
kubectl get events -n rwa-prime --sort-by='.lastTimestamp'
```

**Solution 1**: Fix health check
```yaml
# Deployment: Increase health check thresholds
livenessProbe:
  httpGet:
    path: /health
    port: 8000
  initialDelaySeconds: 60  # Increase from 30
  periodSeconds: 10
  failureThreshold: 5      # Increase from 3
```

**Solution 2**: Fix resource limits
```yaml
resources:
  limits:
    memory: "2Gi"    # Increase if OOMKilled
    cpu: "1000m"
  requests:
    memory: "1Gi"
    cpu: "500m"
```

**Root Cause**: Application crashes on startup, failed health check, or insufficient resources.

---

## Data Pipeline Issues

### Issue: Data Ingestion Delayed

**Symptom**:
```
Last price update: 10 minutes ago (expected: <1 minute)
Price data stale
```

**Diagnosis**:
```sql
-- Check last price update per asset
SELECT asset_id, MAX(time) as last_update
FROM price_data
GROUP BY asset_id
HAVING MAX(time) < NOW() - INTERVAL '5 minutes';

-- Check Kafka lag (see Kafka section)
kafka-consumer-groups.sh --bootstrap-server localhost:9092 \
  --describe --group price-consumer
```

**Solution**:
```bash
# Check data ingestion service logs
kubectl logs -f deployment/data-ingestion -n rwa-prime

# Check external API status
curl https://rest.coinapi.io/v1/exchangerate/BTC/USD

# Restart data ingestion service
kubectl rollout restart deployment/data-ingestion -n rwa-prime
```

**Root Cause**: External API down, Kafka consumer lag, or data ingestion service crashed.

---

## Frontend Issues

### Issue: "Cannot read property of undefined"

**Symptom**:
```
TypeError: Cannot read property 'price' of undefined
React component crashes
```

**Diagnosis**:
```typescript
// Add defensive checks
console.log('Asset data:', asset);
console.log('Asset price:', asset?.price);
```

**Solution**: Use optional chaining and nullish coalescing
```typescript
// ❌ BAD: Assumes data is always present
const price = asset.price.toFixed(2);

// ✅ GOOD: Handle undefined/null
const price = asset?.price?.toFixed(2) ?? 'N/A';

// ✅ GOOD: Conditional rendering
{asset?.price && (
  <div>{asset.price.toFixed(2)}</div>
)}
```

**Root Cause**: Data not loaded yet, API returned null, or component rendered before data available.

---

## Common Error Messages

### Python Errors

| Error Message | Likely Cause | Solution |
|---------------|--------------|----------|
| `ModuleNotFoundError: No module named 'X'` | Package not installed | `pip install X` |
| `ImportError: cannot import name 'X'` | Circular import or wrong import path | Check import order, fix circular dependency |
| `TypeError: 'NoneType' object is not iterable` | Function returned None instead of list | Add null check: `if data is None: return []` |
| `KeyError: 'key'` | Dictionary key doesn't exist | Use `.get('key', default)` |
| `AttributeError: 'NoneType' object has no attribute 'X'` | Object is None | Add null check: `if obj is not None: obj.X` |

### SQL Errors

| Error Message | Likely Cause | Solution |
|---------------|--------------|----------|
| `relation "table" does not exist` | Table not created or wrong schema | Run migrations: `alembic upgrade head` |
| `column "X" does not exist` | Column renamed or migration not run | Check migrations, add column |
| `duplicate key value violates unique constraint` | Trying to insert duplicate | Check unique constraints, handle conflict |
| `deadlock detected` | Concurrent transactions | Add retry logic, simplify transactions |

---

## Debugging Tools and Commands

### Backend Debugging

```python
# Python debugger
import pdb; pdb.set_trace()  # Set breakpoint

# IPython debugger (better)
from IPython import embed; embed()

# Logging
import logging
logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)
logger.debug("Debug message")

# FastAPI debug mode
uvicorn app.main:app --reload --log-level debug
```

### Database Debugging

```sql
-- Active queries
SELECT * FROM pg_stat_activity WHERE state = 'active';

-- Lock monitoring
SELECT * FROM pg_locks;

-- Table sizes
SELECT schemaname, tablename, pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

-- Query performance
EXPLAIN (ANALYZE, BUFFERS) SELECT ...;
```

### Docker Debugging

```bash
# Container logs
docker logs -f container-name

# Enter container
docker exec -it container-name /bin/bash

# Container stats
docker stats container-name

# Network debugging
docker network inspect bridge
```

---

## Performance Monitoring

### Metrics to Monitor

```python
# API latency (99th percentile)
p99_latency < 500ms

# Database query time
avg_query_time < 100ms

# Cache hit rate
cache_hit_rate > 80%

# Error rate
error_rate < 1%

# Memory usage
memory_usage < 80% of limit

# CPU usage
cpu_usage < 70%
```

### Monitoring Tools

- **Application**: New Relic, Datadog, Sentry
- **Infrastructure**: Prometheus + Grafana, CloudWatch
- **Logs**: ELK Stack (Elasticsearch, Logstash, Kibana)
- **Database**: pg_stat_statements, TimescaleDB metrics

---

**Last Updated**: October 24, 2025
**Version**: 1.0
**Next Review**: Monthly

---

**Remember**: When troubleshooting, always check logs first, then metrics, then reproduce the issue locally. Document solutions to new issues in this guide! 🔧
