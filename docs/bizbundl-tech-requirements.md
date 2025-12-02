# BizBundl - Technical & Product Requirements Documentation

## 1. Product Overview

**Product Name:** BizBundl  
**Target Market:** Bangladesh (Primary focus: digital product creators, course sellers, digital service providers)  
**Business Model:** SaaS - Single Vendor E-Commerce Platform (single digital product only at MVP)  
**Positioning:** The only Bangladesh e-commerce platform with built-in Meta CAPI tracking + compliant payment processing + aggressive caching for maximum speed

---

## 2. MVP Features & Technical Stack

### 2.1 Core Product Features

#### Phase 1: Single Digital Product (MVP)
- **Product Upload:** Upload single digital product (course, ebook, software, templates, etc.)
- **Product Display:** Customizable product page with descriptions, pricing, demos
- **Digital Delivery:** Automated download link delivery post-purchase
- **Purchase Counter:** Real-time sales tracking dashboard
- **Basic Analytics:** Simple sales graph, customer count, revenue
- **SSL Commerz Integration:** Payment gateway pre-configured (merchant brings own credentials)
- **Built-in Meta CAPI:** Server-side conversion tracking (automatic setup, no extra configuration)
- **Email Notifications:** Order confirmation emails (not transactional)

#### Phase 2 (Future): Multi-Product Support
- Multiple products per store
- Product categories & organization
- Bundle pricing

#### Phase 3 (Future): Physical Products
- Inventory management
- Product variations (size, color, etc.)
- Shipping integration (Steadfast, Pathao)
- Multi-variant support

### 2.2 Technical Stack

| Component | Technology | Justification |
|---|---|---|
| **Backend** | Go Fiber | Minimal CPU/RAM, perfect for multi-tenant Docker containers |
| **Frontend** | ah-templ + HTMX + Alpine JS/GSAP | Server-side rendering, minimal JS, fast interactions |
| **Styling** | Tailwind CSS | Rapid UI development, small bundle size |
| **Database** | PostgreSQL (Centralized) | Single shared DB for all tenants (cost-efficient) |
| **Hosting** | Docker Compose on VPS | Dokploy orchestration, ৳6,708/month for 200+ customers |
| **CDN/Caching** | Cloudflare (Free tier) | 1-year product page cache, aggressive edge caching |
| **Tracking** | Meta CAPI (server-side custom endpoint) | Bypass ad blockers, iOS policies, 80-90% event capture |
| **Payment Gateway** | SSL Commerz | Compliant merchant accounts, 2.5% + ৳15/transaction |
| **Analytics** | Custom dashboard (Go backend) | Basic revenue/sales reporting |

---

## 3. Architecture Details

### 3.1 Multi-Tenant Docker Architecture

```
VPS (128GB RAM, 12 cores, 2x1.92TB SSD) - ৳6,708/month
├── Docker Daemon (Dokploy managed)
│   ├── Customer A Site Container (Go Fiber + ahtempl)
│   ├── Customer B Site Container (Go Fiber + ahtempl)
│   ├── Customer C Site Container (Go Fiber + ahtempl)
│   └── ... up to 200 containers on single VPS with caching
├── PostgreSQL Instance (single shared DB with tenant isolation)
├── Reverse Proxy (Nginx - routes subdomains to containers)
└── Cloudflare (DNS + aggressive caching layer on top)

Each container:
- 0.25 CPU cores (reserved)
- 50MB RAM (at rest)
- 0.5GB disk (app code + logs)
- Most traffic served from Cloudflare cache (93%)
```

### 3.2 Caching Strategy

**Cloudflare Cache Rules:**
- **Product pages:** Cache for 1 year (content rarely changes)
- **Product images:** Cache for 1 year
- **Static assets (CSS/JS):** Cache for 30 days
- **Checkout page:** Bypass cache (per-session)
- **API endpoints:** Bypass cache (dynamic)
- **CAPI event endpoint:** Bypass cache (real-time)

**Result:** ~93% of traffic served from Cloudflare edge, only checkout/events/tracking hit origin server.

### 3.3 Server-Side Tracking (Meta CAPI)

```
Customer's Site (ahtempl/HTMX)
    ↓ (purchase event)
BizBundl Go endpoint: /track/event
    ↓ (hash user data: email, phone)
Meta CAPI API
    ↓
Meta Ads Manager (conversion recorded)

Custom tracking domain: metrics.bizbundl.com
- Appears as infrastructure, not third-party tracking
- Bypasses ad blockers (not on blocklist)
- Avoids iOS ATT popup restrictions
```

### 3.4 Database Schema (Multi-Tenant & Multi-Store)

**Hierarchy:** `Tenant` (Paying Entity) -> `Stores` (Shopfronts) -> `Products/Orders`

```sql
tenants table:
  - id (UUID)
  - name (Business Name)
  - billing_info

stores table:
  - id (UUID)
  - tenant_id (FK)
  - name
  - custom_domain
  - settings (JSONB)

users table:
  - id (UUID)
  - email
  - password_hash
  - is_saas_admin (boolean)

roles table:
  - id (UUID)
  - name (e.g., "Store Admin", "Logistics")
  - scope (ENUM: 'saas', 'store')
  - is_template (boolean) -- For exportable templates
  - permissions (JSONB) -- Granular access: {"product": ["read", "write"], "order": ["read"]}

user_store_roles table:
  - user_id (FK)
  - store_id (FK)
  - role_id (FK)

products table:
  - id
  - store_id (FK - Data Isolation Level)
  - ... (rest of product fields)
```

