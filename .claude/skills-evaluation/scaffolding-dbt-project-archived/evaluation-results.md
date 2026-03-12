# Skill Test Result: `scaffolding-dbt-project`

**Test type:** RED vs GREEN (TDD for skills)
**Skill under test:** `.claude/skills/scaffolding-dbt-project/SKILL.md`
**Domain inputs:** `domain.md` + `source.md`

Both agents used `subagent_type: general-purpose` and wrote actual files (not proposals), starting from a clean temp directory with no pre-existing dbt artifacts.

---

## Run History Progress

All runs across all dates. Scores are numeric only where a fixed rubric was used; earlier runs used an informal violation-listing approach.

| Date | Run | Rubric | RED | GREEN | Skill delta | Key outcome |
|------|-----|--------|-----|-------|-------------|-------------|
| 2026-02-25 | r1 | informal (~10) | ~4/10 | ~10/10 | +6 | Baseline: +meta absent, DAG violation (mart→mart), old `tests:` syntax |
| 2026-02-25 | r2 | informal (~10) | ~4/10 | ~10/10 | +6 | Loophole verification: mart scope + `_source.yml` sync confirmed closed |
| 2026-02-26 | r1 | 10 checks | ~10/10 | 10/10 | ~0 | Anomalous RED pass — outlier; RED got most checks right without skill |
| 2026-02-26 | r2 | 10 checks | 4/10 | 10/10 | +6 | Added co-file naming and incremental checks; RED regressed on +meta |
| 2026-02-26 | r3 | 15 checks | 6/15 | 15/15 | +9 | Full reset with unified rubric; incremental class (C08–C10) added |
| 2026-02-27 | r1 | **29 checks** | **21/29** | **29/29** | **+8** | Expanded rubric (A01–G02); RED still fails +meta, co-file naming, incremental config, mart meta, E03 |

**Trend:** Rubric grew from ~10 informal checks to 15 to 29 checks as new failure patterns were discovered. GREEN has been consistently perfect across all runs. RED's weak spots — `+meta` completeness, YAML co-file naming, incremental config in `dbt_project.yml`, mart model-level `meta:` — are stable across every run.

---

## Run 1 — 2026-02-27 · 29-check rubric (current)

**Output dirs:** `/tmp/finance-red/` (RED) · `/tmp/finance-green/` (GREEN)
**Domain:** `finance` · **Source:** `accounting` (brz_invoices, brz_payments)

| ID  | Group           | Check                                          | RED | GREEN |
|-----|-----------------|------------------------------------------------|-----|-------|
| A01 | Naming          | stg_* filename pattern                         | ✅  | ✅    |
| A02 | Naming          | int_* filename pattern                         | ✅  | ✅    |
| A03 | Naming          | fct_*/dim_* filename pattern                   | ✅  | ✅    |
| A04 | Naming          | YAML co-files: one per folder, `_{layer}_{area}.yml` | ❌  | ✅    |
| A05 | Naming          | `_source.yml` in `models/staging/accounting/`  | ✅  | ✅    |
| B01 | Structure       | stg_* SQL under `models/staging/`              | ✅  | ✅    |
| B02 | Structure       | int_* SQL under `models/intermediate/`         | ✅  | ✅    |
| B03 | Structure       | fct_*/dim_* SQL under `models/marts/`          | ✅  | ✅    |
| B04 | Structure       | `macros/generate_schema_name.sql` exists       | ✅  | ✅    |
| C01 | dbt_project.yml | Staging `+meta`: domain, owner, pii, tier (literals) | ❌  | ✅    |
| C02 | dbt_project.yml | Intermediate `+meta`: all 4 keys (literals)    | ❌  | ✅    |
| C03 | dbt_project.yml | Mart `+meta`: all 4 keys (literals)            | ❌  | ✅    |
| C04 | dbt_project.yml | No `vars:` meta-defaults block                 | ✅  | ✅    |
| C05 | dbt_project.yml | No extra path declarations                     | ❌  | ✅    |
| C06 | dbt_project.yml | Intermediate `+materialized: incremental` + strategy | ❌  | ✅    |
| C07 | dbt_project.yml | Staging view / Mart table                      | ✅  | ✅    |
| D01 | DAG             | stg_* uses `source()` only                     | ✅  | ✅    |
| D02 | DAG             | int_* refs only stg_* or int_*                 | ✅  | ✅    |
| D03 | DAG             | mart refs only int_* or stg_*                  | ✅  | ✅    |
| E01 | Int SQL         | `{{ config() }}` with unique_key + strategy    | ✅  | ✅    |
| E02 | Int SQL         | unique_key matches model grain PK              | ✅  | ✅    |
| E03 | Int SQL         | `is_incremental()` on all event CTEs; no filter on lookups | ❌  | ✅    |
| F01 | YAML            | Every model has entry + description            | ✅  | ✅    |
| F02 | YAML            | PK has `not_null` + `unique` tests             | ✅  | ✅    |
| F03 | YAML            | Mart `contract: enforced: true`                | ✅  | ✅    |
| F04 | YAML            | Mart `config: meta:` with all 4 keys           | ❌  | ✅    |
| F05 | YAML            | Mart columns have `data_type`                  | ✅  | ✅    |
| G01 | Staging purity  | No computed columns in staging                 | ✅  | ✅    |
| G02 | Staging purity  | No WHERE clause in staging                     | ✅  | ✅    |

