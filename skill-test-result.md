# Skill Test Result: `scaffolding-dbt-repos`

**Test date:** 2026-02-26 (run 2)
**Test type:** RED vs GREEN (TDD for skills)
**Skill under test:** `.claude/skills/scaffolding-dbt-repos/SKILL.md`
**Domain inputs:** `domain.md` + `source.md`
**Output dirs:** `/tmp/bakery-red/` (RED) · `/tmp/bakery-green/` (GREEN)

---

## Test Setup

| Agent | Skill provided? | Output dir | Task |
|---|---|---|---|
| RED | No skill | `/tmp/bakery-red/` | Read domain.md + source.md → scaffold dbt project from general knowledge |
| GREEN | Full skill (SKILL.md + repo_conventions.md + model_examples.md + dbt_project.yml + generate_schema_name.sql + schema_contracts.md + sqlfluff.cfg + model_template.sql) | `/tmp/bakery-green/` | Same task, following skill exactly |

Both agents used `subagent_type: general-purpose` — they wrote actual files, not proposals.
Both started from a clean temp directory with no pre-existing dbt artifacts.

---

## File Tree Comparison

| File | RED | GREEN |
|---|---|---|
| `dbt_project.yml` | ✓ | ✓ |
| `sqlfluff.cfg` | ✓ | ✓ |
| `macros/generate_schema_name.sql` | ✓ | ✓ |
| `models/staging/bakery/_source.yml` | ✓ | ✓ |
| `models/staging/bakery/_stg_bakery.yml` | ✓ | ✓ |
| `models/staging/bakery/stg_bakery__customers.sql` | ✓ | ✓ |
| `models/staging/bakery/stg_bakery__products.sql` | ✓ | ✓ |
| `models/staging/bakery/stg_bakery__orders.sql` | ✓ | ✓ |
| `models/staging/bakery/stg_bakery__order_items.sql` | ✓ | ✓ |
| `models/intermediate/orders/_int_orders.yml` | ✓ | ✓ |
| `models/intermediate/orders/int_orders__completed.sql` | ✓ | ✓ |
| `models/intermediate/customers/_int_customers.yml` | ✓ | ✓ |
| `models/intermediate/customers/int_customers__order_history.sql` | ✓ | ✓ |
| `models/marts/revenue/_mart_revenue.yml` | `_fct_revenue.yml` ← wrong name | ✓ |
| `models/marts/revenue/fct_revenue.sql` | ✓ | ✓ |
| `models/marts/customers/_mart_customers.yml` | `_dim_customer.yml` + `_fct_customer_orders.yml` ← split | ✓ |
| `models/marts/customers/dim_customer.sql` | ✓ | ✓ |
| `models/marts/customers/fct_customer_orders.sql` | ✓ | ✓ |
| `models/marts/products/_mart_products.yml` | `_dim_product.yml` ← wrong name | ✓ |
| `models/marts/products/dim_product.sql` | ✓ | ✓ |

**Total files:** RED = 21 · GREEN = 21 (same count; RED splits mart YAML where GREEN combines)

---

## RED Agent Violations

| # | Violation | File | Severity | Detail |
|---|---|---|---|---|
| 1 | **No `+meta` in dbt_project.yml** | `dbt_project.yml` | **Critical** | All 4 meta keys (`domain`, `owner`, `pii`, `tier`) absent from every layer config block. Skill requires these as layer-level defaults; without them no model inherits ownership or observability metadata |
| 2 | **Mart contracts missing `meta:` config** | All `_mart_*.yml` | **Critical** | `contract: enforced: true` is present but no `meta:` block. Skill requires explicit `meta` (all 4 keys) on every Gold-tier model YAML alongside the contract |
| 3 | **YAML co-file naming wrong** | `models/marts/` | Minor | One `.yml` per model (`_dim_customer.yml`, `_fct_customer_orders.yml`, `_dim_product.yml`, `_fct_revenue.yml`) instead of one per folder (`_mart_customers.yml`, `_mart_revenue.yml`, `_mart_products.yml`). Skill: "one `.yml` per folder, shared by all models in that folder" |
| 4 | **Business logic added to staging** | `stg_bakery__orders.sql`, `stg_bakery__customers.sql`, `stg_bakery__order_items.sql` | Minor | Staging computes `is_completed`/`is_cancelled` flags, derives `full_name`, and pre-calculates `line_total`. Skill: staging is clean/type/rename only — no derived logic |
| 5 | **`sqlfluff.cfg` capitalisation conflict** | `sqlfluff.cfg` | Minor | `capitalisation_policy = upper` for keywords, functions, literals. Skill template specifies `lower` throughout |
| 6 | **Extra `dbt_project.yml` keys** | `dbt_project.yml` | Minor | Added `model-paths`, `analysis-paths`, `test-paths`, `seed-paths`, `macro-paths`, `snapshot-paths`, `target-path`, and a `seeds: bakery_sales:` config block — none present in skill template |