### 3.5 Role-Based Access Control (RBAC)

**Core Principles:**
1.  **Separation of Concerns:** SaaS Roles (Super Admin, Marketing) vs. Store Roles (Logistics, Content Editor).
2.  **Granularity:** Permissions defined at the resource level (See, Write, Update).
3.  **Flexibility:**
    *   Users can hold different roles in different stores.
    *   **Permission Templates:** Exportable/Importable JSON definitions for roles to quickly setup new stores.

### 3.6 Frontend Asset Architecture (The "Elementor" Engine)

**1. CSS Isolation & Generation (Generated CSS)**
To support Hover states, Media Queries, and Store Isolation without bloat:
*   **No Global Styles:** Each store has a unique `store-{id}.css` file.
*   **Compiler:** When a user saves a design, the Go backend parses the JSON blocks and generates a static CSS file containing *only* the used styles.
    *   *Example:* User sets "Hover: Red". Backend generates `.block-123:hover { color: red; }`.
*   **Serving:** These CSS files are stored on S3/Disk and served via Cloudflare with long cache TTL.

**2. JavaScript Module Manager**
*   **Core:** Alpine.js (Always On).
*   **Optional Modules:** Users can toggle "GSAP", "Alpine Intersect", "Alpine Persist" in Store Settings.
*   **Loader:** The frontend template checks `store.settings.modules` and conditionally loads the scripts.

**3. Custom Code Injection**
*   **Locations:** `<head>`, `<body>` end.
*   **Storage:** Stored in `stores` table (`custom_code_head`, `custom_code_body`).
*   **Safety:** Sandboxed or validated to prevent breaking the editor (though risky by nature).


---

## 4. Key Differentiators

### 4.1 Meta CAPI Built-In
- **Problem it solves:** 40-50% of conversions lost due to iOS policies + ad blockers
- **Solution:** Server-side tracking reduces attribution loss to 10-20%
- **Benefit for customers:** Accurate ROI tracking on Facebook ads

### 4.2 SSL Commerz Integration
- **Problem:** Most platforms don't integrate payments—merchants confused
- **Solution:** Payment flow pre-configured, secure credential storage
- **Benefit:** Frictionless checkout

### 4.3 Aggressive Performance
- **Problem:** Slow platforms lose 30% of customers (each 100ms delay = 1% conversion loss)
- **Solution:** Go + ahtempl + aggressive Cloudflare caching = <200ms load time
- **Benefit:** Higher conversion rates for customers

### 4.4 Bangladesh-First
- **Problem:** International platforms don't understand local market (MFS, language, content)
- **Solution:** Built for Bangladesh digital product creators
- **Benefit:** Better product-market fit

---

## 5. Non-Functional Requirements

| Requirement | Target | How |
|---|---|---|
| **Performance** | <200ms page load | Go Fiber + ahtempl + Cloudflare cache |
| **Uptime** | 99.5% | VPS reliability, simple architecture |
| **Security** | HTTPS, encrypted credentials | SSL certificates, encrypted DB fields |
| **Data Isolation** | Tenant data 100% isolated | DB-level row security + tenant_id filtering |
| **Scalability** | 200+ customers per VPS | Container limits + aggressive caching |
| **Compliance** | GDPR/CCPA ready | Privacy policy, data deletion flows |

---

## 6. Roadmap Phases

### Phase 1 (MVP - Launch): Single Digital Product
**Timeline:** 4-6 weeks
- Product upload & display
- SSL Commerz payments
- Meta CAPI tracking
- Basic dashboard
- Email notifications

### Phase 2 (8-12 weeks in): Multi-Product
**Timeline:** After 50+ paying customers
- Multiple products per store
- Categories
- Product analytics (per-product sales)

### Phase 3 (6+ months): Physical Products
**Timeline:** After 200+ paying customers
- Inventory management
- Shipping integrations (Steadfast, Pathao)
- Product variations
- Return management

---

## 7. Metrics to Track

| Metric | Why | Target |
|---|---|---|
| **CAPI Event Capture Rate** | Validates tracking quality | >80% of transactions captured |
| **Page Load Time** | User experience | <200ms median |
| **SSL Commerz Approval Rate** | Merchant onboarding friction | >95% approved within 24h |
| **Checkout Completion Rate** | Conversion funnel | >70% of carts → orders |
| **Daily Active Users** | Product engagement | Benchmark: 20-30% of signups |

---

## 8. Technical Constraints & Considerations

- **Multi-tenancy:** All data in single PostgreSQL—must have bulletproof tenant isolation (SQL injection catastrophic)
- **Docker Container Limits:** 200 containers is aggressive—monitor CPU/memory closely in production
- **Cloudflare Cache Invalidation:** Product edits must trigger cache purge (API call to Cloudflare)
- **SSL Commerz Credentials:** Must be encrypted at rest, decrypted only when needed
- **CAPI Event Deduplication:** Server-side + client-side tracking can double-count—need dedup logic
- **Database Backups:** Single shared DB—automated daily backups critical
