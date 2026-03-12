# Skill Test Results: `processing-business-intent-to-dbt-artefacts`

**Test type:** RED vs GREEN (TDD for skills)
**Skill under test:** `.claude/skills/processing-business-intent-to-dbt-artefacts/SKILL.md`
**Domain inputs:** Business intent (monthly revenue report), metrics, rules, grain, edge cases

Both agents use `subagent_type: general-purpose` and produce a **plan only** (list of artefacts + intended SQL/YAML content) — no actual files are written to disk.

---

## Run History Progress

| Date | Run | Rubric | RED | GREEN | Skill delta | Key outcome |
|------|-----|--------|-----|-------|-------------|-------------|
| 2026-03-02 | Run 1 | 29 checks (plan-only) | 21/29 | 26/29 | +5 | Skill fixes orchestration sequencing and full DQ check coverage |
| 2026-03-02 | Run 2 | 29 checks (artefact-based) | 25/29 | 24/29 | -1 | RED outscores GREEN; skill led to missing composite unique key in mart YAML |

---

## Run 1

**Date:** 2026-03-02
**Model:** claude-sonnet-4-6

### Scorecard

| ID  | Group           | Check                                               | RED (no skill) | GREEN (with skill) |
|-----|-----------------|-----------------------------------------------------|----------------|--------------------|
| A01 | Orchestration   | Skill invokes 1.1 before 1.2                        | ❌             | ✅                 |
| A02 | Orchestration   | Skill always invokes 1.4 (DQ checks)                | ✅             | ✅                 |
| A03 | Orchestration   | Skill does NOT invoke 1.3 (Semantic Layer)          | ✅             | ✅                 |
| A04 | Orchestration   | Artefact plan produced before generation            | ✅             | ✅                 |
| A05 | Orchestration   | Skill references project_standards.md               | ❌             | ❌                 |
| B01 | Mart Model      | Correct grain (category × month)                    | ✅             | ✅                 |
| B02 | Mart Model      | All 4 metrics present                               | ✅             | ✅                 |
| B03 | Mart Model      | Status filter applied                               | ✅             | ✅                 |
| B04 | Mart Model      | Revenue > 0 filter applied                          | ✅             | ✅                 |
| B05 | Mart Model      | Config block present with materialization           | ❌             | ❌                 |
| C01 | Staging/Int     | stg_bakery__orders included                         | ✅             | ✅                 |
| C02 | Staging/Int     | stg_bakery__order_items included                    | ✅             | ✅                 |
| C03 | Staging/Int     | Business logic applied (dedup, filter, or refund)   | ✅             | ✅                 |
| C04 | Staging/Int     | Config blocks present                               | ❌             | ✅                 |
| C05 | Staging/Int     | YAML schema files generated                         | ✅             | ✅                 |
| D01 | Data Contracts  | Unique key defined in mart schema                   | ✅             | ✅                 |
| D02 | Data Contracts  | Not-null constraints on required columns            | ✅             | ✅                 |
| D03 | Data Contracts  | Accepted values test for status                     | ✅             | ✅                 |
| E01 | DQ Checks       | Revenue > 0 check present                           | ✅             | ✅                 |
| E02 | DQ Checks       | No null category check present                      | ❌             | ✅                 |
| E03 | DQ Checks       | No duplicate items check present                    | ❌             | ✅                 |
| E04 | DQ Checks       | Severity levels assigned (warn vs error)            | ❌             | ✅                 |
| F01 | Edge Cases      | MoM growth nullability handled (new cats → null)    | ✅             | ✅                 |
| F02 | Edge Cases      | Partial refund handling (deduction, not exclusion)  | ✅             | ✅                 |
| F03 | Edge Cases      | Multi-category logic (line-item grain addressed)    | ✅             | ✅                 |
| G01 | Test Generation | Unit tests generated for business rules             | ✅             | ✅                 |
| G02 | Test Generation | Integration tests generated for cross-model logic   | ✅             | ✅                 |
| G03 | Test Generation | E2E tests generated for pipeline validation         | ✅             | ✅                 |
| G04 | Test Generation | Test execution via unified `dbt test` mentioned     | ❌             | ❌                 |

**RED score:   21/29**
**GREEN score: 26/29**
**Skill delta: +5 checks fixed by skill**

Checks fixed by skill: A01, C04, E02, E03, E04

Checks still failing with skill: A05, B05, G04

---

### Failure Analysis

| ID  | Failure | Root cause | Suggested fix |
|-----|---------|------------|---------------|
| A05 | `project_standards.md` not referenced | File does not exist in the repo — agent cannot reference a non-existent file | Create `project_standards.md` at `.claude/skills/processing-business-intent-to-dbt-artefacts/references/project_standards.md` with naming conventions, layer rules, and config defaults |
| B05 | Mart SQL missing `{{ config() }}` block | Both RED and GREEN omit the config block from the mart SQL; materialization defaults to `view` silently | Add explicit rule to 1.1 skill: "Mart models must always include `{{ config(materialized='table') }}` as the opening block" |
| G04 | Unified `dbt test` execution not mentioned in plan | Skill says to execute `dbt test` after generation but plan-only mode makes this unclear; agents don't call it out | Add to SKILL.md execution flow: "Step 7 must be stated in every plan: 'Execute all tests via `dbt test --select +fct_<model_name>`'" |

