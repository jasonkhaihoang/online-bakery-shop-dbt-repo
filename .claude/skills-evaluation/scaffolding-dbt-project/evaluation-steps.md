# Skill Evaluation: `scaffolding-dbt-project-v2`

> **Invoke `superpowers:dispatching-parallel-agents` before starting this evaluation.**

## 1 — Overview

This document defines a repeatable evaluation that measures whether the `scaffolding-dbt-project-v2` skill actually changes Claude's behavior for the better.

Two parallel agents receive the same scaffolding task:
- **RED agent** — no skill invoked (reflects Claude's default behavior)
- **GREEN agent** — skill invoked before starting (reflects skill-guided behavior)

Both outputs are evaluated against the same 30-check rubric. The resulting scorecard shows exactly which checks the skill fixes and which gaps remain.

**Key differences from `scaffolding-dbt-project` (v1):**
- v2 is **Phase 1 only** — it produces config and infra artefacts, never model SQL
- v2 is **interview-driven** — walks through Bronze → Fabric → Metadata topics before generating
- v2 is **Fabric-specific** — `dbt-fabric` adapter, ODBC, `sparksql` dialect, per-lakehouse endpoints
- v2 meta keys are `owner`, `domain`, `sla`, `contains_pii` (not `tier`/`pii`)

---

## 2 — How to Run the Evaluation

1. Open a new conversation and invoke `superpowers:dispatching-parallel-agents`.
2. Spawn **RED agent** (general-purpose subagent):
   - Give it the Standard Test Task (Section 3) verbatim, with **no mention of any skill**.
3. Spawn **GREEN agent** (general-purpose subagent):
   - Give it the same Standard Test Task, but prepend:
     > "Before starting, invoke the `scaffolding-dbt-project-v2` skill."
4. Both agents return a **plan only** — a list of artefacts they would generate with the full intended content of each file. **Do not write actual files to disk.** The plan is sufficient for evaluation.
5. Evaluate each agent's plan against the Evaluation Rubric (Section 4), marking each check ✅ or ❌.
6. Fill in the Comparison Scorecard (Section 5), compute totals, and identify the skill delta.

---

## 3 — Standard Test Task

> You are setting up a new Microsoft Fabric dbt project for a `finance` domain.
>
> Walk through the project setup interview. Use the following answers when prompted:
>
> **Bronze ownership:**
>
> | Table | Schema/Database |
> |-------|----------------|
> | `brz_invoices` | `finance_bronze.dbo` |
> | `brz_payments` | `finance_bronze.dbo` |
>
> **Fabric connection:**
> - Bronze endpoint: `finance-bronze.datawarehouse.fabric.microsoft.com`
> - Silver endpoint: `finance-silver.datawarehouse.fabric.microsoft.com`
> - Gold endpoint: `finance-gold.datawarehouse.fabric.microsoft.com`
> - Staging schema: `staging`
> - Intermediate schema: `intermediate`
> - Mart schema: `marts`
> - Credentials: stored in `environment variables`
>
> **Metadata:**
> - `owner`: `"data-engineering"`
> - `domain`: `"finance"`
> - `sla`: `"07:00"`
> - `contains_pii`: `false`
>
> Do not generate actual files. Instead, produce a **plan**: list every artefact you would generate and show the full intended content of each. Do not run any dbt commands.

This task is deliberately minimal but exercises all three interview topics, all config groups, and all check areas in the rubric.

---

## 4 — Evaluation Rubric

Grade each check as ✅ (pass) or ❌ (fail). Apply the same rubric to both RED and GREEN outputs.

### Group A — Interview Protocol

| ID  | Check | Pass condition |
|-----|-------|----------------|
| A01 | One topic at a time | Skill steps through Bronze → Fabric → Metadata sequentially; does not dump all questions at once |
| A02 | Summary before generation | A summary block is presented after all inputs are collected, before any file is written |
| A03 | No model SQL produced | No `stg_*`, `int_*`, `fct_*`, or `dim_*` SQL files are generated |

### Group B — `dbt_project.yml`

| ID  | Check | Pass condition |
|-----|-------|----------------|
| B01 | Staging `+meta` completeness | `+meta` under staging path has all 4 keys: `owner`, `domain`, `sla`, `contains_pii` as literal values |
| B02 | Intermediate `+meta` completeness | Same 4 keys under intermediate path, literal values |
| B03 | Mart `+meta` completeness | Same 4 keys under mart path, literal values |
| B04 | No `vars:` meta-defaults block | No `vars:` block used to supply meta key defaults |
| B05 | No extra path declarations | No unnecessary `model-paths`, `seed-paths`, `analysis-paths`, etc. |
| B06 | Intermediate materialization | `+materialized: incremental` + `+incremental_strategy: merge` under intermediate path |
| B07 | Staging view / Mart table | Staging `+materialized: view`, mart `+materialized: table` |

### Group C — `profiles.yml`

| ID  | Check | Pass condition |
|-----|-------|----------------|
| C01 | Adapter is `fabric` | Adapter field is `fabric` — not `spark`, `synapse`, `postgres`, or `dbt-synapse` |
| C02 | `dev` target uses interactive auth | dev target has Entra ID interactive authentication |
| C03 | `prod` target uses service principal | prod target references `client_id`, `client_secret`, `tenant_id` from env vars |
| C04 | Bronze endpoint present | The provided Bronze endpoint URL appears in profiles |
| C05 | Silver and Gold endpoints present | Silver and Gold endpoint URLs appear in profiles for the correct targets |

### Group D — Source Declarations

| ID  | Check | Pass condition |
|-----|-------|----------------|
| D01 | `_source.yml` at correct path | File at `models/staging/accounting/_source.yml` or `models/staging/finance_bronze/_source.yml` |
| D02 | Declares correct bronze tables | `brz_invoices` and `brz_payments` declared — no extra or missing tables |
| D03 | Database/schema matches bronze | `database` / `schema` in source declaration matches the provided bronze lakehouse details |

### Group E — `.sqlfluff`

| ID  | Check | Pass condition |
|-----|-------|----------------|
| E01 | `dialect = sparksql` | Not `postgres`, `tsql`, or `ansi` |
| E02 | `capitalisation_policy = lower` | Applied to keywords, identifiers, and functions |
| E03 | Trailing comma + explicit aliasing | `line_position = trailing` and `aliasing = explicit` for tables and columns |

### Group F — `macros/generate_schema_name.sql`

| ID  | Check | Pass condition |
|-----|-------|----------------|
| F01 | File produced | `macros/generate_schema_name.sql` exists |
| F02 | `prod` uses schema as-is | When `target.name == 'prod'`, returns `custom_schema_name` untouched |
| F03 | Non-prod prefixes with target name | Non-prod returns `{{ target.name }}_{{ custom_schema_name }}` pattern |

### Group G — `project_standards.md`

| ID  | Check | Pass condition |
|-----|-------|----------------|
| G01 | File produced at repo root | `project_standards.md` exists |
| G02 | Contains DAG rules | Documents the 4 DAG rules (`stg_*` → source only; `int_*` → ref stg/int; mart → ref int/stg) |
| G03 | Contains staging boundary rules | Documents what is forbidden in staging (flags, filters, computed metrics) |
| G04 | Contains bronze ownership statement | States that bronze is managed outside dbt; staging is the dbt entry point |

### Group H — Supporting Files

| ID  | Check | Pass condition |
|-----|-------|----------------|
| H01 | `packages.yml` has `dbt_utils` only | `dbt-labs/dbt_utils` declared; no additional test packages |
| H02 | `source.md` documents bronze tables | Bronze table inventory produced with at minimum table names and schema |

---

## 5 — Comparison Scorecard (output template)

Fill in after evaluating both agents. Use ✅ for pass, ❌ for fail.

```
## Scorecard — scaffolding-dbt-project-v2 skill evaluation

| ID  | Group           | Check                                               | RED (no skill) | GREEN (with skill) |
|-----|-----------------|-----------------------------------------------------|----------------|--------------------|
| A01 | Interview       | One topic at a time                                 |                |                    |
| A02 | Interview       | Summary before generation                           |                |                    |
| A03 | Interview       | No model SQL produced                               |                |                    |
| B01 | dbt_project.yml | Staging +meta: owner, domain, sla, contains_pii     |                |                    |
| B02 | dbt_project.yml | Intermediate +meta: all 4 keys                      |                |                    |
| B03 | dbt_project.yml | Mart +meta: all 4 keys                              |                |                    |
| B04 | dbt_project.yml | No vars: meta-defaults block                        |                |                    |
| B05 | dbt_project.yml | No extra path declarations                          |                |                    |
| B06 | dbt_project.yml | Intermediate incremental + merge strategy           |                |                    |
| B07 | dbt_project.yml | Staging view / Mart table                           |                |                    |
| C01 | profiles.yml    | Adapter is fabric                                   |                |                    |
| C02 | profiles.yml    | dev uses Entra ID interactive auth                  |                |                    |
| C03 | profiles.yml    | prod uses service principal (env vars)              |                |                    |
| C04 | profiles.yml    | Bronze endpoint URL present                         |                |                    |
| C05 | profiles.yml    | Silver and Gold endpoint URLs present               |                |                    |
| D01 | _source.yml     | File at correct path                                |                |                    |
| D02 | _source.yml     | Declares correct bronze tables only                 |                |                    |
| D03 | _source.yml     | database/schema matches bronze lakehouse            |                |                    |
| E01 | .sqlfluff       | dialect = sparksql                                  |                |                    |
| E02 | .sqlfluff       | capitalisation_policy = lower                       |                |                    |
| E03 | .sqlfluff       | Trailing comma + explicit aliasing                  |                |                    |
| F01 | macro           | generate_schema_name.sql exists                     |                |                    |
| F02 | macro           | prod returns schema as-is                           |                |                    |
| F03 | macro           | non-prod prefixes with target name                  |                |                    |
| G01 | project_stds    | project_standards.md exists                         |                |                    |
| G02 | project_stds    | Contains DAG rules                                  |                |                    |
| G03 | project_stds    | Contains staging boundary rules                     |                |                    |
| G04 | project_stds    | Contains bronze ownership statement                 |                |                    |
| H01 | packages.yml    | dbt_utils only (no extra packages)                  |                |                    |
| H02 | source.md       | Bronze table inventory produced                     |                |                    |

**RED score:   /30**
**GREEN score: /30**
**Skill delta: + checks fixed by skill**

Checks fixed by skill: ...
Checks still failing with skill: ...
```

> **Checks still failing with skill** = skill gaps. Each one maps to a rule in the SKILL.md that needs to be strengthened or added.
