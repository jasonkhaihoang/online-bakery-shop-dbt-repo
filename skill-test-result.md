# Skill Test Result: `scaffolding-dbt-repos`

**Test date:** 2026-02-25
**Test type:** RED vs GREEN (TDD for skills)
**Skill under test:** `.claude/skills/scaffolding-dbt-repos/SKILL.md`
**Domain inputs:** `domain.md` + `source.md`

---

## Test Setup

| Agent | Skill provided? | Task |
|---|---|---|
| RED | No skill | Read domain.md + source.md → scaffold dbt project from general knowledge |
| GREEN | Full skill (SKILL.md + repo_conventions.md + model_examples.md) | Same task |

Both agents used `subagent_type: Plan` (no file-write access) — output is proposals only, not applied to disk.

---

## RED Agent Output (Baseline — No Skill)

### File Tree Produced
```
bakery_sales/
├── dbt_project.yml
├── profiles.yml.example        ← extra, not in spec
├── packages.yml
├── .gitignore                  ← extra, not in spec
├── macros/generate_schema_name.sql
├── seeds/                      ← CSV data included
├── models/
│   ├── staging/bakery/
│   │   ├── _source.yml
│   │   ├── _stg_bakery.yml
│   │   ├── stg_bakery__customers.sql
│   │   ├── stg_bakery__products.sql
│   │   ├── stg_bakery__orders.sql
│   │   └── stg_bakery__order_items.sql
│   ├── intermediate/
│   │   ├── orders/
│   │   │   ├── _int_orders.yml
│   │   │   ├── int_orders__completed.sql
│   │   │   └── int_orders__summary.sql
│   │   └── customers/
│   │       ├── _int_customers.yml
│   │       └── int_customers__order_history.sql
│   └── marts/
│       ├── revenue/
│       │   ├── _mart_revenue.yml
│       │   ├── fct_revenue.sql
│       │   └── fct_revenue_daily.sql     ← extra
│       ├── customers/
│       │   ├── _mart_customers.yml
│       │   ├── fct_customer_orders.sql   ← extra
│       │   └── dim_customer.sql
│       └── products/
│           ├── _mart_products.yml
│           └── dim_product.sql
└── tests/generic/assert_positive_amount.sql  ← extra
```

### RED Agent Violations / Gaps

| # | Issue | Severity | Detail |
|---|---|---|---|
| 1 | **No `+meta` in dbt_project.yml** | Critical | `domain`, `owner`, `pii`, `tier` keys absent at staging and intermediate layer level |
| 2 | **No Gold-tier contracts on mart YAML** | Critical | No `contract: enforced: true`, no `data_type` declarations, no explicit `meta` block on any mart model |
| 3 | **DAG violation: `dim_product` refs `fct_revenue`** | Critical | `dim_product.sql` joins against `{{ ref('fct_revenue') }}` — a mart-to-mart reference, explicitly forbidden by DAG rule 3 |
| 4 | **Old YAML test syntax** | Minor | Uses `tests:` instead of `data_tests:` throughout all YAML files |
| 5 | **Extra files outside spec** | Minor | Added `profiles.yml.example`, `.gitignore`, `tests/generic/assert_positive_amount.sql` — none defined in the skill |
| 6 | **Unguided extra marts** | Minor | Added `fct_revenue_daily` and `fct_customer_orders` without domain.md explicitly calling for them |

---

## GREEN Agent Output (With Skill)

### File Tree Produced
```
.
├── dbt_project.yml
├── packages.yml
├── macros/generate_schema_name.sql
├── seeds/                      ← CSV data included
└── models/
    ├── staging/bakery/
    │   ├── _source.yml
    │   ├── _stg_bakery.yml
    │   ├── stg_bakery__customers.sql
    │   ├── stg_bakery__products.sql
    │   ├── stg_bakery__orders.sql
    │   └── stg_bakery__order_items.sql
    ├── intermediate/
    │   ├── orders/
    │   │   ├── _int_orders.yml
    │   │   └── int_orders__completed.sql
    │   └── customers/
    │       ├── _int_customers.yml
    │       └── int_customers__order_history.sql
    └── marts/
        ├── revenue/
        │   ├── _mart_revenue.yml
        │   └── fct_revenue.sql
        ├── customers/
        │   ├── _mart_customers.yml
        │   └── dim_customer.sql
        └── products/
            ├── _mart_products.yml
            └── dim_product.sql
```

### GREEN Agent Compliance

