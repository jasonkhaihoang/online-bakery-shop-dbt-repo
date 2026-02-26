# Skill Test Result: `scaffolding-dbt-project`

**Test date:** 2026-02-26 (run 3 — full reset, 15-check unified checklist)
**Test type:** RED vs GREEN (TDD for skills)
**Skill under test:** `.claude/skills/scaffolding-dbt-project/SKILL.md`
**Domain inputs:** `domain.md` + `source.md`
**Output dirs:** `/tmp/bakery-red2/` (RED) · `/tmp/bakery-green5/` (GREEN)

---

## Test Setup

| Agent | Skill provided? | Output dir |
|---|---|---|
| RED | No skill — LLM general knowledge only | `/tmp/bakery-red2/` |
| GREEN | Full skill (all 9 files from `scaffolding-dbt-project/`) | `/tmp/bakery-green5/` |

Both agents used `subagent_type: general-purpose` and wrote actual files (not proposals).
Both started from a clean temp directory with no pre-existing dbt artifacts.

---

## Unified 15-Check Results

| Check | RED | RED evidence (on FAIL) | GREEN | GREEN evidence (on FAIL) | Verdict |
|---|---|---|---|---|---|
| **C01** `dbt_project.yml` has `+meta` (domain, owner, pii, tier) at staging, intermediate, AND marts | FAIL | `+meta` has only `layer`, `owner`, `domain` — `pii` and `tier` absent from all three layer blocks | PASS | | skill helped |
| **C02** `dbt_project.yml` lean — no extra path keys, no `seeds:` block | FAIL | Has `model-paths`, `seed-paths`, `test-paths`, `analysis-paths`, `macro-paths`, `vars: {}`, and a `seeds:` block | PASS | | skill helped |
| **C03** Each mart model YAML has explicit `meta:` block (all 4 keys) alongside `contract: enforced: true` | FAIL | `contract: enforced: true` present but zero `meta:` blocks in any mart model entry | PASS | | skill helped |
| **C04** Every mart column has `data_type:` using Postgres types — no `string`, `decimal`, `nvarchar` | PASS | | PASS | | tie |
| **C05** All YAML test blocks use `data_tests:` (not deprecated `tests:`) | FAIL | 80 occurrences of `tests:` across all YAML files; zero `data_tests:` | PASS | Zero `tests:` in model YAMLs; 59 `data_tests:` used throughout | skill helped |
| **C06** YAML co-files: one `.yml` per folder, named `_stg_{source}.yml` / `_int_{concept}.yml` / `_mart_{area}.yml` | FAIL | Mart co-files named `_marts_revenue.yml`, `_marts_customers.yml`, `_marts_products.yml` (extra `s`) | PASS | `_mart_revenue.yml`, `_mart_customers.yml`, `_mart_products.yml` match convention | skill helped |
| **C07** Staging is pure passthrough — cast and rename only; no derived flags or computed metrics | PASS | | PASS | | tie |
| **C08** Every `int_*` SQL has `{{ config(materialized='incremental', unique_key='...', incremental_strategy='merge') }}` | FAIL | Both int models use `materialized='table'`; no `unique_key` or `incremental_strategy` | PASS | Both int models declare `incremental` + `merge` + `unique_key` | skill helped |
| **C09** `unique_key` is the output grain PK (matches not_null+unique column in YAML) — not a FK, not omitted | FAIL | No `unique_key` at all (models are `table`) | PASS | `int_customers__order_history`: `customer_id`; `int_orders__completed`: `order_item_id` — both match not_null+unique tested column | skill helped |
| **C10** Every event/transactional source CTE in `int_*` models has `{% if is_incremental() %}` filter on an updated_at/date column | FAIL | No `is_incremental()` blocks at all | PASS | Both int models filter their transactional CTEs; lookup CTEs correctly exempt (no `updated_at`) | skill helped |
| **C11** Filtered intermediate has `accepted_values` sentinel test on `status` column in its YAML | PASS | | PASS | | tie |
| **C12** `sqlfluff.cfg` uses `dialect = postgres` and `capitalisation_policy = lower` | PASS | | PASS | | tie |
| **C13** DAG clean — staging only `source()`, intermediate only `ref()` to `stg_*/int_*`, marts only `ref()` to `int_*/stg_*` | PASS | | PASS | | tie |
| **C14** Naming — `stg_{source}__{entity}`, `int_{concept}__{descriptor}`, `fct_{entity}`, `dim_{entity}`, double-underscore | PASS | | PASS | | tie |
| **C15** Mart scope = `domain.md` areas only; `_source.yml` declares exactly the 4 tables in `source.md` | PASS | | PASS | | tie |

---

## Summary

| | Score |
|---|---|
| **RED** | **6 / 15** |
| **GREEN** | **15 / 15** |

**Checks where skill helped (GREEN passes, RED fails):** C01, C02, C03, C05, C06, C08, C09, C10 — 8 checks

**Ties (both pass):** C04, C07, C11, C12, C13, C14, C15 — 7 checks

---

## C10 Fix Applied (post-run 3)

