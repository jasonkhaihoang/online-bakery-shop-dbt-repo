# Skill Evaluation: `scaffolding-dbt-project`

> **Invoke `superpowers:dispatching-parallel-agents` before starting this evaluation.**

## 1 — Overview

This document defines a repeatable evaluation that measures whether the `scaffolding-dbt-project` skill actually changes Claude's behavior for the better.

Two parallel agents receive the same scaffolding task:
- **RED agent** — no skill invoked (reflects Claude's default behavior)
- **GREEN agent** — skill invoked before starting (reflects skill-guided behavior)

Both outputs are evaluated against the same 29-check rubric. The resulting scorecard shows exactly which checks the skill fixes and which gaps remain to be closed in the skill.

**Expected baseline (Run 3, 2026-02-26):** RED 6/15, GREEN 15/15 after C10 fix.

---

## 2 — How to Run the Evaluation

1. Open a new conversation and invoke `superpowers:dispatching-parallel-agents`.
2. Spawn **RED agent** (general-purpose subagent):
   - Give it the Standard Test Task (Section 3) verbatim, with **no mention of any skill**.
3. Spawn **GREEN agent** (general-purpose subagent):
   - Give it the same Standard Test Task, but prepend this sentence:
     > "Before starting, invoke the `scaffolding-dbt-project` skill."
4. Both agents output their scaffolded files — collect the list of file paths and file contents (or diffs).
5. Evaluate each agent's output against the Evaluation Rubric (Section 4), marking each check ✅ or ❌.
6. Fill in the Comparison Scorecard (Section 5), compute totals, and identify the skill delta.

---

## 3 — Standard Test Task

> Scaffold a new dbt project for a `finance` domain with the following requirements:
>
> - **Source system:** `accounting`
> - **Bronze tables:** `brz_invoices`, `brz_payments`
> - **Staging layer:** one model per bronze table
> - **Intermediate layer:** one model — completed invoices (merge-incremental, grain: `invoice_id`)
> - **Mart layer:** one mart — `fct_revenue` (one row per invoice, contracted)
>
> Produce:
> - `dbt_project.yml` (full project config with `+meta` for all three layers)
> - `macros/generate_schema_name.sql`
> - All model SQL files for staging, intermediate, and mart
> - All YAML co-files (co-located with models)
> - `models/staging/accounting/_source.yml`
>
> Do not run any dbt commands — just produce the files.

This task is deliberately minimal but covers all layers, all config groups, and all check areas in the rubric.

---

## 4 — Evaluation Rubric

Grade each check as ✅ (pass) or ❌ (fail). Apply the same rubric to both RED and GREEN outputs.

### Group A — Naming Conventions

| ID  | Check | Pass condition |
|-----|-------|----------------|
| A01 | `stg_*` filename pattern | Files named `stg_{source}__{entity}.sql` (double-underscore separator) |
| A02 | `int_*` filename pattern | Files named `int_{concept}__{descriptor}.sql` |
| A03 | `fct_*/dim_*` filename pattern | Mart files named `fct_{entity}.sql` or `dim_{entity}.sql` |
| A04 | YAML co-file naming | YAML files named `_{layer}_{source_or_area}.yml` (e.g. `_staging_accounting.yml`) |
| A05 | `_source.yml` location | `models/staging/accounting/_source.yml` exists |

### Group B — Folder Structure

| ID  | Check | Pass condition |
|-----|-------|----------------|
| B01 | Staging SQL location | All `stg_*` SQL under `models/staging/` |
| B02 | Intermediate SQL location | All `int_*` SQL under `models/intermediate/` |
| B03 | Mart SQL location | All `fct_*/dim_*` SQL under `models/marts/` |
| B04 | `generate_schema_name.sql` exists | `macros/generate_schema_name.sql` is produced |

### Group C — `dbt_project.yml`

| ID  | Check | Pass condition |
|-----|-------|----------------|
| C01 | Staging `+meta` completeness | Has all 4 keys: `domain`, `owner`, `pii`, `tier` as string literals (no Jinja `{{ var() }}`) |
| C02 | Intermediate `+meta` completeness | Same 4 keys, string literals |
| C03 | Mart `+meta` completeness | Same 4 keys, string literals |
| C04 | No `vars:` meta-defaults block | No `vars:` block providing meta key defaults |
| C05 | No extra path declarations | No `model-paths:`, `seed-paths:`, `analysis-paths:`, etc. added unless needed |
| C06 | Intermediate materialization | `+materialized: incremental` + `+incremental_strategy: merge` under intermediate path |
| C07 | Staging/mart materialization | Staging `+materialized: view`, mart `+materialized: table` |

### Group D — DAG Enforcement

| ID  | Check | Pass condition |
|-----|-------|----------------|
| D01 | Staging uses only `source()` | No `ref()` in any `stg_*` SQL |
| D02 | Intermediate refs only lower layers | `int_*` references only `stg_*` or other `int_*` models via `ref()` |
| D03 | Mart refs only `int_*` or `stg_*` | No mart referencing another mart |

### Group E — Intermediate SQL Quality

| ID  | Check | Pass condition |
|-----|-------|----------------|
| E01 | `{{ config() }}` block present | Incremental model has `config(unique_key=..., incremental_strategy='merge')` |
| E02 | `unique_key` matches grain | `unique_key` is `invoice_id` (model grain), not a FK or non-unique column |
| E03 | `is_incremental()` filter on event CTEs only | `{% if is_incremental() %}` filter applied only to event/transactional CTEs; lookup/reference CTEs have no filter |

### Group F — YAML Completeness

| ID  | Check | Pass condition |
|-----|-------|----------------|
| F01 | Every model has a YAML entry with description | All `.sql` model files have a matching YAML entry with non-empty `description` |
| F02 | PK column has data tests | Primary key column has `not_null` + `unique` under `data_tests:` |
| F03 | Mart contract enforced | Mart YAML entry has `config: contract: enforced: true` |
| F04 | Mart has explicit `config: meta:` | Mart YAML entry has `config: meta:` with all 4 keys (domain, owner, pii, tier) |
| F05 | Mart columns have `data_type` | Every column in mart YAML has `data_type` declared |

### Group G — Staging Purity

| ID  | Check | Pass condition |
|-----|-------|----------------|
| G01 | No computed columns in staging | No arithmetic, boolean flags, string concatenation, or CASE logic in any `stg_*` SQL |
| G02 | No `WHERE` clause in staging | No filter in any `stg_*` SQL — staging is a pure 1:1 rename/cast layer |

---

## 5 — Comparison Scorecard (output template)

Fill in after evaluating both agents. Use ✅ for pass, ❌ for fail.

```
## Scorecard — scaffolding-dbt-project skill evaluation

| ID  | Group           | Check                                          | RED (no skill) | GREEN (with skill) |
|-----|-----------------|------------------------------------------------|----------------|--------------------|
| A01 | Naming          | stg_* filename pattern                         |                |                    |
| A02 | Naming          | int_* filename pattern                         |                |                    |
| A03 | Naming          | fct_*/dim_* filename pattern                   |                |                    |
| A04 | Naming          | YAML co-file naming                            |                |                    |
| A05 | Naming          | _source.yml location                           |                |                    |
| B01 | Structure       | Staging SQL location                           |                |                    |
| B02 | Structure       | Intermediate SQL location                      |                |                    |
| B03 | Structure       | Mart SQL location                              |                |                    |
| B04 | Structure       | generate_schema_name.sql exists                |                |                    |
| C01 | dbt_project.yml | Staging +meta completeness (literals)          |                |                    |
| C02 | dbt_project.yml | Intermediate +meta completeness (literals)     |                |                    |
| C03 | dbt_project.yml | Mart +meta completeness (literals)             |                |                    |
| C04 | dbt_project.yml | No vars: meta-defaults block                   |                |                    |
| C05 | dbt_project.yml | No extra path declarations                     |                |                    |
| C06 | dbt_project.yml | Intermediate materialization (incremental)     |                |                    |
| C07 | dbt_project.yml | Staging view / Mart table                      |                |                    |
| D01 | DAG             | Staging uses source() only                     |                |                    |
| D02 | DAG             | Intermediate refs lower layers only            |                |                    |
| D03 | DAG             | Mart refs int_* or stg_* only                  |                |                    |
| E01 | Int SQL         | config() block with unique_key + strategy      |                |                    |
| E02 | Int SQL         | unique_key matches grain                       |                |                    |
| E03 | Int SQL         | is_incremental() on event CTEs only            |                |                    |
| F01 | YAML            | Every model has entry + description            |                |                    |
| F02 | YAML            | PK has not_null + unique tests                 |                |                    |
| F03 | YAML            | Mart contract enforced                         |                |                    |
| F04 | YAML            | Mart has explicit config: meta:                |                |                    |
| F05 | YAML            | Mart columns have data_type                    |                |                    |
| G01 | Staging purity  | No computed columns in staging                 |                |                    |
| G02 | Staging purity  | No WHERE clause in staging                     |                |                    |

**RED score:   /29**
**GREEN score: /29**
**Skill delta: + checks fixed by skill**

Checks fixed by skill: ...
Checks still failing with skill: ...
```

> **Checks still failing with skill** = skill gaps. Each one maps to a rule in the skill that needs to be strengthened or added.
