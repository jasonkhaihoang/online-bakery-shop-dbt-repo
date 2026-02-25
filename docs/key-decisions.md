# Key Architecture Decisions: Online Bakery Shop dbt Project

> **Purpose:** This is the living architecture reference for the project. Consult and update it as the bakery dbt project evolves. Each decision captures the *why*, not just the *what* — so future engineers understand the reasoning, not just the outcome.

---

## Decision 1: Marts Domain Structure

**Question:** How many business domains do we need, and what are they?

**Decision:** Three mart domains.

```
models/marts/
├── sales/          ← orders, revenue, daily aggregates
├── customers/      ← customer analytics, CLV, segmentation
└── products/       ← product performance, category analysis
```

**Why it matters:** The mart domain structure drives all downstream decisions — which fact/dim tables to build, how to split intermediate models, and who the consumers of each mart are. Defining it upfront prevents the anti-pattern of stuffing everything into a single `sales/` folder.

**Status:** `sales/` exists. `customers/` and `products/` are planned.

---

## Decision 2: Grain of Each Fact Table

**Question:** What level of detail does each fact table capture?

**Decision:**

| Fact Table | Grain | Status | Notes |
|---|---|---|---|
| `fct_orders` | 1 row per order | ✅ exists | Order-level metrics |
| `fct_order_items` | 1 row per line item | ❌ planned | Required for product-mix analysis |
| `fct_daily_sales` | 1 row per day | ✅ exists | Aggregated from `fct_orders` |
| `fct_product_sales` | 1 row per product per day | ❌ potential | When product reporting matures |
| `fct_customer_orders` | 1 row per customer | ❌ potential | Alternative to `dim_customers` |

**Why it matters:** `fct_orders` collapses line-item detail. Without `fct_order_items`, you cannot answer: "which products sell together?", "revenue by product", or "average basket size by category." Get the grain wrong and no downstream query can recover it.

---

## Decision 3: Dimension Table Completeness

**Question:** Build the full dimension set now or incrementally?

**Decision:** Build incrementally, in this order of priority:

1. `dim_products` — ✅ exists
2. `dim_customers` — customer attributes + derived cohort fields (`first_order_date`, `city`, `total_orders`, `customer_segment`)
3. `dim_dates` — date spine for time-series joins (`day`, `week`, `month`, `quarter`, `is_weekend`)

**Why it matters:**
- Without `dim_dates`, you cannot report "sales on days with no orders" (calendar gaps). Every time-series chart has silent holes.
- Without `dim_customers`, customer segmentation requires staging joins in every downstream query — coupling marts to raw data.

**SQLite note:** `dim_dates` requires a recursive CTE date spine. There is no `generate_series()` in SQLite.

---

## Decision 4: Intermediate Layer Strategy

**Question:** One fat intermediate model or purpose-built intermediates per domain?

**Decision:** Split by domain as marts scale.

| Option | Description | When to use |
|---|---|---|
| **Option A — single wide join** (current) | `int_orders_with_details` joins all 4 staging models | Acceptable with one mart domain |
| **Option B — domain intermediates** (target) | Separate intermediates per mart domain | Required when adding a customers mart |

Target state:
- `int_orders_enriched` — orders + items + products (feeds `sales/`)
- `int_customers_enriched` — customers + order history aggregates (feeds `customers/`)

**Why it matters:** As marts scale, a single fat intermediate becomes a bottleneck and mixes concerns between domains. The `customers/` mart should not depend on an intermediate whose primary purpose is order-item joining.

---

## Decision 5: Materialization Strategy

**Question:** What materialization is appropriate at each layer?

**Decision (current — appropriate for seeds/SQLite):**

| Layer | Materialization | Rationale |
|---|---|---|
| `staging/` | `view` | Raw passthrough; no storage cost |
| `intermediate/` | `view` | Transformation logic; rebuilt on demand |
| `marts/` | `table` | Query performance for BI consumers |

**Future decisions (when data grows):**

- **Incremental models** — move `fct_orders` to `incremental` on `order_date` when order volume becomes large
- **Source freshness** — add `freshness:` blocks to `_sources.yml` when moving from seeds to real ingestion
- **Snapshots** — add `snapshots/` for SCD Type 2 if product prices or customer details change over time

---

## Decision 6: Naming Conventions

**Decision:** Lock in these prefixes across the project.

| Layer | Pattern | Example |
|---|---|---|
| Staging | `stg_<source>_<entity>` | `stg_bakery_orders` |
| Intermediate | `int_<entity>_<transformation>` | `int_customers_enriched` |
| Fact tables | `fct_<business_process>` | `fct_orders` |
| Dimensions | `dim_<entity>` | `dim_customers` |
| Seeds | `brz_<entity>` | `brz_orders` |

**Why it matters:** Consistent prefixes allow any engineer to understand a model's role and layer at a glance. They also make `dbt ls --select tag:` filters and documentation auto-grouping reliable.

