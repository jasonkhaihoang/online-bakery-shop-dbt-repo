# Online Bakery Shop — dbt Project Design

**Date:** 2026-02-23
**Status:** Implemented
**Warehouse:** SQLite (via dbt-sqlite community adapter)

---

## Overview

This document describes the design and architecture of the dbt analytics project for an online bakery shop. The project transforms raw transactional data (orders, products, customers) into clean, queryable analytics models optimized for sales reporting.

## Business Context

The bakery shop needs visibility into:
- Order volume and revenue trends (daily, by customer, by product)
- Product performance by category
- Order status distribution (completed vs. pending vs. cancelled)
- Customer purchasing behavior

The initial implementation loads data via dbt seeds (CSV files) to enable immediate development and testing without requiring a production data pipeline.

---

## Architecture

### Three-Layer Model

```
Seeds (CSV) → Staging → Intermediate → Marts (Sales Reporting)
```

| Layer | Folder | Materialization | Responsibility |
|---|---|---|---|
| Seeds | `seeds/` | Table | Raw CSV data — source of truth for development |
| Staging | `models/staging/` | View | 1:1 with source tables; cleans types, standardizes naming |
| Intermediate | `models/intermediate/` | View | Joins and enrichment; no aggregation |
| Marts | `models/marts/sales/` | Table | Business-ready facts and dimensions for reporting |

### Design Principles

1. **Staging is 1:1 with sources** — Every staging model maps directly to one source table. No joins, no aggregations. This makes debugging easy: if something is wrong, you know which layer to look at.

2. **Intermediate models handle joins** — Complex multi-table logic is isolated in the intermediate layer, keeping marts simple and readable.

3. **Marts are queryable by analysts** — Mart models are materialized as tables for query performance, with clear column names and business-friendly metrics.

4. **Seeds enable rapid iteration** — Using dbt seeds means the project is immediately runnable without an external data warehouse or ETL pipeline. The seed structure mirrors what production source tables would look like, making the eventual migration to `{{ source() }}` references trivial.

---

## Data Model

### Seeds (Raw Data)

#### `brz_customers`
| Column | Type | Description |
|---|---|---|
| customer_id | integer | Primary key |
| first_name | text | Customer first name |
| last_name | text | Customer last name |
| email | text | Email address (unique) |
| city | text | Customer city |
| created_at | text | Account creation date |

#### `brz_products`
| Column | Type | Description |
|---|---|---|
| product_id | integer | Primary key |
| product_name | text | Product display name |
| category | text | One of: bread, pastry, cake, cookie |
| price | real | Unit price |
| is_active | text | Boolean flag (true/false) |

#### `brz_orders`
| Column | Type | Description |
|---|---|---|
| order_id | integer | Primary key |
| customer_id | integer | FK to brz_customers |
| order_date | text | Date order was placed (YYYY-MM-DD) |
| status | text | One of: pending, completed, cancelled |
| total_amount | real | Order total |

#### `brz_order_items`
| Column | Type | Description |
|---|---|---|
| order_item_id | integer | Primary key |
| order_id | integer | FK to brz_orders |
| product_id | integer | FK to brz_products |
| quantity | integer | Units ordered |
| unit_price | real | Price at time of order |

### Staging Models

Each staging model:
- References seeds via `{{ ref('seed_name') }}`
- Casts all columns to their correct types (INTEGER, REAL, TEXT)
- Applies lightweight transformations: `lower()` on emails and categories, boolean normalization for `is_active`
- Computes `line_total = quantity * unit_price` in `stg_order_items`

### Intermediate Model

#### `int_orders_with_details`
The central join model. Joins:
- `stg_orders` (order header)
- `stg_order_items` (line items)
- `stg_products` (product details)
- `stg_customers` (customer details)

Produces one row per order line item with all context needed for mart aggregations. No metrics are computed here — this is a pure join/enrichment layer.

### Mart Models

#### `fct_orders` (Fact)
One row per order. Aggregates from `int_orders_with_details`.
- `item_count` = count of line items
- `total_revenue` = sum of `line_total`

**Use case:** Order-level analysis, customer order history, revenue by order.

#### `fct_daily_sales` (Fact)
One row per day. Aggregates from `fct_orders`.
- `total_orders` = all orders (any status)
- `completed_orders` = completed orders only
- `total_revenue` = revenue from completed orders
- `avg_order_value` = average completed order value

**Use case:** Daily sales dashboard, trend analysis, revenue reporting.

#### `dim_products` (Dimension)
One row per product. Sourced from `stg_products`.

**Use case:** Product catalog lookups, joins for ad-hoc product performance queries.

---

## Testing Strategy

Tests are defined in YAML schema files at each layer:

| Layer | Test File | Tests |
|---|---|---|
| Staging | `_stg_bakery.yml` | not_null + unique on all PKs; accepted_values on status and category |
| Intermediate | `_int_bakery.yml` | not_null on order_id; not_null + unique on order_item_id |
| Marts | `_marts_sales.yml` | not_null + unique on PKs; not_null on key metrics |

---

## SQLite Adapter Notes

- **Adapter:** `dbt-sqlite` (community adapter)
- **Database file:** `bakery.db` (created in project root)
- **Schema:** `main` (SQLite's default schema)
- **Limitations:**
  - SQLite does not support all SQL dialects (no `INITCAP()`, limited window functions)
  - Staging models use SQLite-compatible type casting: `cast(x as integer)`, `cast(x as real)`, `cast(x as text)`
  - Views are supported; marts use tables for query performance
- **Running with profiles.yml in project root:**
  ```bash
  dbt run --profiles-dir .
  dbt test --profiles-dir .
  ```

---

## Migration Path to Production

When a production warehouse (e.g., BigQuery, Snowflake, Postgres) is available:

1. Update `profiles.yml` with the production adapter configuration
2. Create a `models/staging/_sources.yml` source definition pointing to production tables
3. Update staging models to use `{{ source('bakery_raw', 'brz_customers') }}` instead of `{{ ref('brz_customers') }}`
4. Remove or archive seed files (or keep for testing)
5. All intermediate and mart logic remains unchanged — no modifications needed above the staging layer

---

## File Structure

```
online-bakery-shop-dbt-repo/
├── dbt_project.yml                         # Project name, model paths, materializations
├── profiles.yml                            # SQLite connection (project-local)
├── README.md                               # Project overview and quickstart
├── docs/
│   └── plans/
│       └── 2026-02-23-bakery-dbt-design.md # This document
├── seeds/
│   ├── _seeds.yml                          # Column type definitions for seeds
│   ├── brz_customers.csv                   # 20 customer records
│   ├── brz_orders.csv                      # 25 order records
│   ├── brz_order_items.csv                 # 45 order line items
│   └── brz_products.csv                    # 16 product records
└── models/
    ├── staging/
    │   ├── _sources.yml                    # Source table documentation
    │   ├── _stg_bakery.yml                 # Staging model docs + tests
    │   ├── stg_customers.sql
    │   ├── stg_orders.sql
    │   ├── stg_order_items.sql
    │   └── stg_products.sql
    ├── intermediate/
    │   ├── _int_bakery.yml                 # Intermediate model docs + tests
    │   └── int_orders_with_details.sql
    └── marts/
        └── sales/
            ├── _marts_sales.yml            # Mart model docs + tests
            ├── dim_products.sql
            ├── fct_daily_sales.sql
            └── fct_orders.sql
```
