---
name: scaffolding-dbt-project-v2
description: >
  Use when setting up a new Microsoft Fabric dbt project from scratch, or performing a major
  structural refactor (layer boundaries, naming, Fabric connection config). No models are created
  here. All Phase 2 skills depend on the artefacts this skill produces.
allowed-tools:
  - Read
---

# scaffolding-dbt-project-v2

## Overview

Phase 1 — Project Provisioning. Business-agnostic. Run once per project (or when big refactoring occurs).

Produces a fully scaffolded dbt project structure with no models — only standards, configs, and conventions.

**Phase 1 file ownership — hard rule**

Phase 1 exclusively owns the following files. Phase 2 must never modify them:
- `dbt_project.yml` — layer configs, materialization defaults, tag/meta defaults
- `profiles.yml` — connection targets (dev/prod)
- `.sqlfluff`, `packages.yml`
- `project_standards.md`

Phase 2 may only:
- Create new files under `models/`, `tests/`, `seeds/`, `macros/`
- Add `schema.yml` entries for new models
- Create or update domain-specific docs under `docs/`

If a business intent requires changes to Phase 1 files, **stop and escalate** — this is a refactoring decision, not an implementation decision.

---

## What This Skill Decides (Fixed — No User Input Required)

### Layers & Folders

```
source (bronze) ⇒ staging (models/staging/{source}/)
               ⇒ intermediate/silver (models/intermediate/{concept}/)
               ⇒ mart/gold (models/marts/{consumer_area}/)
```

### Bronze Ownership

- Bronze is managed outside dbt (by DLT); dbt never touches it
- Staging is the dbt entry point — references bronze via `source()`, not `ref()`
- Seeds (`seeds/`) load bronze data; `_source.yml` declares those same tables for `source()` — they must stay in sync

### Naming Conventions (snake_case, double `__` separator)

| Layer | Pattern | Example |
|-------|---------|---------|
| Staging | `stg_{source}__{entity}.sql` | `stg_salesforce__account.sql` |
| Intermediate | `int_{concept}__{descriptor}.sql` | `int_orders__completed.sql` |
| Mart (fact) | `fct_{entity}.sql` | `fct_revenue.sql` |
| Mart (dim) | `dim_{entity}.sql` | `dim_customer.sql` |
| YAML co-files | `_{layer}_{source_or_area}.yml` | `_stg_salesforce.yml` |
| Sources file | `_source.yml` | `_source.yml` |

- One YAML co-file per folder — not one per model

### DAG Rules (Enforced)

1. `stg_*` → ONLY `source()` — never `ref()`
2. `int_*` → ONLY `ref()` to `stg_*` or `int_*`
3. `fct_*` / `dim_*` → ONLY `ref()` to `int_*` or `stg_*`
4. No backwards refs; no cross-domain refs

### Testing Baseline Per Layer

| Layer | Required tests |
|-------|---------------|
| Staging | `unique` + `not_null` on PK column |
| Intermediate | `unique` + `not_null` on `unique_key` |
| Mart | `unique` + `not_null` on PK; `not_null` on all contracted columns |

- Approved test package: `dbt_utils` only — no additional test packages

### Materialization Defaults Per Layer

| Layer | Materialization | Notes |
|-------|----------------|-------|
| Staging | `view` | Passthrough only; no storage cost, always fresh |
| Intermediate | `incremental` + `incremental_strategy: merge` | Declared in `dbt_project.yml` |
| Mart | `table` | Consumer-ready; predictable query performance |

- Setting intermediate to `table` is a **hard violation**

### Fabric Connection

- Adapter: `dbt-fabric` (ODBC) — not dbt-spark or dbt-synapse
- One SQL Analytics Endpoint per lakehouse (Bronze / Silver / Gold)
- Endpoint URL format: `{workspace}.datawarehouse.fabric.microsoft.com`
- Service principal auth (`client_id`, `client_secret`, `tenant_id`) for CI/prod
- Entra ID interactive auth (`authentication: CLI`) for local dev
- **Bronze endpoint is read-only** — declared in `_source.yml` only, never a dbt write target
- **Silver endpoint** is the write target for staging + intermediate models
- **Gold endpoint** (= Mart endpoint) is the write target for mart models — same pattern as Silver but for the Gold lakehouse; must appear as a named target in `profiles.yml`
- `profiles.yml` must define at minimum: `dev` (Silver, interactive), `prod_silver` (Silver, SP), `prod_gold` (Gold, SP)
- SQLFluff dialect: **`sparksql` is the default** (Fabric Lakehouse SQL endpoint). Only switch to `tsql` when the user explicitly confirms they are using a Fabric Warehouse endpoint.

