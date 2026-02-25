# What a dbt Analytics Engineer Analyses & Designs at Project Start

## Context

This is a reference framework — not tied to any specific codebase. It maps the full scope of analysis and design a dbt analytics engineer works through when starting a new project, from business context through to operations. The goal is also to identify which Claude Code skills support each area.

---

## Area 1: Business Context & Stakeholder Mapping

What to analyse:
- What does the business do, and what are its core processes?
- What business questions must the data answer? (KPIs, OKRs)
- Who consumes the data? (BI analysts, data scientists, executives, ops teams)
- What are the data products? (dashboards, reports, ML features, reverse ETL)
- What are the freshness and latency SLAs?
- What decisions will the data directly drive?

Why it matters: Everything downstream — domains, grains, freshness — flows from here. Building models without this produces technically correct tables nobody uses.

---

## Area 2: Source System Inventory

What to analyse:
- What raw data sources exist? (transactional DBs, SaaS tools, event streams, spreadsheets)
- How is data ingested? (Fivetran, Airbyte, custom ETL, seeds, Kafka)
- What is the data volume, velocity, and update frequency per source?
- What are the source schemas, data types, and nullability?
- Are there known data quality issues in the sources? (duplicates, nulls, truncation)
- What is the source entity model? (identify primary keys and relationships)
- Which source tables are safe to use vs. which require caution?

Why it matters: Source quality and volume determines every technical decision — materialization, incremental strategy, test coverage, and where to place cleaning logic.

---

## Area 3: Layer Architecture Design

What to design:
- How many layers? (typically: staging → intermediate → marts)
- What belongs in staging? (1:1 with source, rename + cast only, no business logic)
- What belongs in intermediate? (cross-source joins, pre-aggregations, domain prep)
- What belongs in marts? (business-facing fact and dim tables)
- Are ephemeral models appropriate anywhere? (inline CTEs vs materialised intermediate)
- Should there be a `base/` layer beneath staging for very raw sources?

Why it matters: Layer violations — business logic in staging, raw joins in marts — are the most common cause of dbt project technical debt. Establish the contract for each layer before writing any SQL.

---

## Area 4: Mart Domain Structure

What to design:
- What are the business domains? (sales, customers, products, finance, marketing, ops)
- Who owns each domain? (one team per mart folder)
- What is the directory structure under `models/marts/`?
- Which domains are in scope for v1 vs. later?

Example:
```
models/marts/
├── sales/
├── customers/
├── products/
└── finance/
```

Why it matters: Domain structure drives all downstream decisions — which fact/dim tables to build, how to split intermediates, and team ownership. Hard to refactor once downstream consumers exist.

---

## Area 5: Fact Table Design

What to design per fact table:
- What is the business process being measured? (orders, payments, sessions, shipments)
- What is the grain? (1 row per order? per line item? per day?)
- What measures belong on this fact? (revenue, quantity, count)
- What foreign keys link to dimensions?
- Does this fact need multiple grains? (order-level AND line-item-level)
- What is the date/time key?
- Which statuses should be included vs. excluded from measures?

Common grains to evaluate:

| Process | Candidate grains |
|---|---|
| Orders | per order, per line item, per day |
| Web sessions | per session, per page view, per day |
| Payments | per transaction, per customer per month |
| Inventory | per SKU per day |

Why it matters: Getting the grain wrong cannot be fixed downstream. Too coarse = lost analytical capability. Too fine = performance and complexity problems.

---

## Area 6: Dimension Table Design

What to design per dimension:
- What entities need dimension tables? (customers, products, employees, locations, dates)
- What attributes belong on each dimension?
- Which attributes are derived vs. source? (e.g. `customer_segment` derived from `total_orders`)
- Do any dimensions change over time? → SCD Type 2 (snapshots)
- Is a date spine needed? (`dim_dates`)
- What is the primary key for each dimension?

SCD decision:

| Dimension | Changes over time? | Strategy |
|---|---|---|
| `dim_customers` | Email, address can change | SCD Type 1 (overwrite) or Type 2 (snapshot) |
| `dim_products` | Price can change | Snapshot if historical price matters |
| `dim_dates` | Never changes | Static table or recursive CTE |

Why it matters: Missing `dim_dates` = no gap-safe time series. Missing `dim_customers` = customer segmentation requires staging joins in every mart query.

---

## Area 7: Intermediate Model Strategy

What to design:
- Should intermediates be wide joins (one per domain) or narrow purpose-built models?
- What pre-aggregations are shared across multiple marts?
- Which intermediates should be views vs. tables?
- How should intermediates be named? (`int_<entity>_<transformation>`)
- Are any intermediates ephemeral (pure CTE with no materialisation)?

Why it matters: A single fat intermediate that joins everything becomes a bottleneck and mixes domain concerns as the project grows. Purpose-built intermediates per domain scale better.

---

## Area 8: Naming Conventions

What to lock in before writing any code:
- Staging: `stg_<source>_<entity>`
- Intermediate: `int_<entity>_<transformation>`
- Fact tables: `fct_<business_process>`
- Dimensions: `dim_<entity>`
- Seeds: `raw_<entity>`
- Snapshots: `<entity>_snapshot`
- Metrics: `mtr_<metric_name>` (if using dbt metrics)

Additional conventions:
- Boolean columns: `is_<state>` or `has_<attribute>`
- Date columns: `<event>_date` or `<event>_at`
- Amount columns: `<metric>_amount` or `<metric>_revenue`
- Count columns: `<entity>_count` or `total_<entity>s`

Why it matters: Consistent naming is the cheapest form of documentation. Engineers unfamiliar with the project can understand a model's role and layer from its name alone.

---

## Area 9: Testing Strategy

What to design:
- What generic tests are mandatory at staging? (not_null, unique on PKs, accepted_values on enums)
- What relationship/FK tests are needed? (referential integrity across models)
- What singular (custom SQL) tests are needed? (business logic assertions)
- What test severity levels? (error blocks run; warn surfaces but continues)
- What packages are needed? (dbt-utils, dbt-expectations)
- Which tests run in CI vs. full runs?

Test tier framework:

| Tier | Type | Layer | Blocks CI? |
|---|---|---|---|
| 1 | Generic: not_null, unique, accepted_values | Staging | Yes |
| 2 | Relationship (FK integrity) | Staging | Yes |
| 3 | Positive value / range checks | Staging | Yes |
| 4 | Business logic assertions (singular) | Marts | Yes |
| 5 | Source freshness | Sources | Warn |

Why it matters: Tests are the only thing preventing silent data corruption. Without FK tests, orphaned rows cause invisible revenue drops. Without singular tests, a bug like "cancelled orders included in revenue" ships to production.

---

## Area 10: Materialisation Strategy

What to decide per model:
- Staging → views (passthrough, no storage cost)
- Intermediate → views (rebuilt on demand)
- Marts → tables (query performance for BI)
- Large fact tables → incremental (when do you switch, and on what key?)
- Slowly changing dimensions → snapshots (`dbt snapshot`)

Incremental model decisions:
- What is the `unique_key`?
- What is the `incremental_strategy`? (append, merge, delete+insert)
- What is the `partition_by` or `cluster_by` column?
- How far back does a late-arriving data backfill go?

Why it matters: Wrong materialisations cause either performance problems (everything is a view) or storage/freshness problems (everything is a table with full refresh).

---

## Area 11: Source Configuration & Freshness

What to configure:
- Define all sources in `_sources.yml` with descriptions
- Set `freshness:` thresholds per source table (warn_after, error_after)
- Set `loaded_at_field` for freshness checks
- Document source contact/owner for incident response
- Identify which sources are critical path vs. supplemental