---

## GREEN Agent Compliance

| # | Requirement | Status | Notes |
|---|---|---|---|
| 1 | `+meta` defaults in `dbt_project.yml` (all 4 keys per layer) | **PASS** | `domain: sales`, `owner: data-eng`, `pii: false`, `tier: 3/2/1` at staging, intermediate, mart paths |
| 2 | Gold-tier contracts with explicit `meta:` on all mart models | **PASS** | `contract: enforced: true`, `meta:` (all 4 keys), `data_type`, tests on all mart models |
| 3 | YAML co-file naming — one file per folder | **PASS** | `_mart_customers.yml`, `_mart_revenue.yml`, `_mart_products.yml` — all correctly named and shared |
| 4 | Staging = clean/type/rename only, no derived logic | **PASS** | Staging SQL limited to `select`, column renaming, and explicit casts; no business-logic derivations |
| 5 | `sqlfluff.cfg` keyword capitalisation = lower | **PASS** | Matches skill template: lowercase keywords, identifiers, functions, literals |
| 6 | Lean `dbt_project.yml` matching skill template | **PASS** | Only layer materialisation, schema, tags, meta, snapshots, tests, clean-targets — no extra path keys |
| 7 | DAG rules (no backwards/cross-layer refs) | **PASS** | Staging → `source()` only; intermediate → `stg_*` only; marts → `int_*` or `stg_*` only |
| 8 | Naming conventions (double `__`, correct prefix) | **PASS** | All files follow `stg_bakery__*`, `int_{concept}__*`, `fct_*`/`dim_*` patterns |
| 9 | Mart scope grounded in `domain.md` | **PASS** | Exactly `revenue`, `customers`, `products` — no extras |
| 10 | `_source.yml` declares exactly the tables in `source.md` | **PASS** | 4 tables: `brz_customers`, `brz_products`, `brz_orders`, `brz_order_items` |

---

## Side-by-Side Comparison

| Dimension | RED (no skill) | GREEN (with skill) | Verdict |
|---|---|---|---|
| `+meta` in `dbt_project.yml` | **Missing entirely** | All 4 keys at all 3 layers | better |
| `meta:` block on mart model YAML | **Missing** (contract present but no meta) | Explicit meta on every mart model | better |
| YAML co-file per folder | **Violated** — per-model files | One file per folder, correct names | better |
| Staging SQL — clean/type/rename only | **Violated** — derived flags, full_name, line_total | Clean: cast + rename only | better |
| `sqlfluff.cfg` keyword policy | **UPPER** (contradicts skill template) | **lower** (matches skill template) | better |
| `dbt_project.yml` leanness | Extra path keys + seeds block | Matches skill template exactly | better |
| `contract: enforced: true` on mart YAML | Present ✓ | Present ✓ | tie |
| `data_type` on all mart columns | Present ✓ | Present ✓ | tie |
| DAG compliance | Clean ✓ | Clean ✓ | tie |
| Naming conventions | Correct ✓ | Correct ✓ | tie |
| Mart scope = `domain.md` areas only | Correct ✓ | Correct ✓ | tie |
| `_source.yml` sync with `source.md` | Correct ✓ | Correct ✓ | tie |

---

## Critical Violations Breakdown

### Violation 1 — No `+meta` in `dbt_project.yml`

**RED:**
```yaml
staging:
  +schema: staging
  +materialized: view
  bakery:
    +tags: ["staging", "bakery"]
  # NO +meta block
```

**GREEN:**
```yaml
staging:
  +materialized: view
  +schema: staging
  +tags:
    - staging
  +meta:
    domain: sales
    owner: data-eng
    pii: false
    tier: 3
```

