# Generating Data Quality Checks

**Skill Code:** 1.4
**Phase:** Phase 2 — Modeling & Data Quality
**Depends on:** 1.1, 1.2 (modeling complete)
**Used by:** processing-business-intent-to-dbt-artefacts
**Execution in Phase 2:** Generated only (not executed; reserved for production monitoring)

## Purpose

Generate data quality checks and validation rules that protect data integrity across the pipeline from staging through marts. DQ checks are generated during Phase 2 for production use but not executed in development.

## When to Use

Use this skill when:
- Implementing data quality checks (freshness, nulls, duplicates, volume anomalies)
- Defining failure thresholds and severity levels (warn vs error)
- Establishing pre-publish and post-publish checks
- Selecting DQ tooling strategy (dbt built-in tests, Great Expectations, dbt_expectations, custom macros)

**Always run after modeling (1.1, 1.2)** to ensure all models have DQ protection. DQ checks are generated for production monitoring but NOT executed during Phase 2 development.

## Input Requirements

From 1.1, 1.2 (models defined):
- Model list with columns and data types
- Business rules and constraints (e.g., revenue > 0, status in allowed set)
- Edge cases to cover

Decisions to make:
1. **DQ dimensions to validate** — freshness, nulls, duplicates, volume, distribution, relationships?
2. **Failure thresholds per check** — e.g., max 5% nulls, volume must be within ±20% of baseline
3. **Severity levels** — warn (log only) vs error (block publish)?
4. **Check placement** — pre-publish (before data reaches marts) vs post-publish (after)?
5. **DQ tooling** — dbt generic tests, dbt_expectations, custom macros, or external tool?

## Output Artefacts

- **Docs:** `/docs/dq/core_checks.md` (DQ strategy, check catalog, thresholds, severity mapping)
- **Config:** `dbt_project.yml` (DQ vars, threshold definitions, check configuration)
- **Config:** `selectors.yml` (tag-based selectors for `pre_publish_checks`, `post_publish_checks`)
- **YAML:** `models/**/schema.yml` (generic tests: unique, not_null, accepted_values, relationships)
- **SQL:** `tests/**.sql` (singular custom DQ checks for volume anomaly, freshness, distribution)

## User Confirmation

After generating, prompt user to confirm or override:
- Proposed DQ checks and their placement (pre vs post-publish)
- Failure thresholds and severity levels
- Check coverage (which models/columns have protection)
- DQ tooling selection and integration points

## Implementation Notes

- Embed column-level tests in model YAML files (unique, not_null, accepted_values)
- Use dbt_expectations for distribution and volume checks
- Create custom SQL tests for business-specific rules (e.g., revenue > 0, no duplicates per customer per day)
- Document failure thresholds in vars section of `dbt_project.yml`
- Use selectors to group pre/post-publish checks for automation
- Link DQ checks back to business rules from entry point
- Consider performance: place expensive checks only at critical points