**Root cause identified:** The `intermediate.example.sql` example showed `is_incremental()` filters
only on event/transactional CTEs, but the old `repo_conventions.md` text said "goes on the
`source` CTE" (singular, ambiguous). A GREEN agent correctly recognised that lookup/reference
CTEs have no `updated_at` and should NOT be filtered, but failed the check because the check
wording said "every source CTE".

**Fix:** Both C10 and the skill were corrected together:

- `intermediate.example.sql` — added a third `account_regions` CTE (lookup, no filter) with
  explicit comments differentiating "event/transactional CTEs" (apply filter) from
  "lookup/reference CTEs" (do NOT apply filter).

- `repo_conventions.md` — updated the incremental filter paragraph: "must be applied to each
  **event/transactional** source CTE that has an `updated_at`…"; added a new paragraph:
  "**Lookup/reference CTEs do NOT get the incremental filter.** … all rows must be available
  for joins on every run. Filtering a lookup table incrementally would cause missing join
  matches."

**Result:** C10 re-scored as GREEN PASS (lookup CTEs correctly exempt), bringing GREEN to 15/15.

---

## Historical Comparison (all runs)

| Dimension | RED 2026-02-25 r1 | RED 2026-02-25 r2 | RED 2026-02-26 r1 | RED 2026-02-26 r2 | RED 2026-02-26 r3 |
|---|---|---|---|---|---|
| No `+meta` in `dbt_project.yml` | **Critical** | **Critical** | Correct | **Critical** | **Critical** |
| No mart `meta:` in YAML | **Critical** | **Critical** | Correct | Partial | **Critical** |
| No `contract: enforced: true` | **Critical** | **Critical** | Correct | Correct | Correct |
| No `data_tests:` (uses deprecated `tests:`) | **Minor** | **Minor** | Correct | Correct | **Critical** |
| YAML co-file naming wrong | Correct | Correct | Correct | **Minor** | **Minor** |
| Extra `dbt_project.yml` path keys | **Minor** | **Minor** | Correct | **Minor** | **Minor** |
| Business logic in staging | n/a | n/a | Clean | **Minor** | Clean |
| `int_*` not incremental (uses `table`) | n/a | n/a | n/a | n/a | **Critical** |
| DAG violations | **Critical** | **Critical** | Clean | Clean | Clean |
| Mart scope / `_source.yml` sync | **Minor** | **Minor** | Clean | Clean | Clean |

**Pattern:**
- `+meta` omission is the most consistent RED failure — appears in 4 of 5 RED runs
- `tests:` vs `data_tests:` regressed in run 3 after being correct in runs 1 and 2
- Incremental config (C08/C09/C10) is a new check class — RED fails as expected (no skill)

---

## Previous Test Runs — Archived

<details>
<summary>2026-02-26 run 2 results</summary>

**Test date:** 2026-02-26 (run 2)
**Output dirs:** `/tmp/bakery-red/` (RED) · `/tmp/bakery-green/` (GREEN)

### RED Violations (run 2)

| # | Violation | File | Severity |
|---|---|---|---|
| 1 | No `+meta` in `dbt_project.yml` | `dbt_project.yml` | Critical |
| 2 | Mart contracts missing `meta:` config | All `_mart_*.yml` | Critical |
| 3 | YAML co-file naming wrong | `models/marts/` | Minor |
| 4 | Business logic in staging | `stg_bakery__orders.sql` etc. | Minor |
| 5 | `sqlfluff.cfg` capitalisation conflict (`upper` vs `lower`) | `sqlfluff.cfg` | Minor |
| 6 | Extra `dbt_project.yml` keys | `dbt_project.yml` | Minor |

### GREEN Compliance (run 2) — 10/10 criteria PASS

All meta, contracts, YAML co-files, staging purity, sqlfluff, lean dbt_project.yml, DAG, naming, mart scope, source sync — all correct.

</details>

<details>
<summary>2026-02-25 test results (runs 1 and 2)</summary>

### RED Run 1 — Baseline Violations

| # | Issue | Severity |
|---|---|---|
| 1 | No `+meta` in dbt_project.yml | Critical |
| 2 | No Gold-tier contracts on mart YAML | Critical |
| 3 | DAG violation: `dim_product` refs `fct_revenue` | Critical |
| 4 | Old `tests:` syntax throughout | Minor |
| 5 | Extra files outside spec | Minor |
| 6 | Unguided extra marts | Minor |

### GREEN Run 1 — All critical issues resolved

### RED Run 2 (loophole closure verification)

```
└── marts/
    ├── revenue/
    │   ├── fct_revenue.sql
    │   └── dim_product.sql          ← misplaced
    ├── customers/
    │   ├── fct_customer_orders.sql
    │   └── dim_customer.sql
    └── products/
        └── dim_product_category.sql ← invented; refs dim_product = mart→mart DAG violation
```

### GREEN Run 2 — Loophole closure confirmed

Both rules (mart scope + bronze sync) confirmed closed. Full DAG compliance. All contracts and meta present.

</details>