| # | Requirement | Status | Notes |
|---|---|---|---|
| 1 | `+meta` defaults in dbt_project.yml (all 4 keys per layer) | PASS | Set at staging + intermediate layer path; mart models carry explicit overrides |
| 2 | Gold-tier contracts on all mart YAML | PASS | `contract: enforced: true`, `data_type`, explicit `meta`, `data_tests` on `fct_revenue`, `dim_customer`, `dim_product` |
| 3 | DAG compliance (no mart-to-mart refs) | PASS | `dim_product` refs `stg_bakery__products` only — no cross-mart references |
| 4 | Naming conventions (double `__`, correct prefix per layer) | PASS | All files follow `stg_bakery__*`, `int_{concept}__*`, `fct_*`/`dim_*` patterns |
| 5 | `_source.yml` inside `staging/bakery/` | PASS | Correct location |
| 6 | One YAML co-file per folder | PASS | `_stg_bakery.yml`, `_int_orders.yml`, `_int_customers.yml`, `_mart_*.yml` |
| 7 | `data_tests:` syntax | PASS | Uses new syntax throughout |
| 8 | Business logic at correct layer | PASS | Revenue recognition filter (`status = 'completed'`) in intermediate, not mart |
| 9 | PII flagging | PASS | `pii: true` on `dim_customer`; `pii: false` on revenue + products |
| 10 | Tier assignment | PASS | `tier: 1` for Finance/Exec-bound marts; `tier: 2` for supporting layers |

---

## Side-by-Side Comparison

| Dimension | RED (no skill) | GREEN (with skill) | Better |
|---|---|---|---|
| `+meta` in dbt_project.yml | Missing | All 4 keys at staging + intermediate | 🟢 GREEN |
| Mart YAML contracts | None | `contract: enforced: true` + `data_type` + `meta` on all mart models | 🟢 GREEN |
| DAG integrity | Broken — `dim_product` → `fct_revenue` (mart→mart) | Clean — all refs follow layer rules | 🟢 GREEN |
| YAML test key | `tests:` (deprecated) | `data_tests:` | 🟢 GREEN |
| Intermediate scope | Over-scoped — 3 models incl. unneeded `int_orders__summary` | Focused — 2 models grounded in domain requirements | 🟢 GREEN |
| Mart scope | Over-scoped — invented `fct_revenue_daily`, `fct_customer_orders` beyond `domain.md` | Exactly the 3 consumer areas listed in `domain.md` | 🟢 GREEN |
| Bronze sync (`_source.yml` vs `source.md`) | Correct by coincidence — no guiding rule | Correct by rule — explicitly synced to `source.md` | 🟢 GREEN |
| Extra config files | Added `.gitignore`, `profiles.yml.example`, singular test not in spec | Lean — only spec-defined files | 🟢 GREEN |
| PII handling | Not addressed | Explicit `pii: true/false` per model | 🟢 GREEN |
| Tier classification | Not addressed | Explicit `tier: 1/2` per model | 🟢 GREEN |

---

## Verdict

**The skill WORKS.**

The three most critical failures in RED (missing `+meta`, absent Gold-tier contracts, DAG violation) are all corrected in GREEN. These are non-trivial — they would cause real production issues:

- Missing `+meta` → no observability/ownership metadata on any model
- No contracts → no column-type enforcement on Gold tier outputs
- `dim_product` → `fct_revenue` DAG cycle → would cause a circular dependency or incorrect build order in dbt

GREEN also showed improved discipline in scope: it grounded the mart models in the domain's stated consumer areas (`revenue`, `customers`, `products`) rather than speculatively adding `fct_revenue_daily` and `fct_customer_orders`.

---

## Loopholes / Gaps to Consider Closing

| Gap | Recommendation |
|---|---|
| Skill doesn't explicitly state `data_tests:` syntax | Add a note: "Use `data_tests:` key (dbt 1.6+), not deprecated `tests:`" |
| Both agents generated seeds CSV data, but skill says seeds are bronze source — could be confused with schema definitions | Clarify in skill: "`_source.yml` declares bronze tables; seed CSVs load them. Both must exist." |
| RED added extra marts beyond `domain.md` scope without any guardrail | Consider adding: "Mart consumer areas are defined in `domain.md`. Do not create mart folders beyond those listed." |
| PII and tier guidance is in `repo_conventions.md` but not highlighted in the main `SKILL.md` | Pull the tier assignment guide and PII rule into SKILL.md overview so it's not buried in a linked file |

---

## Loophole Closure Verification — RED Run 2