---

## Decision 7: Testing Coverage Philosophy

**Question:** What layers of tests do we enforce, and at what point do tests block a `dbt run`?

**Decision:** Three tiers, enforced progressively.

| Tier | Type | Status |
|---|---|---|
| 1 | **Generic tests** — `not_null`, `unique`, `accepted_values` | ✅ exists |
| 2 | **Relationship tests** — FK integrity across models | ❌ missing |
| 3 | **Singular tests** — custom SQL for business logic assertions | ❌ missing |

**Principle:** Tests at Tier 2 and 3 should be part of CI. A missing FK relationship means silent data loss via LEFT JOINs. A broken business rule (e.g. cancelled order with revenue > 0) means incorrect dashboards.

---

## Decision 8: Data Quality Tests — What to Add

### What exists today
All tests are generic inline YAML: `not_null`, `unique`, `accepted_values`. No singular tests. No `tests/` folder. No relationship (FK) tests.

---

### 🔴 High priority — correctness gaps

| Gap | Where | Impact |
|---|---|---|
| No FK / relationship tests | `stg_order_items` → `stg_orders`, `stg_products`; `stg_orders` → `stg_customers` | Orphaned rows cause silent data loss via LEFT JOINs |
| Cancelled orders included in `fct_orders.total_revenue` | `fct_orders.sql` | Overstates revenue — inconsistent with `fct_daily_sales` which correctly excludes them |
| No `price > 0` / `quantity > 0` / `unit_price > 0` tests | `stg_products`, `stg_order_items` | Negative or zero values corrupt all downstream revenue metrics |
| No test that `line_total = quantity * unit_price` | `stg_order_items` | Calculation drift goes undetected |

---

### 🟡 Medium priority — consistency gaps

| Gap | Where | Impact |
|---|---|---|
| No test that `sum(line_total)` = `orders.total_amount` per order | `stg_orders` vs `stg_order_items` | Header and detail totals can silently diverge |
| No test that `order_date >= customer.created_at` | `stg_orders` | Orders placed before account creation is logically impossible |
| Pending orders in `fct_orders.total_revenue` — intentional? | `fct_orders.sql` | Undocumented assumption; should pending revenue count? |
| `avg_order_value` in `fct_daily_sales` has no `not_null` test | `_marts_sales.yml` | NULL on days with 0 completed orders is correct but undocumented |

---

### 🟢 Low priority — edge cases

| Gap | Where | Impact |
|---|---|---|
| No guard blocking inactive products from order items | `stg_order_items` | Product #16 is inactive; no guard if it gets ordered |
| No email format validation | `stg_customers` | Invalid emails pass silently |
| No `order_date` range check | `stg_orders` | Future-dated orders pass silently |

---

### Recommended tests to add

**1. Relationship (FK) tests** — add to `_stg_bakery.yml` (built-in dbt, no package needed):

```yaml
# stg_order_items
- order_id:
    tests:
      - relationships:
          to: ref('stg_orders')
          field: order_id
- product_id:
    tests:
      - relationships:
          to: ref('stg_products')
          field: product_id

# stg_orders
- customer_id:
    tests:
      - relationships:
          to: ref('stg_customers')
          field: customer_id
```

**2. Positive value tests** — requires `dbt-utils`:

```yaml
- price:
    tests:
      - dbt_utils.expression_is_true:
          expression: "price > 0"
- quantity:
    tests:
      - dbt_utils.expression_is_true:
          expression: "quantity > 0"
- unit_price:
    tests:
      - dbt_utils.expression_is_true:
          expression: "unit_price > 0"
```

**3. Singular tests** — new `tests/` folder:

```sql
-- tests/assert_line_total_matches_calculation.sql
select order_item_id
from {{ ref('stg_order_items') }}
where abs(line_total - (quantity * unit_price)) > 0.01
```

```sql
-- tests/assert_cancelled_orders_zero_revenue.sql
select order_id
from {{ ref('fct_orders') }}
where status = 'cancelled' and total_revenue > 0
```

**4. Package to add** — `packages.yml`:

```yaml
packages:
  - package: dbt-labs/dbt_utils
    version: [">=1.0.0"]
```

---

## Implementation Priority

When you are ready to act on these decisions, work in this order:

1. **Decide mart domains** (Decision 1 — drives everything else)
2. **Decide fact table grains** (Decision 2 — determines intermediate models needed)
3. **Add relationship tests + fix cancelled order revenue bug** (Decision 8 🔴 — correctness first)
4. **Add `dim_customers` and `dim_dates`** (Decision 3 — unlocks most analytics use cases)
5. **Split intermediate layer** if adding a customers mart (Decision 4)
6. **Add positive value + singular tests** (Decision 8 🟡)
7. **Document naming conventions** in `CONTRIBUTING.md` (Decision 6)
8. **Decide materialization / incremental strategy** (Decision 5 — when data grows)
