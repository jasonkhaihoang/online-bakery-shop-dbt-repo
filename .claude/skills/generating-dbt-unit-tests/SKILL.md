# Generating dbt Unit Tests

**Skill Code:** 2.1
**Phase:** Phase 2 — Business Logic Testing
**Depends on:** 1.1, 1.2 (models generated)
**Used by:** processing-business-intent-to-dbt-artefacts
**Mandatory:** Yes, always invoked by entry point

## Purpose

Generate unit tests for model business rules and column constraints based on requirements from the entry point. Tests are executed by the entry point's unified `dbt test` command to validate logical correctness.

## When to Use

This skill is **always invoked** by the entry point as part of the mandatory Phase 2 execution flow. It:
- Generates unit tests for model business logic and column constraints
- Tests business rules in isolation (e.g., revenue > 0, no duplicates)
- Validates data transformations and calculations
- Builds test fixtures for edge cases
- **Tests are executed by entry point's unified `dbt test` command**

## Input Requirements

From entry point and 1.1, 1.2:
- Business rules and constraints from intent
- Edge cases to cover
- Model definitions and column specs

Decisions to make:
1. **Test package selection** — dbt_utils, dbt_expectations, Great Expectations, custom macros?
2. **Fixture strategy** — use seeds for test data, reference production samples, or synthetic data?
3. **Unit test cases** — which business rules and edge cases to cover with unit tests?
4. **Test coverage requirements** — e.g., 80%+ of business rules covered?
5. **Assertion library** — use dbt's built-in tests, custom SQL, or external assertions?

## Output Artefacts

- **Docs:** `/docs/testing/unit_tests.md` (test strategy, coverage metrics, edge case catalog)
- **Config:** `packages.yml` (test package dependencies: dbt_expectations, dbt_utils, etc.)
- **YAML:** `models/**/schema.yml` (generic tests: unique, not_null, accepted_values, custom assertions)
- **SQL:** `seeds/**.csv` (test data fixtures for edge cases, if applicable)
- **SQL/Macros:** `macros/tests/**.sql` (custom assertion macros for business-specific logic)

## User Confirmation

After generating, prompt user to confirm or override:
- Proposed unit test cases and edge cases covered
- Test package selection and dependencies
- Fixture strategy and test data
- Coverage expectations and acceptance criteria

## Implementation Notes

- Write isolated unit tests that validate single business rules
- Use test seeds for reproducible, edge case scenarios (null values, boundary conditions, etc.)
- Document test intent and what business rule it validates
- Create reusable test macros for common business logic (e.g., "no negative revenue", "status in allowed set")
- Link unit tests back to business rules in entry point intent
- Aim for coverage of all critical business rules, especially revenue and status fields
- Use dbt test --select flags for fast, targeted testing during development