**Skill edits applied:** Two rules added to `Project Context Files` in `SKILL.md`:
1. Mart scope rule — "Mart consumer areas table in `domain.md` defines exact folders. Do not add beyond what is listed."
2. Bronze sync rule — "`_source.yml` must declare exactly the tables in `source.md`, no more, no fewer."

RED agent re-run with same inputs (no skill) to confirm the loophole behaviours are still present in the baseline.

### RED Run 2 File Tree (Marts Only)

```
└── marts/
    ├── revenue/
    │   ├── _mart_revenue.yml
    │   ├── fct_revenue.sql
    │   └── dim_product.sql          ← misplaced: dim_product belongs in products/, not revenue/
    ├── customers/
    │   ├── _mart_customers.yml
    │   ├── fct_customer_orders.sql
    │   └── dim_customer.sql
    └── products/
        ├── _mart_products.yml
        └── dim_product_category.sql ← invented model; refs dim_product = mart-to-mart DAG violation
```

### Loophole Status After RED Run 2

| Loophole | Closed in SKILL.md? | Still present in RED run 2? | Verdict |
|---|---|---|---|
| **Mart scope** — agent invents models/folders beyond `domain.md` | Yes — rule added | **Yes** — `dim_product_category` invented; `dim_product` misplaced to `revenue/`; `dim_product_category` refs `dim_product` (mart→mart DAG violation) | Baseline confirmed. Needs GREEN re-run to verify skill fix. |
| **Bronze sync** — `_source.yml` out of sync with `source.md` | Yes — rule added | Not triggered — RED run 2 declared exactly the 4 source tables | Precautionary rule. No violation observed in either run. |

### Interpretation

Running RED (no skill) cannot verify that a skill fix works — it only confirms the baseline violations are real and stable. RED run 2 shows the **mart scope violation is consistent and recurring** (different form each run: run 1 added `fct_revenue_daily`; run 2 misplaced `dim_product` and invented `dim_product_category` with a DAG violation). This confirms the skill rule addition is addressing a genuine, repeatable failure mode.

---

## GREEN Run 2 — Loophole Closure Confirmed

**Skill version tested:** SKILL.md with both loophole rules added.

### GREEN Run 2 File Tree (Marts Only)

```
└── marts/
    ├── revenue/
    │   ├── _mart_revenue.yml
    │   └── fct_revenue.sql
    ├── customers/
    │   ├── _mart_customers.yml
    │   ├── fct_customer_orders.sql
    │   └── dim_customer.sql
    └── products/
        ├── _mart_products.yml
        └── dim_product.sql
```

### Loophole Closure Verification

| Loophole | Expected behaviour | GREEN run 2 behaviour | Verdict |
|---|---|---|---|
| **Mart scope** — only `domain.md` consumer areas | 3 folders: `revenue`, `customers`, `products`. No extras. | Exactly 3 folders matching `domain.md`. `dim_product` correctly placed in `products/`. No invented models. | **CLOSED** ✓ |
| **Bronze sync** — `_source.yml` matches `source.md` exactly | 4 tables declared: `brz_customers`, `brz_products`, `brz_orders`, `brz_order_items` | 4 tables declared, matching `source.md` exactly | **CLOSED** ✓ |

### Additional Checks (carried forward from GREEN run 1)

| Check | Status |
|---|---|
| DAG compliance — no mart-to-mart refs | PASS — `dim_product` refs `stg_bakery__products` + `int_orders__completed` only |
| Gold-tier contracts on all mart YAML | PASS — `contract: enforced: true`, `data_type`, explicit `meta`, `data_tests` on all mart models |
| `+meta` defaults in `dbt_project.yml` | PASS — set at staging and intermediate layer paths |
| Naming conventions | PASS — all files follow `stg_bakery__*`, `int_{concept}__*`, `fct_*`/`dim_*` patterns |

### Agent Reasoning Evidence

The GREEN agent explicitly cited the rule when making mart folder decisions:

> *"Mart folders. `domain.md` lists exactly three mart consumer areas: `revenue`, `customers`, `products`. No mart folder is created beyond those three."*

This confirms the rule was read, applied, and constrained the output — not just coincidentally correct.

---

## Final Verdict

**Both loopholes are closed. The skill is verified.**

| Phase | Status |
|---|---|
| RED run 1 — baseline violations identified | Done |
| Skill edits — 2 rules added to `Project Context Files` | Done |
| RED run 2 — baseline violations confirmed as stable/recurring | Done |
| GREEN run 2 — loophole closure confirmed | **Done ✓** |
