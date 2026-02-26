---
name: scaffolding-dbt-repos
description: Use when scaffolding a new dbt data domain repo, placing a new model in the correct layer, checking naming or DAG compliance, or referencing project config templates and linting rules.
---

## Overview

One dbt project per data domain, each in its own GitHub repo and Fabric workspace (1:1 mapping).

| Layer | Alias | Folder | Purpose |
| --- | --- | --- | --- |
| **Staging** | — | `models/staging/{source}/` | dbt entry point. Cast, rename, passthrough only — no derived columns, no boolean flags, no computed metrics. One model per source table. Consumes bronze via `source()`. |
| **Intermediate** | Silver | `models/intermediate/{concept}/` | Core business logic, cross-source joins. Materialized as incremental (merge strategy). Each model declares its own `unique_key` in a `{{ config() }}` block. |
| **Mart** | Gold | `models/marts/{consumer_area}/` | Consumer-ready fct/dim. Contracted, SLA-bound. |

> **Note:** Bronze tables are managed outside dbt. Staging is the dbt entry point — it references bronze via `source()`, not `ref()`.

> **Rule of thumb:** "Would a second consumer need this same logic?" **Yes** → Intermediate. **No** → Mart.

## Naming Conventions

| Layer | Pattern | Example |
| --- | --- | --- |
| Staging | `stg_{source}__{entity}.sql` | `stg_salesforce__account.sql` |
| Intermediate | `int_{concept}__{descriptor}.sql` | `int_customers__unified.sql`, `int_orders__completed.sql`, `int_customers__order_history.sql` |
| Mart (fact) | `fct_{entity}.sql` | `fct_revenue.sql` |
| Mart (dim) | `dim_{entity}.sql` | `dim_customer.sql` |
| YAML schemas | `_{layer}_{source_or_area}.yml` | `_stg_salesforce.yml` |
| Sources | `_source.yml` | `_source.yml` |

- **snake_case** everywhere. **Double underscore** `__` separates source/concept from entity/descriptor.
- Intermediate descriptor can be a verb, past participle, or noun phrase — pick what best describes the transformation (e.g. `completed`, `unified`, `order_history`).

## DAG Enforcement (machine-readable)

1. `stg_*` → ONLY `source()` to reference bronze tables, never `ref()`
2. `int_*` → ONLY `ref()` to `stg_*` or `int_*`
3. `fct_*` / `dim_*` → ONLY `ref()` to `int_*` or `stg_*`
4. **No backwards refs.** No cross-domain refs (use dbt mesh for that).

## Project Context Files

Before scaffolding, read these files from the repo root if they exist:

| File | Contains | When to use |
| --- | --- | --- |
| `domain.md` | Project domain, business intent, key entities | Bootstrapping a new project, choosing mart consumer areas, or making naming decisions |
| `source.md` | Available bronze sources and their fields, derived from seeds | Creating or updating `_source.yml`, adding staging models |

These files are project-specific and maintained by the repo owner — not created by this skill. If they don't exist, ask the user before proceeding.

**Mart scope is set by `domain.md`.**  The `Mart consumer areas` table in `domain.md` lists the exact folders to create under `models/marts/`. Do not create mart folders or models beyond what is listed there.

**Bronze: seeds vs `_source.yml`.**  Seeds (CSV files in `seeds/`) load the bronze data into the database. `_source.yml` (inside `models/staging/{source}/`) declares those same tables so dbt's `source()` function can reference them. They must stay in sync — `_source.yml` should declare exactly the tables listed in `source.md`, no more, no fewer.

## Reference Files

**Conventions** → `repo_conventions.md` — full folder tree, business logic placement, meta keys, and YAML co-file requirements.

**Config templates:**
- `dbt_project.template.yml` — project config template with layer materializations and meta defaults
- `sqlfluff.template.cfg` — linting rules (postgres dialect; switch to sparksql for Fabric targets)
- `generate_schema_name.template.sql` — schema isolation macro + env mapping table

**Examples & templates:**
- `model_examples.md` — staging, intermediate, and mart model examples
- `schema_contracts.md` — Gold-tier YAML with enforced contracts
- `model.template.sql` — starter skeleton for new models
