# Skill Test Results: `processing-business-intent-to-dbt-artefacts`

**Test type:** RED vs GREEN (TDD for skills)
**Skill under test:** `.claude/skills/processing-business-intent-to-dbt-artefacts/SKILL.md`
**Domain inputs:** Business intent (monthly revenue report), metrics, rules, grain, edge cases

Both agents use `subagent_type: general-purpose` and produce a **plan only** (list of artefacts + intended SQL/YAML content) — no actual files are written to disk.

---

## Run History Progress

| Date | Run | Rubric | RED | GREEN | Skill delta | Key outcome |
|------|-----|--------|-----|-------|-------------|-------------|
| 2026-03-02 | Run 1 | 29 checks | 21/29 | 26/29 | +5 | Skill fixes orchestration sequencing and full DQ check coverage |

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
