# Online Bakery Shop — dbt Analytics Project

A dbt project that transforms raw transactional data for an online bakery shop into clean, queryable analytics models for sales reporting.

## Architecture

```
Seeds (CSV) → Staging → Intermediate → Marts (Sales Reporting)
```

### Layers

| Layer | Materialization | Purpose |
|---|---|---|
| **Staging** | View | Clean and type-cast raw seed data (1:1 with sources) |
| **Intermediate** | View | Join and enrich data across entities |
| **Marts** | Table | Business-ready aggregated metrics for reporting |

## Project Structure

```
online-bakery-shop-dbt-repo/
├── dbt_project.yml          # Project config
├── profiles.yml             # SQLite connection profile
├── seeds/                   # Raw CSV data
│   ├── raw_customers.csv
│   ├── raw_orders.csv
│   ├── raw_order_items.csv
│   └── raw_products.csv
└── models/
    ├── staging/             # Clean, typed staging models
    ├── intermediate/        # Enriched join models
    └── marts/sales/         # Sales reporting fact & dimension tables
```

## Models

### Staging
- `stg_customers` — cleaned customer records
- `stg_products` — cleaned product catalog
- `stg_orders` — cleaned order headers
- `stg_order_items` — cleaned line items with calculated `line_total`

### Intermediate
- `int_orders_with_details` — one row per order line item, enriched with product and customer info

### Marts (Sales)
- `fct_orders` — one row per order with aggregated revenue metrics
- `fct_daily_sales` — daily sales aggregation (orders, revenue, avg order value)
- `dim_products` — clean product dimension table

## Getting Started

### Prerequisites

```bash
pip install dbt-core dbt-sqlite
```

### Run the Project

```bash
# Verify configuration
dbt debug --profiles-dir .

# Load seed data
dbt seed --profiles-dir .

# Run all models
dbt run --profiles-dir .

# Run tests
dbt test --profiles-dir .

# Generate documentation
dbt docs generate --profiles-dir .
dbt docs serve --profiles-dir .
```

## Warehouse

Target: **SQLite** via the `dbt-sqlite` community adapter. The database file `bakery.db` is created in the project root directory.