---

## Run 2

**Date:** 2026-03-02
**Model:** claude-sonnet-4-6
**Evaluation mode:** Artefact-based (agents write actual files to disk in isolated temp folders)

### Scorecard

| ID  | Group           | Check                                               | RED (no skill) | GREEN (with skill) |
|-----|-----------------|-----------------------------------------------------|----------------|--------------------|
| A01 | Orchestration   | Skill invokes 1.1 before 1.2                        | ❌             | ❌                 |
| A02 | Orchestration   | Skill always invokes 1.4 (DQ checks)                | ✅             | ✅                 |
| A03 | Orchestration   | Skill does NOT invoke 1.3 (Semantic Layer)          | ✅             | ✅                 |
| A04 | Orchestration   | All 4 artefact categories present                   | ✅             | ✅                 |
| A05 | Orchestration   | Skill references project_standards.md               | ❌             | ❌                 |
| B01 | Mart Model      | Correct grain (category × month)                    | ✅             | ✅                 |
| B02 | Mart Model      | All 4 metrics present                               | ✅             | ✅                 |
| B03 | Mart Model      | Status filter applied                               | ✅             | ✅                 |
| B04 | Mart Model      | Revenue > 0 filter applied                          | ✅             | ✅                 |
| B05 | Mart Model      | Config block present with materialization           | ✅             | ✅                 |
| C01 | Staging/Int     | stg_bakery__orders referenced                       | ✅             | ✅                 |
| C02 | Staging/Int     | stg_bakery__order_items referenced                  | ✅             | ✅                 |
| C03 | Staging/Int     | Business logic applied (dedup, filter, or refund)   | ✅             | ✅                 |
| C04 | Staging/Int     | Config blocks present in new SQL files              | ❌             | ❌                 |
| C05 | Staging/Int     | YAML schema files generated                         | ✅             | ✅                 |
| D01 | Data Contracts  | Unique key defined in mart schema                   | ✅             | ❌                 |
| D02 | Data Contracts  | Not-null constraints on required columns            | ✅             | ✅                 |
| D03 | Data Contracts  | Accepted values test for status                     | ✅             | ✅                 |
| E01 | DQ Checks       | Revenue > 0 check file present                      | ✅             | ✅                 |
| E02 | DQ Checks       | No null category check file present                 | ✅             | ✅                 |
| E03 | DQ Checks       | No duplicate items check file present               | ✅             | ✅                 |
| E04 | DQ Checks       | Severity levels assigned (warn vs error)            | ✅             | ✅                 |
| F01 | Edge Cases      | MoM growth nullability (new cats → null)            | ✅             | ✅                 |
| F02 | Edge Cases      | Partial refund handling (deduction, not exclusion)  | ✅             | ✅                 |
| F03 | Edge Cases      | Multi-category logic (line-item grain)              | ✅             | ✅                 |
| G01 | Test Generation | Unit tests written to disk                          | ✅             | ✅                 |
| G02 | Test Generation | Integration tests written to disk                   | ✅             | ✅                 |
| G03 | Test Generation | E2E tests written to disk                           | ✅             | ✅                 |
| G04 | Test Generation | dbt parse passes after generation                   | ❌             | ❌                 |

**RED score:   25/29**
**GREEN score: 24/29**
**Skill delta: -1 (regression)**

Checks fixed by skill: none

Checks still failing with skill (vs RED baseline): A01, A05, C04, D01, G04

Regressions introduced by skill: D01 (GREEN omitted composite unique key from mart YAML; RED included it)

---

### Failure Analysis — Run 2

| ID  | Agent  | Failure | Root cause | Suggested fix |
|-----|--------|---------|------------|---------------|
| A01 | Both   | No explicit 1.1-before-1.2 execution log | Neither agent produced an execution log with skill ordering labels | Add to SKILL.md: "Begin your response with an Execution Log section listing: `1.1 → 1.2 → 1.4 → 2.1 → 2.2 → 2.3`" |
| A05 | Both   | `project_standards.md` not referenced | File does not exist | Create the file |
| C04 | Both   | Updated staging SQL has no `{{ config() }}` block | Staging models default to view; neither agent added a config block to the overridden staging file | Add rule: "Any new or modified staging SQL file must open with `{{ config(materialized='view') }}`" |
| D01 | GREEN  | Composite unique key absent from mart YAML | GREEN's `_mart_revenue.yml` had no model-level `data_tests` with a unique composite key; RED did include it | Add explicit rule to 1.1 skill: "Mart schema.yml must include a model-level `data_tests: - unique:` on the composite grain key `[category, month]`" |
| G04 | RED    | `dbt parse` fails — unit test on incremental model missing `is_incremental` override | `unit_tests.yml` had a unit test for `int_orders__revenue_by_category` (incremental model) without `overrides: is_incremental: false` | Add rule to 2.1 skill: "Unit tests on incremental models must include `overrides: { is_incremental: false }` in the YAML" |
| G04 | GREEN  | `dbt parse` fails — duplicate schema.yml entry for `int_orders__revenue_by_category` | `_mart_revenue.yml` included a stub model entry for the upstream intermediate model, conflicting with `_int_orders.yml` | Add rule to 1.1 skill: "Mart YAML files must not re-declare upstream intermediate or staging models — reference them only in SQL `ref()` calls" |
