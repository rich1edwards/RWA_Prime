# Critical Decisions Tracker

**Purpose**: Track all critical architectural and business decisions before development begins.

**Status Key**:
- ⏳ Pending Decision
- ✅ Decided
- 🚧 In Progress
- ⚠️ Blocked

---

## Infrastructure & Cloud

| Decision | Status | Answer | Notes | Owner |
|----------|--------|--------|-------|-------|
| AWS Account (new/existing) | ⏳ | | | |
| AWS Primary Region | ⏳ | us-east-1 (proposed) | | |
| Multi-region Strategy | ⏳ | | | |
| Domain Name | ⏳ | | | |
| SSL Certificate Strategy | ⏳ | AWS ACM (proposed) | | |
| Monthly Infrastructure Budget | ⏳ | $2,500/month (estimated) | | |
| Kubernetes Cluster Size (dev) | ⏳ | 2-3 t3.medium nodes (proposed) | | |
| Kubernetes Cluster Size (prod) | ⏳ | 5-10 t3.xlarge nodes (proposed) | | |

---

## External APIs & Data Sources

| Service | Tier Decision | Monthly Cost | Status | Owner |
|---------|--------------|--------------|--------|-------|
| CoinAPI | ⏳ Startup ($329) vs Pro ($829) | $329-$829 | ⏳ | |
| Amberdata | ⏳ Developer ($500) vs Pro ($1500) | $500-$1500 | ⏳ | |
| Bitquery | ⏳ Explorer ($99) vs Pro ($299) | $99-$299 | ⏳ | |
| RWA.io | ⏳ Basic ($299) vs Premium ($699) | $299-$699 | ⏳ | |
| Trading Economics | Standard ($250) | $250 | ⏳ | |
| NewsAPI.ai | Professional ($449) | $449 | ⏳ | |

**Backup Data Sources**: ⏳ TBD

**Mock Data for Development**: ⏳ TBD

---

## Authentication & Payment

| Decision | Status | Answer | Notes | Owner |
|----------|--------|--------|-------|-------|
| Email Provider | ⏳ | SendGrid (proposed) | | |
| SMS Provider (2FA) | ⏳ | Twilio (proposed) | | |
| Payment Processor | ⏳ | Stripe (proposed) | CRITICAL | |
| Subscription Management | ⏳ | Stripe Billing (proposed) | | |
| Trial Period | ⏳ | 7-day (proposed) | | |
| Trial Requires Credit Card | ⏳ | Yes (proposed) | | |
| Billing Cycle | ⏳ | Monthly + Annual | | |
| Refund Policy | ⏳ | 30-day (proposed) | | |
| Tax Handling | ⏳ | Stripe Tax (proposed) | | |

---

## Blockchain Integration

| Decision | Status | Answer | Notes | Owner |
|----------|--------|--------|-------|-------|
| Blockchain Node Provider | ⏳ | Alchemy (proposed) | | |
| Initial Blockchains Supported | ⏳ | Ethereum, Polygon (proposed) | | |
| Wallet Connection Protocol | ⏳ | WalletConnect v2 (proposed) | | |
| Supported Wallets | ⏳ | MetaMask, Coinbase, WalletConnect (proposed) | | |

---

## ML Models & Training

| Decision | Status | Answer | Notes | Owner |
|----------|--------|--------|-------|-------|
| Historical Data Source | ⏳ | | Need 1-2 years | |
| ML Training Platform | ⏳ | AWS SageMaker (proposed) | | |
| Model Storage | ✅ | S3 | | |
| Model Versioning | ⏳ | MLflow (proposed) | | |
| Training Schedule | ⏳ | Daily (proposed) | | |

---

## User Management & Tiers

| Decision | Status | Answer | Notes | Owner |
|----------|--------|--------|-------|-------|
| Free Trial Offered | ⏳ | Yes, 7-day Professional tier (proposed) | | |
| Free Tier Available | ⏳ | No (proposed) | | |
| Downgrade Handling | ⏳ | Archive excess items (proposed) | | |
| Portfolio Limit Enforcement | ⏳ | Hard limit (proposed) | | |
| Alert Limit Enforcement | ⏳ | Hard limit (proposed) | | |

---

## Regulatory & Compliance

| Decision | Status | Answer | Notes | Owner |
|----------|--------|--------|-------|-------|
| Terms of Service Drafted | ⏳ | | REQUIRED | |
| Privacy Policy Drafted | ⏳ | | REQUIRED | |
| Cookie Policy Drafted | ⏳ | | REQUIRED | |
| Financial Disclaimer | ⏳ | | REQUIRED | |
| GDPR Compliance Plan | ⏳ | | | |
| CCPA Compliance Plan | ⏳ | | | |
| Legal Counsel Consulted | ⏳ | | | |

---

## Monitoring & Operations

| Decision | Status | Answer | Notes | Owner |
|----------|--------|--------|-------|-------|
| APM/Monitoring Platform | ⏳ | New Relic (proposed) | | |
| Error Tracking | ✅ | Sentry | | |
| Log Aggregation | ⏳ | CloudWatch Logs (proposed) | | |
| Status Page Provider | ⏳ | Statuspage.io (proposed) | | |
| On-Call Rotation | ⏳ | | | |
| Incident Escalation Policy | ⏳ | | | |

---

## Team & Organization

| Decision | Status | Answer | Notes | Owner |
|----------|--------|--------|-------|-------|
| Initial Team Size | ⏳ | | | |
| Backend Developers | ⏳ | | | |
| Frontend Developers | ⏳ | | | |
| ML Engineers | ⏳ | | | |
| DevOps/SRE | ⏳ | | | |
| QA Engineers | ⏳ | | | |
| Production Access Policy | ⏳ | | | |
| PR Approval Requirements | ⏳ | 1 approval (features), 2 (breaking) | | |

---

## Frontend & Design

| Decision | Status | Answer | Notes | Owner |
|----------|--------|--------|-------|-------|
| Design System / UI Kit | ⏳ | Tailwind + Custom (proposed) | | |
| Design Files Available | ⏳ | | | |
| Brand Guidelines | ⏳ | | Colors, fonts, logos | |
| Mobile App Timeline | ⏳ | Phase 2 (proposed) | | |
| Mobile Platform | ⏳ | React Native, iOS + Android (proposed) | | |

---

## Analytics & Support

| Decision | Status | Answer | Notes | Owner |
|----------|--------|--------|-------|-------|
| Analytics Platform | ⏳ | Mixpanel (proposed) | | |
| Support Ticket System | ⏳ | Intercom (proposed) | | |
| Live Chat Widget | ⏳ | Yes, Intercom (proposed) | | |
| Knowledge Base Platform | ⏳ | Intercom Articles (proposed) | | |

---

## Critical Path Items (Block Development)

1. ⏳ **AWS Account Setup** - Needed for infrastructure
2. ⏳ **Domain Name** - Needed for SSL, DNS
3. ⏳ **API Key Procurement** - Long lead time, needed for development
4. ⏳ **Payment Processor** - CRITICAL - needed for billing
5. ⏳ **Legal Documents** - Required before public launch
6. ⏳ **Historical Data for ML** - Needed for model training

---

## Decision Meeting Agenda

**Attendees**: [List stakeholders]
**Date**: [TBD]

### Agenda:
1. Infrastructure (AWS, domain, budget)
2. External APIs (tier selection, cost approval)
3. Payment processor selection
4. Blockchain integration scope
5. Team composition
6. Launch timeline

---

**Last Updated**: [Date]
**Next Review**: [Date]
