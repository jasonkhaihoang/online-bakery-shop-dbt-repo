# Generating dbt E2E Tests

**Skill Code:** 2.3
**Phase:** Phase 2 — Business Logic Testing
**Depends on:** 1.1, 1.2 (models generated)
**Used by:** processing-business-intent-to-dbt-artefacts
**Mandatory:** Yes, always invoked by entry point

## Purpose

Generate end-to-end tests to validate the full pipeline from raw source through to final mart output against known reference values. Tests are executed by the entry point's unified `dbt test` command to ensure pipeline correctness.

## When to Use

This skill is **always invoked** by the entry point as part of the mandatory Phase 2 execution flow. It:
- Validates critical business journeys end-to-end (raw → staging → intermediate → mart)
- Compares pipeline results against reference datasets or golden records
- Tests data quality across the entire transformation chain
- Validates business logic at multiple stages of the pipeline
- **Tests are executed by entry point's unified `dbt test` command**

## Input Requirements

From entry point and 1.1, 1.2:
- Critical business journeys to validate (e.g., order flow, customer lifetime value calculation)
- Reference datasets or golden records
- Expected outputs and tolerance thresholds

Decisions to make:
1. **Critical business journeys to validate** — which end-to-end flows are most important?
2. **Reference datasets** — do we have golden records or baseline data to compare against?
3. **Tolerance thresholds** — what % variance is acceptable between pipeline and reference?
4. **Validation environment** — do we test in dev, staging, prod, or all?
5. **Validation frequency** — one-time validation or ongoing monitoring?

## Output Artefacts

- **Docs:** `/docs/testing/e2e_validation.md` (E2E scenarios, reference data strategy, validation checkpoints)
- **Config:** `selectors.yml` (selectors for E2E test groups)
- **SQL:** `models/validation/**.sql` (validation queries that compare pipeline output to reference)
- **SQL/YAML:** `tests/**.sql` and `models/validation/**/schema.yml` (E2E test definitions)

## User Confirmation

After generating, prompt user to confirm or override:
- Proposed critical business journeys and validation scenarios
- Reference datasets and how to obtain them
- Tolerance thresholds for acceptable variance
- Validation environment and frequency
- Validation checkpoints (which layers to validate)

## Implementation Notes

- Create validation models that aggregate pipeline results by critical dimension
- Build reference queries against source data to establish baseline expectations
- Use tolerance thresholds to handle minor discrepancies (e.g., rounding, timing)
- Document why each journey is critical and what would break if it failed
- Consider performance: use sampling or recent data windows for large datasets
- Store validation results for audit trail and trend analysis
- Automate E2E tests in CI/CD pipeline to catch regressions early
- Use dbt seeds or external tables for reference data lookup
