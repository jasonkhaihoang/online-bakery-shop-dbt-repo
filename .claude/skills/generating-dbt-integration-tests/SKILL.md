# Generating dbt Integration Tests

**Skill Code:** 2.2
**Phase:** Phase 2 — Business Logic Testing
**Depends on:** 1.1, 1.2 (models generated)
**Used by:** processing-business-intent-to-dbt-artefacts
**Mandatory:** Yes, always invoked by entry point

## Purpose

Generate integration tests to validate relationships and data consistency across multiple models within the same business intent. Tests are executed by the entry point's unified `dbt test` command to ensure cross-model integrity.

## When to Use

This skill is **always invoked** by the entry point as part of the mandatory Phase 2 execution flow. It:
- Validates cross-model relationships and cardinality constraints
- Tests multi-model invariants (e.g., sum of line items = order total, customer count matches)
- Ensures reconciliation between facts and dimensions
- Validates referential integrity across layers
- **Tests are executed by entry point's unified `dbt test` command**

## Input Requirements

From entry point and 1.1, 1.2:
- Model relationships and dimensional structure
- Business invariants and reconciliation logic
- Grain definitions and join logic

Decisions to make:
1. **Cross-model relationships to test** — which models depend on each other?
2. **Cardinality rules** — e.g., fact-to-dimension ratios, one-to-many constraints?
3. **Reconciliation logic** — e.g., line-item sum matches order total, customer counts match?
4. **Severity assignment** — which invariants are errors vs warnings?
5. **Integration test cases** — which cross-model scenarios to validate?

## Output Artefacts

- **Docs:** `/docs/testing/integration_tests.md` (cross-model invariants, reconciliation rules, cardinality checks)
- **Config:** `selectors.yml` (selectors for integration test groups by domain/layer)
- **SQL:** `tests/**.sql` (reconciliation queries, cardinality checks, multi-model invariants)
- **Macros:** `macros/**` (reusable reconciliation and join helper macros)

## User Confirmation

After generating, prompt user to confirm or override:
- Proposed cross-model relationships and cardinality rules
- Reconciliation logic and validation queries
- Severity levels for each invariant
- Additional cross-model scenarios to validate

## Implementation Notes

- Create SQL tests that validate relationships between facts and dimensions
- Test referential integrity (foreign keys exist in dimension tables)
- Implement reconciliation queries (totals, counts) between layers
- Use reusable macros for common patterns (e.g., "verify_fact_dimension_cardinality")
- Document each test's business intent and why it matters
- Test across layer boundaries (staging → intermediate, intermediate → mart)
- Consider data volume and test performance; use sampling for large tables if needed
- Tag tests by domain/model pair for easy selection
