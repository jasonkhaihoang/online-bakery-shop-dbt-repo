# Skill Evaluation: `processing-business-intent-to-dbt-artefacts`

> **Invoke `superpowers:dispatching-parallel-agents` before starting this evaluation.**

## 1 — Overview

This document defines a repeatable evaluation that measures whether the `processing-business-intent-to-dbt-artefacts` master orchestration skill improves Claude's ability to handle Phase 2 business intent requests.

Two agents receive the same business intent input **sequentially** (not in parallel — they both write files to disk and would conflict):
- **RED agent** — no skill invoked (reflects Claude's default behavior)
- **GREEN agent** — skill invoked before starting (reflects skill-guided behavior)

Both agents **write actual dbt artefacts to disk**. After each agent completes, run `dbt parse` to validate compilability, then grade against the rubric. Reset the repo (via `git checkout .` + `git clean -fd`) between runs to give each agent a clean slate.

Both outputs are evaluated against the same 29-check rubric. The resulting scorecard shows exactly which checks the skill fixes and which gaps remain.

---

## 2 — How to Run the Evaluation

Both agents run **in parallel** — they each write into their own isolated temp folder so there are no conflicts.

### Temp folder layout

```
.claude/skills-evaluation/processing-business-intent-to-dbt-artefacts/
  eval-runs/
    red/          ← RED agent writes here
      models/
      tests/
      seeds/
    green/        ← GREEN agent writes here
      models/
      tests/
      seeds/
```

Agents mirror the same subdirectory structure used in the real project (`models/staging/`, `models/intermediate/`, `models/marts/`, `tests/`, `seeds/`).

### Step 1 — Spawn both agents in parallel

**RED agent** (general-purpose subagent):
- Give it the Standard Test Task (Section 3) verbatim, **with no mention of any skill**.
- Tell it to write all artefacts under: `.claude/skills-evaluation/processing-business-intent-to-dbt-artefacts/eval-runs/red/`

**GREEN agent** (general-purpose subagent):
- Give it the same Standard Test Task, but prepend:
  > "Before starting, read the skill file at `.claude/skills/processing-business-intent-to-dbt-artefacts/SKILL.md` and follow all instructions in it."
- Tell it to write all artefacts under: `.claude/skills-evaluation/processing-business-intent-to-dbt-artefacts/eval-runs/green/`

### Step 2 — Run dbt parse for G04

For each agent's output in turn:
1. Copy the agent's `models/` and `tests/` and `seeds/` subtrees into the real project directories.
2. Run `.venv/bin/dbt parse` and record pass / fail.
3. **Reset:** `git checkout . && git clean -fd` before testing the next agent.

### Step 3 — Grade and score

Read the files in each agent's temp folder and grade against the Evaluation Rubric (Section 4). Fill in the Comparison Scorecard (Section 5).

---

## 3 — Standard Test Task

When spawning each agent, replace `{AGENT_OUTPUT_DIR}` with the agent's temp folder path:
- RED: `C:\Users\ADMIN\github\online-bakery-shop-dbt-repo\.claude\skills-evaluation\processing-business-intent-to-dbt-artefacts\eval-runs\red`
- GREEN: `C:\Users\ADMIN\github\online-bakery-shop-dbt-repo\.claude\skills-evaluation\processing-business-intent-to-dbt-artefacts\eval-runs\green`

```
You are a dbt analyst at an online bakery shop. The sales team has requested
a new monthly revenue report by product category.

The dbt project root is: C:\Users\ADMIN\github\online-bakery-shop-dbt-repo
Read dbt_project.yml and the existing staging/intermediate/mart files to understand
the project structure before generating artefacts.

Write all output files under: {AGENT_OUTPUT_DIR}
Mirror the same directory structure as the real project:
  {AGENT_OUTPUT_DIR}\models\staging\bakery\
  {AGENT_OUTPUT_DIR}\models\intermediate\orders\
  {AGENT_OUTPUT_DIR}\models\marts\revenue\
  {AGENT_OUTPUT_DIR}\tests\
  {AGENT_OUTPUT_DIR}\seeds\   (if needed)

Do not write files anywhere else. Do not modify any existing project files.

---

## Business Intent

Monthly revenue report by product category for the sales team.

## Business Metrics Required

- `total_revenue` — Sum of completed order line item amounts (excluding refunds and cancellations)
- `order_count` — Count of distinct orders per product category per month
- `avg_order_value` — `total_revenue / order_count` per category per month
- `revenue_mom_growth` — Month-over-month revenue growth percentage per category

## Business Rules

Each model must enforce:
- Revenue values must be > 0 (cancelled or fully-refunded orders excluded entirely)
- Order status must be in `('completed', 'shipped')` only
- `product_category_id` must not be null
- No duplicate `order_line_item_id` within a single order
- Null `product_category_id` rows must be excluded before aggregation

## Grain of Primary Output

**One row per `product_category` per `month`** (year-month grain)

## Known Edge Cases & Data Conditions

- **New categories:** If a product category exists in the current month but not the prior month, `revenue_mom_growth` should be null (not 0, not an error)
- **Multi-category orders:** Orders may span multiple product categories (split by line item grain, not order grain)
- **Partial refunds:** Some line items may be refunded while others are completed; capture refunded amount as a deduction from revenue, not as a full order exclusion
- **Pending orders:** Orders with status `'pending'` or `'processing'` should be excluded (not yet complete)
- **Historical changes:** If a product category name changes retroactively, handle gracefully (no failures)

---

Generate and write to disk:

1. **Staging models** — any new staging SQL + YAML needed (minimal transformations, cast + rename only)
2. **Intermediate models** — SQL applying all business rules with `{{ config() }}` blocks
3. **Mart model** — SQL with all 4 metrics, grain, and `{{ config() }}` block
4. **YAML schema files** — data contracts with unique keys, not_null, accepted_values
5. **DQ checks** — singular SQL tests enforcing business rules (revenue > 0, no nulls, no duplicates), each with explicit severity
6. **Unit tests** — YAML or SQL test artefacts validating business rules and column constraints
7. **Integration tests** — SQL tests validating cross-model relationships and reconciliation
8. **E2E tests** — SQL/YAML validating full pipeline from source to mart against reference data
```

---

## 4 — Evaluation Rubric

Grade each check as ✅ (pass) or ❌ (fail). Apply the same rubric to both RED and GREEN outputs.

> **Note:** For this artefact-generation evaluation, checks are graded against the **actual files written to disk**, not a plan. Open and read the generated files to verify each check.

### Group A — Orchestration & Planning

| ID  | Check | Pass condition |
|-----|-------|----------------|
| A01 | Skill invokes 1.1 before 1.2 | Mart model is generated before intermediate models (or agent log shows 1.1 before 1.2) |
| A02 | Skill always invokes 1.4 | DQ check SQL files are written to disk |
| A03 | Skill does NOT invoke 1.3 | No `metrics.yml` or Semantic Layer file is generated |
| A04 | Artefact list complete | All 4 categories of artefacts are present: SQL models, YAML schemas, DQ checks, tests |
| A05 | Skill references standards | Agent log or file comments reference `project_standards.md` for naming/structure decisions |

### Group B — Mart Model (Dimensional Design & SQL)

| ID  | Check | Pass condition |
|-----|-------|----------------|
| B01 | Correct grain | Mart model grain is explicitly one row per `product_category` per `month` (stated in SQL comment or YAML description) |
| B02 | All 4 metrics present | Mart SQL includes `total_revenue`, `order_count`, `avg_order_value`, `revenue_mom_growth` |
| B03 | Status filter applied | SQL includes `WHERE status IN ('completed', 'shipped')` or equivalent |
| B04 | Revenue > 0 filter | SQL includes `WHERE revenue > 0` or `HAVING revenue > 0` or net revenue deduction logic |
| B05 | Config block present | Mart SQL file includes `{{ config() }}` with materialization strategy |

### Group C — Staging & Intermediate Models

| ID  | Check | Pass condition |
|-----|-------|----------------|
| C01 | `stg_bakery__orders` referenced | Intermediate or mart SQL references `ref('stg_bakery__orders')` |
| C02 | `stg_bakery__order_items` referenced | Intermediate SQL references `ref('stg_bakery__order_items')` |
| C03 | Business logic applied | Intermediate model applies at least one business rule (deduplication, status filter, or refund adjustment) |
| C04 | Config blocks present | Each new staging/intermediate SQL file includes `{{ config() }}` block |
| C05 | YAML schema files present | `_*.yml` files exist for new/modified staging and intermediate models |

### Group D — Data Contracts

| ID  | Check | Pass condition |
|-----|-------|----------------|
| D01 | Unique key defined | Mart YAML defines a unique key on `[product_category, month]` or surrogate equivalent |
| D02 | Not-null constraints | YAML includes `not_null` tests for `product_category` and `month` on mart model |
| D03 | Accepted values | YAML includes `accepted_values` test for `status` column with allowed set |

### Group E — DQ Checks (Data Quality Validation)

| ID  | Check | Pass condition |
|-----|-------|----------------|
| E01 | Revenue > 0 check | A DQ SQL file explicitly validates `revenue > 0` |
| E02 | No null category check | A DQ SQL file validates no null `product_category` |
| E03 | No duplicate items check | A DQ SQL file validates no duplicate `order_line_item_id` per order |
| E04 | Severity levels assigned | At least 2 DQ check files have explicit severity (`warn` vs `error`) in their config or comments |

### Group F — Edge Case Handling

| ID  | Check | Pass condition |
|-----|-------|----------------|
| F01 | MoM growth nullability | SQL explicitly produces `NULL` (not 0) for new categories — e.g. via `LAG()` or `CASE WHEN prior IS NULL THEN NULL` |
| F02 | Partial refund handling | SQL deducts refund amount from line revenue without excluding the full order |
| F03 | Multi-category logic | SQL aggregates at line-item grain with `COUNT(DISTINCT order_id)` per category |

### Group G — Test Generation (2.1, 2.2, 2.3)

| ID  | Check | Pass condition |
|-----|-------|----------------|
| G01 | Unit tests present | At least one unit test SQL or YAML file exists validating a business rule |
| G02 | Integration tests present | At least one integration test SQL file validates a cross-model relationship |
| G03 | E2E tests present | At least one E2E test (SQL or seed+model) validates the full pipeline against reference data |
| G04 | dbt parse passes | `dbt parse` completes without errors after agent writes all files |

---

## 5 — Comparison Scorecard (output template)

Fill in after evaluating both agents. Use ✅ for pass, ❌ for fail.

```
## Scorecard — processing-business-intent-to-dbt-artefacts skill evaluation

| ID  | Group           | Check                                               | RED (no skill) | GREEN (with skill) |
|-----|-----------------|-----------------------------------------------------|----------------|--------------------|
| A01 | Orchestration   | Skill invokes 1.1 before 1.2                        |                |                    |
| A02 | Orchestration   | Skill always invokes 1.4 (DQ checks)                |                |                    |
| A03 | Orchestration   | Skill does NOT invoke 1.3 (Semantic Layer)          |                |                    |
| A04 | Orchestration   | All 4 artefact categories present                   |                |                    |
| A05 | Orchestration   | Skill references project_standards.md               |                |                    |
| B01 | Mart Model      | Correct grain (category × month)                    |                |                    |
| B02 | Mart Model      | All 4 metrics present                               |                |                    |
| B03 | Mart Model      | Status filter applied                               |                |                    |
| B04 | Mart Model      | Revenue > 0 filter applied                          |                |                    |
| B05 | Mart Model      | Config block present with materialization           |                |                    |
| C01 | Staging/Int     | stg_bakery__orders referenced                       |                |                    |
| C02 | Staging/Int     | stg_bakery__order_items referenced                  |                |                    |
| C03 | Staging/Int     | Business logic applied (dedup, filter, or refund)   |                |                    |
| C04 | Staging/Int     | Config blocks present in new SQL files              |                |                    |
| C05 | Staging/Int     | YAML schema files generated                         |                |                    |
| D01 | Data Contracts  | Unique key defined in mart schema                   |                |                    |
| D02 | Data Contracts  | Not-null constraints on required columns            |                |                    |
| D03 | Data Contracts  | Accepted values test for status                     |                |                    |
| E01 | DQ Checks       | Revenue > 0 check file present                      |                |                    |
| E02 | DQ Checks       | No null category check file present                 |                |                    |
| E03 | DQ Checks       | No duplicate items check file present               |                |                    |
| E04 | DQ Checks       | Severity levels assigned (warn vs error)            |                |                    |
| F01 | Edge Cases      | MoM growth nullability (new cats → null)            |                |                    |
| F02 | Edge Cases      | Partial refund handling (deduction, not exclusion)  |                |                    |
| F03 | Edge Cases      | Multi-category logic (line-item grain)              |                |                    |
| G01 | Test Generation | Unit tests written to disk                          |                |                    |
| G02 | Test Generation | Integration tests written to disk                   |                |                    |
| G03 | Test Generation | E2E tests written to disk                           |                |                    |
| G04 | Test Generation | dbt parse passes after generation                   |                |                    |

**RED score:   /29**
**GREEN score: /29**
**Skill delta: + checks fixed by skill**

Checks fixed by skill: ...
Checks still failing with skill: ...
```

> **Checks still failing with skill** = skill gaps. Each one maps to a rule in the SKILL.md that needs to be strengthened or added.