**RED: 21/29 · GREEN: 29/29 · Skill delta: +8**

Checks fixed by skill: A04, C01, C02, C03, C05, C06, E03, F04
Checks still failing with skill: none

**RED failure notes:**
- A04: Created one YAML file per model (`_stg_accounting__invoices.yml`, `_stg_accounting__payments.yml`, etc.) instead of one co-file per folder
- C01–C03: `+meta` used `layer:` and `owner:` only — `domain`, `pii`, `tier` absent from all three layers
- C05: Added all default path declarations (`model-paths`, `seed-paths`, `test-paths`, `analysis-paths`, `macro-paths`, `snapshot-paths`, `docs-paths`)
- C06: Intermediate set to `+materialized: table` in dbt_project.yml (incremental config only in model SQL config block)
- E03: `invoices` CTE had `is_incremental()` filter; `payments` CTE (also transactional) did not
- F04: Mart YAML had `contract: enforced: true` but no `meta:` block

---

## Run 3 — 2026-02-26 · 15-check unified rubric

**Output dirs:** `/tmp/bakery-red2/` (RED) · `/tmp/bakery-green5/` (GREEN)

| Check | RED | RED evidence (on FAIL) | GREEN | Verdict |
|---|---|---|---|---|
| **C01** `dbt_project.yml` has `+meta` (domain, owner, pii, tier) at staging, intermediate, AND marts | FAIL | `+meta` has only `layer`, `owner`, `domain` — `pii` and `tier` absent from all three layer blocks | PASS | skill helped |
| **C02** `dbt_project.yml` lean — no extra path keys, no `seeds:` block | FAIL | Has `model-paths`, `seed-paths`, `test-paths`, `analysis-paths`, `macro-paths`, `vars: {}`, and a `seeds:` block | PASS | skill helped |
| **C03** Each mart model YAML has explicit `meta:` block (all 4 keys) alongside `contract: enforced: true` | FAIL | `contract: enforced: true` present but zero `meta:` blocks in any mart model entry | PASS | skill helped |
| **C04** Every mart column has `data_type:` using Postgres types — no `string`, `decimal`, `nvarchar` | PASS | | PASS | tie |
| **C05** All YAML test blocks use `data_tests:` (not deprecated `tests:`) | FAIL | 80 occurrences of `tests:` across all YAML files; zero `data_tests:` | PASS | skill helped |
| **C06** YAML co-files: one `.yml` per folder, named `_stg_{source}.yml` / `_int_{concept}.yml` / `_mart_{area}.yml` | FAIL | Mart co-files named `_marts_revenue.yml`, `_marts_customers.yml`, `_marts_products.yml` (extra `s`) | PASS | skill helped |
| **C07** Staging is pure passthrough — cast and rename only; no derived flags or computed metrics | PASS | | PASS | tie |
| **C08** Every `int_*` SQL has `{{ config(materialized='incremental', unique_key='...', incremental_strategy='merge') }}` | FAIL | Both int models use `materialized='table'`; no `unique_key` or `incremental_strategy` | PASS | skill helped |
| **C09** `unique_key` is the output grain PK (matches not_null+unique column in YAML) — not a FK, not omitted | FAIL | No `unique_key` at all (models are `table`) | PASS | skill helped |
| **C10** Every event/transactional source CTE in `int_*` models has `{% if is_incremental() %}` filter on an updated_at/date column | FAIL | No `is_incremental()` blocks at all | PASS | skill helped |
| **C11** Filtered intermediate has `accepted_values` sentinel test on `status` column in its YAML | PASS | | PASS | tie |
| **C12** `sqlfluff.cfg` uses `dialect = postgres` and `capitalisation_policy = lower` | PASS | | PASS | tie |
| **C13** DAG clean — staging only `source()`, intermediate only `ref()` to `stg_*/int_*`, marts only `ref()` to `int_*/stg_*` | PASS | | PASS | tie |
| **C14** Naming — `stg_{source}__{entity}`, `int_{concept}__{descriptor}`, `fct_{entity}`, `dim_{entity}`, double-underscore | PASS | | PASS | tie |
| **C15** Mart scope = `domain.md` areas only; `_source.yml` declares exactly the 4 tables in `source.md` | PASS | | PASS | tie |

