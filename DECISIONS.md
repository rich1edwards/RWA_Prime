# Critical Decisions Tracker

**Purpose**: Track all critical architectural and business decisions before development begins.

**Status Key**:
- ⏳ Pending Decision
- ✅ Decided
- 🚧 In Progress
- ⚠️ Blocked

---

## 🚨 PRIORITY DECISIONS (Action Required)

### 🔴 CRITICAL - Blocks Development Start

**Must decide in next 48-72 hours** to avoid delaying project start:

| # | Decision | Why Critical | Impact if Delayed | Estimated Cost | Owner | Status |
|---|----------|-------------|-------------------|----------------|-------|--------|
| **1** | **Payment Processor Selection** | Cannot build billing, subscription management, tier enforcement | 2-3 week delay for integration | 2.9% + $0.30/txn | | ⏳ |
| **2** | **API Budget Approval** | Cannot develop data ingestion, predictions, sentiment analysis | All core features blocked | ~$2,000/month | | ⏳ |
| **3** | **Domain Name Purchase** | Cannot configure SSL, CORS, email, production URLs | Infrastructure setup blocked | $12/year | | ⏳ |
| **4** | **AWS Account Setup** | Cannot provision infrastructure, databases, Kubernetes | All infrastructure blocked | $812-$2,500/month | | ⏳ |
| **5** | **Historical ML Data Source** | Cannot train quality ML models, poor predictions | ML/prediction features blocked | $500-$2,000 one-time | | ⏳ |
| **6** | **Legal Documents (ToS/Privacy)** | Cannot launch publicly, legal exposure | Public launch blocked | $1,000-$3,000 one-time | | ⏳ |

**Total Critical Path Budget**: ~$5,500-$8,500 initial + ~$2,800-$4,500/month recurring

---

### 🟡 HIGH PRIORITY - Needed for MVP (Week 1-2)

**Must decide before Sprint 2** to maintain launch timeline:

| # | Decision | Why Important | Impact if Delayed | Estimated Cost | Owner | Status |
|---|----------|--------------|-------------------|----------------|-------|--------|
| **7** | Email Service Provider | User registration, notifications, password reset | User onboarding broken | $20/month (SendGrid) | | ⏳ |
| **8** | Blockchain Node Provider | Wallet sync, on-chain data | Portfolio sync broken | Free-$200/month | | ⏳ |
| **9** | Initial Blockchain Priority | Scope MVP features | Feature scope unclear | N/A | | ⏳ |
| **10** | Tier Limit Enforcement Strategy | User experience for limits | Confusing UX, support burden | N/A | | ⏳ |
| **11** | Free Trial Strategy | User acquisition | No trial = lower conversions | N/A | | ⏳ |
| **12** | Downgrade Flow Logic | User retention | Frustrating downgrades | N/A | | ⏳ |

---

### 🟢 MEDIUM PRIORITY - Decide Before Launch (Week 3-4)

**Should decide by end of Sprint 3**:

| # | Decision | Why Needed | Impact if Delayed | Estimated Cost | Owner | Status |
|---|----------|-----------|-------------------|----------------|-------|--------|
| **13** | Monitoring Stack (APM/Logs) | Production observability | Hard to debug issues | $200/month | | ⏳ |
| **14** | Status Page Provider | User communication during incidents | Poor incident comms | $29/month | | ⏳ |
| **15** | Design System Choice | Frontend consistency | Inconsistent UI | N/A | | ⏳ |
| **16** | Mobile App Timeline | Development planning | Resource allocation | N/A | | ⏳ |
| **17** | Team Structure | Hiring plan | Understaffed team | $500K-$1M/year | | ⏳ |
| **18** | Tax Handling Strategy | Revenue compliance | Tax filing issues | $0.50/txn (Stripe Tax) | | ⏳ |

---

### 🔵 LOW PRIORITY - Can Decide Post-MVP

**Can defer to Phase 2 without blocking launch**:

| # | Decision | When Needed | Owner | Status |
|---|----------|------------|-------|--------|
| **19** | Analytics Platform | Phase 1 end | | ⏳ |
| **20** | Customer Support System | After first 100 users | | ⏳ |
| **21** | SMS Provider (2FA) | Enterprise tier launch | | ⏳ |
| **22** | Model Versioning System | After 3-5 model iterations | | ⏳ |
| **23** | Social Login (OAuth) | Phase 2 | | ⏳ |
| **24** | Multi-Region Strategy | After 1000+ users | | ⏳ |