Why it matters: Without source freshness checks, a broken ingestion pipeline produces stale dashboards with no alert. Engineers discover it when a stakeholder complains, not when the pipeline breaks.

---

## Area 12: Documentation Standards

What to establish:
- Which models require descriptions? (all marts, all staging — enforced via CI)
- Which columns require descriptions? (all PKs, FKs, and measure columns)
- Where do business definitions live? (dbt docs vs. external wiki)
- Is `dbt docs generate` part of the CI/CD pipeline?
- How is the lineage graph published and shared?

Why it matters: Undocumented models become "dark data" — engineers avoid touching them because they don't understand what they do. This compounds over time.

---

## Area 13: Development Workflow & CI/CD

What to design:
- Git branching strategy (feature branches off `main`, PR required)
- What checks run in CI? (`dbt build --select state:modified+`)
- Slim CI: defer to production state to avoid rebuilding unchanged models
- PR review requirements (who approves model changes? YAML changes?)
- `CONTRIBUTING.md` contents

CI pipeline stages:
1. `dbt deps` — install packages
2. `dbt build --select state:modified+ --defer --state ./prod-artifacts` — slim CI
3. `dbt test --select state:modified+` — run tests on changed models
4. `dbt docs generate` — refresh docs on merge

Why it matters: Without CI, broken SQL ships to production. Without slim CI, every PR rebuilds the entire project — which is expensive and slow at scale.

---

## Area 14: Orchestration & Operations

What to design:
- What orchestrates dbt runs? (dbt Cloud, Airflow, Dagster, Prefect, GitHub Actions)
- What is the run cadence per job? (hourly, daily, event-driven)
- Full refresh vs. incremental run strategy
- What triggers a full refresh? (schema changes, backfill requests)
- Alert setup: who is notified when a run fails or a test errors?
- Incident runbook: what do you do when the morning run fails?

Why it matters: A well-designed dbt project with no operational plan means engineers are manually running `dbt run` in production. Orchestration is the difference between a project and a product.

---

## Area 15: Governance & Security

What to decide:
- Which columns contain PII? (name, email, address, phone)
- How is PII masked or excluded in downstream models?
- Who has SELECT access to raw vs. staging vs. marts?
- Are row-level security policies needed?
- What is the data retention policy per table?
- Are any models subject to compliance? (GDPR, HIPAA, SOC 2)

Why it matters: A single unmasked PII column in a widely-shared mart can create legal and reputational exposure. This is far cheaper to design in than to retrofit.

---

## Summary: 15 Areas, mapped to Claude Code skills

| Area | Claude Code Skill |
|---|---|
| 1. Business context | `brainstorming` |
| 2. Source system inventory | `brainstorming`, `writing-plans` |
| 3. Layer architecture | `brainstorming`, `writing-plans` |
| 4. Mart domain structure | `brainstorming`, `writing-plans` |
| 5. Fact table design | `brainstorming`, `test-driven-development` |
| 6. Dimension table design | `brainstorming`, `writing-plans` |
| 7. Intermediate model strategy | `brainstorming`, `dispatching-parallel-agents` |
| 8. Naming conventions | `writing-plans` |
| 9. Testing strategy | `test-driven-development`, `verification-before-completion` |
| 10. Materialisation strategy | `systematic-debugging`, `verification-before-completion` |
| 11. Source freshness | `writing-plans`, `systematic-debugging` |
| 12. Documentation standards | `writing-plans` |
| 13. Development workflow & CI/CD | `using-git-worktrees`, `requesting-code-review`, `finishing-a-development-branch` |
| 14. Orchestration & operations | `writing-plans`, `executing-plans` |
| 15. Governance & security | `brainstorming`, `writing-plans` |

Cross-cutting (all areas):
- `using-git-worktrees` — work in isolation for any implementation
- `receiving-code-review` — handle feedback rigorously
- `finishing-a-development-branch` — complete each area with merge/PR decision