**Impact:** Without `+meta` defaults, no model in the project inherits `domain`, `owner`, `pii`, or `tier`. These keys are the project's observability and governance taxonomy. Data catalogues, lineage tools, and access-control systems that read dbt metadata will find empty fields for every model.

---

### Violation 2 — Mart YAML contracts missing `meta:` config

**RED (`_fct_revenue.yml`):**
```yaml
config:
  contract:
    enforced: true
# NO meta: block
```

**GREEN (`_mart_revenue.yml`):**
```yaml
config:
  contract:
    enforced: true
  meta:
    domain: sales
    owner: data-eng
    pii: false
    tier: 1
```

**Impact:** Gold-tier models are the public interface of the project — the ones consumed by Finance, Marketing, and Exec. Per `repo_conventions.md`: "Mart (Gold): `meta` must be declared explicitly in each model's YAML block (in addition to any `+meta` defaults)." Omitting it means even if `+meta` defaults existed, the mart-level overrides (e.g., `pii: true` for `dim_customer`) would be missing.

---

### Violation 3 — YAML co-file naming

**RED** splits the customers mart into two separate files:
```
models/marts/customers/
  _dim_customer.yml          ← one file per model
  _fct_customer_orders.yml   ← one file per model
  dim_customer.sql
  fct_customer_orders.sql
```

**GREEN** follows the skill rule of one co-file per folder:
```
models/marts/customers/
  _mart_customers.yml        ← single co-file for all models in folder
  dim_customer.sql
  fct_customer_orders.sql
```

**Impact:** In large projects, per-model YAML files create a proliferation of files that are harder to navigate. The skill's one-co-file-per-folder rule keeps each mart area readable in a single scan.

---

### Violation 4 — Business logic in staging

**RED `stg_bakery__orders.sql` (derived flags):**
```sql
status = 'completed' as is_completed,
status = 'cancelled' as is_cancelled
```

**RED `stg_bakery__customers.sql` (derived column):**
```sql
first_name || ' ' || last_name as full_name,
lower(email)                   as email,
```

**GREEN `stg_bakery__orders.sql` (clean — no derivations):**
```sql
cast(order_date as date)        as order_date,
status,
cast(total_amount as numeric)   as total_amount
```

**Impact:** Revenue logic downstream in RED uses `where is_completed` — a flag derived in staging. This blurs the boundary: staging should pass data through cleanly so that the intermediate layer is the single place where business rules live. If the completed filter is bypassed or changed, staging's boolean flags become stale and intermediate models silently produce wrong results.

---

## Verdict

**The skill works and continues to fix the two most critical structural failures.**

Both violations that matter most for production correctness — missing `+meta` in `dbt_project.yml` and missing `meta:` on mart contracts — appeared in RED and were absent in GREEN. These are not cosmetic:

- **Missing `+meta`** means zero observability metadata on any model in the project
- **Missing mart `meta:`** means no PII flags, no tier assignments, and no ownership on the models that Finance and Marketing actually query

GREEN also maintained cleaner staging SQL (cast/rename only), correct YAML co-file names, and a lean `dbt_project.yml` matching the skill template exactly.

---

## Historical Comparison (all runs)

| Dimension | RED 2026-02-25 run 1 | RED 2026-02-25 run 2 | RED 2026-02-26 run 1 | RED 2026-02-26 run 2 |
|---|---|---|---|---|
| No `+meta` in `dbt_project.yml` | **Critical** | **Critical** | Correct | **Critical** |
| No mart contracts | **Critical** | **Critical** | Correct | Partial (contract present, meta missing) |
| DAG violations | **Critical** | **Critical** | Clean | Clean |
| YAML co-file naming | Correct | Correct | Correct | **Violated** |
| Old `tests:` syntax | **Minor** | **Minor** | Correct | n/a (both use `tests:`) |
| Extra marts beyond domain.md | **Minor** | **Minor** | Clean | Clean |
| Staging = clean/type/rename | n/a | n/a | Clean | **Violated** |

**Pattern:** The `+meta` omission is the most consistent RED failure across all runs. It has appeared in 3 of 4 RED runs. This confirms it is the primary thing the skill fixes reliably.

---

## Previous Test Runs (2026-02-25) — Archived

<details>
<summary>Full 2026-02-25 test results</summary>

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