---

## Interview Flow (User Input Required)

Walk through one topic at a time. After all topics, show a summary for user confirmation before generating any artefacts.

### Topic 1 — Bronze Ownership

> List the bronze source tables and the schema/database they are loaded into.

Example:
```
Table           | Schema/Database
----------------|----------------
brz_orders      | bronze_db.dbo
brz_customers   | bronze_db.dbo
brz_products    | bronze_db.dbo
```

### Topic 2 — Fabric Connection

**Step 1** — Fill in the SQL Analytics Endpoint URL for each lakehouse:

| Lakehouse | Used by | Endpoint URL |
|-----------|---------|--------------|
| Bronze | `_source.yml` (source tables) | _(fill in)_ |
| Silver | `models/intermediate/` | _(fill in)_ |
| Gold | `models/marts/` | _(fill in)_ |

**Step 2** — Fill in the schema name dbt writes to *within* each lakehouse (e.g. `dbo`, `staging`, `silver`, `gold`):

| Layer | Schema name |
|-------|-------------|
| Staging | _(fill in)_ |
| Intermediate | _(fill in)_ |
| Mart | _(fill in)_ |

**Step 3** — Select where service principal credentials are stored:
- `.env file`
- `environment variables`
- `Azure Key Vault`
- `other`

### Topic 3 — Metadata

> Which `meta` keys are required on every model?

Select from defaults or fill in custom values:

| Key | Default example | Your value |
|-----|----------------|------------|
| `owner` | `"data-engineering"` | _(fill in)_ |
| `domain` | `"sales"` | _(fill in)_ |
| `sla` | `"07:00"` | _(fill in)_ |
| `contains_pii` | `false` | _(fill in)_ |

---

## Summary & Confirmation

After collecting all inputs, present a summary:

```
Project scaffold summary
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Bronze tables:    {list}
Endpoints:        Bronze={url} | Silver={url} | Gold={url}
Schemas:          staging={name} | intermediate={name} | marts={name}
Credentials:      stored in {location}
Meta keys:        owner, domain, sla, contains_pii
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Confirm to generate all artefacts? (yes / amend)
```

Only proceed to generation after explicit confirmation.

---

## Generated Artefacts

### Layers & Folders
- **Config:** `dbt_project.yml` (folder/layer configs, materialization defaults, tag/meta defaults)

### Bronze Ownership
- **Docs:** `source.md` (bronze table inventory)
- **YAML:** `models/staging/{source}/_source.yml` (source declarations)

### Naming Conventions
- **Config:** `.sqlfluff` (naming/style enforcement per layer)

### Testing Baseline
- **Config:** `packages.yml` (dbt_utils)

### Fabric Connection
- **Config:** `profiles.yml` (dev + prod targets, ODBC endpoints, auth)
- **SQL:** `macros/generate_schema_name.sql` (dev/prod schema isolation)

### Always-On
- **Docs:** `project_standards.md` (DAG rules, layer placement logic, business logic placement rules, bronze ownership — what dbt artefacts don't capture)

---

## Reference Files

**Config templates:**
- `references/dbt_project.template.yml` — project config template with layer materializations and meta defaults (`owner`, `domain`, `sla`, `contains_pii`)
- `references/profiles.template.yml` — Fabric ODBC connection template (dev + prod_silver + prod_gold targets)
- `references/sqlfluff.template.cfg` — linting rules (`sparksql` default; `tsql` for Warehouse only)
- `references/generate_schema_name.template.sql` — schema isolation macro (dev/prod prefix mapping)

**Conventions:**
- `references/repo_conventions.md` — full folder tree, DAG rules, business logic placement, meta keys, YAML co-file requirements