---

## 📅 Recommended Decision Timeline

### Week 1: Critical Path (Nov 1-7)
- [ ] **Day 1**: Purchase domain name
- [ ] **Day 1**: Set up AWS account
- [ ] **Day 2**: Select payment processor (recommend: Stripe)
- [ ] **Day 2**: Approve API budget
- [ ] **Day 3**: Engage legal counsel for ToS/Privacy Policy
- [ ] **Day 4**: Procure API keys (lowest tiers to start)
- [ ] **Day 5**: Purchase historical ML training data

### Week 2: High Priority (Nov 8-14)
- [ ] **Mon**: Configure email service (SendGrid)
- [ ] **Mon**: Select blockchain node provider (Alchemy)
- [ ] **Tue**: Define blockchain support priority (start with 2-3)
- [ ] **Wed**: Document tier enforcement strategy
- [ ] **Thu**: Define free trial parameters
- [ ] **Fri**: Document downgrade flow logic

### Week 3: Medium Priority (Nov 15-21)
- [ ] **Mon**: Select monitoring stack
- [ ] **Mon**: Set up status page
- [ ] **Tue**: Choose design system
- [ ] **Wed**: Define mobile app timeline
- [ ] **Thu**: Finalize team structure and hiring plan
- [ ] **Fri**: Choose tax handling approach

### Week 4+: Low Priority (Nov 22+)
- [ ] Analytics platform (can use GA4 free initially)
- [ ] Customer support (can use email initially)
- [ ] Remaining items as needed

---

## 💰 Budget Summary

### One-Time Costs
| Item | Cost | Priority | Status |
|------|------|----------|--------|
| Domain name | $12 | 🔴 Critical | ⏳ |
| Legal documents | $1,000-$3,000 | 🔴 Critical | ⏳ |
| Historical ML data | $500-$2,000 | 🔴 Critical | ⏳ |
| **Total One-Time** | **$1,512-$5,012** | | |

### Monthly Recurring Costs
| Item | Cost | Priority | Status |
|------|------|----------|--------|
| AWS Infrastructure (dev) | $812 | 🔴 Critical | ⏳ |
| AWS Infrastructure (prod) | $2,500 | 🔴 Critical | ⏳ |
| External APIs | $1,500-$2,000 | 🔴 Critical | ⏳ |
| Payment processing | 2.9% + $0.30/txn | 🔴 Critical | ⏳ |
| Email (SendGrid) | $20 | 🟡 High | ⏳ |
| Blockchain nodes | $0-$200 | 🟡 High | ⏳ |
| Monitoring (New Relic/Datadog) | $200 | 🟢 Medium | ⏳ |
| Status page | $29 | 🟢 Medium | ⏳ |
| Error tracking (Sentry) | $26 | 🟢 Medium | ⏳ |
| **Total Monthly (dev)** | **~$2,587-$3,087** | | |
| **Total Monthly (prod)** | **~$4,275-$4,975** | | |

### Team Costs (Annual)
| Role | Quantity | Annual Cost | Priority |
|------|----------|-------------|----------|
| Backend Developer | 2-3 | $300K-$450K | 🔴 Critical |
| Frontend Developer | 1-2 | $150K-$300K | 🔴 Critical |
| ML Engineer | 1-2 | $150K-$300K | 🔴 Critical |
| DevOps/SRE | 1 | $150K-$200K | 🟡 High |
| QA Engineer | 0.5-1 | $75K-$150K | 🟢 Medium |
| **Total Team Costs** | **$825K-$1.4M/year** | | |

---

## 🎯 Quick Action Checklist

### Before First Code Commit
- [ ] AWS account created and configured
- [ ] Domain purchased and DNS configured
- [ ] Payment processor account created (Stripe)
- [ ] API keys obtained (at least free tiers)
- [ ] Legal counsel engaged

### Before Sprint 1 Ends
- [ ] All API keys upgraded to paid tiers
- [ ] Historical data purchased and loaded
- [ ] Email service configured (SendGrid)
- [ ] Blockchain node provider selected
- [ ] Tier enforcement logic documented

### Before MVP Launch
- [ ] Legal documents finalized (ToS, Privacy Policy)
- [ ] Monitoring and alerting configured
- [ ] Status page live
- [ ] Tax handling implemented
- [ ] Team fully hired and onboarded

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