**RED: 6/15 · GREEN: 15/15 · Skill delta: +9**

Checks where skill helped: C01, C02, C03, C05, C06, C08, C09, C10
Ties (both pass): C04, C07, C11, C12, C13, C14, C15

---

## Run 2 — 2026-02-26 · 10 checks

**Output dirs:** `/tmp/bakery-red/` (RED) · `/tmp/bakery-green/` (GREEN)

### RED — 4/10 (6 violations found)

| # | Violation | File | Severity |
|---|---|---|---|
| 1 | No `+meta` in `dbt_project.yml` | `dbt_project.yml` | Critical |
| 2 | Mart contracts missing `meta:` config | All `_mart_*.yml` | Critical |
| 3 | YAML co-file naming wrong | `models/marts/` | Minor |
| 4 | Business logic in staging | `stg_bakery__orders.sql` etc. | Minor |
| 5 | `sqlfluff.cfg` capitalisation conflict (`upper` vs `lower`) | `sqlfluff.cfg` | Minor |
| 6 | Extra `dbt_project.yml` keys | `dbt_project.yml` | Minor |

### GREEN — 10/10

All meta, contracts, YAML co-files, staging purity, sqlfluff, lean `dbt_project.yml`, DAG, naming, mart scope, source sync — all correct.

---

## Run 1 — 2026-02-26 · 10 checks (outlier)

No dedicated breakdown. Per the historical RED behavior table, RED passed nearly every check without the skill — the only run where this occurred across all 5 runs. No explanation was recorded. GREEN also passed 10/10.

Skill delta: ~0 (not informative — treat as outlier).

---

## C10 Fix Applied (post-run 3)

**Root cause:** The `intermediate.example.sql` example showed `is_incremental()` filters only on event/transactional CTEs, but `repo_conventions.md` said "goes on the `source` CTE" (singular, ambiguous). A GREEN agent correctly recognised that lookup/reference CTEs have no `updated_at` and should NOT be filtered, but failed the check because the check wording said "every source CTE".

**Fix applied to both the check and the skill:**

- `intermediate.example.sql` — added a third `account_regions` CTE (lookup, no filter) with explicit comments differentiating "event/transactional CTEs" (apply filter) from "lookup/reference CTEs" (do NOT apply filter).
- `repo_conventions.md` — updated the incremental filter paragraph and added: "**Lookup/reference CTEs do NOT get the incremental filter.** Filtering a lookup table incrementally would cause missing join matches."

**Result:** C10 re-scored as GREEN PASS, bringing GREEN to 15/15.

