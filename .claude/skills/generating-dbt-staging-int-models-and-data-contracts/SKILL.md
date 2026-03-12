# Generating dbt Staging & Intermediate Models and Data Contracts

**Skill Code:** 1.2
**Phase:** Phase 2 — Modeling & Data Quality
**Depends on:** 1.1 (generating-dbt-mart-models-and-data-contracts)
**Used by:** processing-business-intent

## Purpose

Generate staging and intermediate SQL model files with data contracts that feed the Gold/Mart models designed in 1.1.

## When to Use

Use this skill after completing the dimensional design (1.1) to:
- Generate SQL models for the staging layer (source cleaning and renaming)
- Generate SQL models for the intermediate layer (business logic and calculations)
- Define data contracts for each model (uniqueness, nullability, cardinality)
- Establish materialization strategies (view, table, incremental)
- Configure incremental logic with merge strategies and state-based filtering

## Input Requirements

From 1.1 (dimensional design):
- Mart model names and dimensions/facts structure
- Upstream dependencies and data lineage
- Business metrics and grain definitions

Decisions to make:
1. **Required staging/intermediate models** — which source tables and transformations are needed?
2. **Materialization strategy per model** — view, table, or incremental?
3. **Unique key definition** — if incremental, what identifies a unique record?
4. **Merge strategy** — for incremental models, is this append-only or upsert logic?
5. **Data contracts per model** — unique key constraints, nullability rules, distribution bounds
6. **State-based filtering** — use `:state:modified+` for smart dbt selection?

## Output Artefacts

- **SQL:** `models/staging/**/*.sql` (complete model files with `config()` blocks)
- **SQL:** `models/intermediate/**/*.sql` (complete model files with `config()` blocks)
- **YAML:** `models/staging/**/_*.yml` (schema definitions, contracts, tests)
- **YAML:** `models/intermediate/**/_*.yml` (schema definitions, contracts, tests)
- **Docs:** inline comments documenting materialization choices and business logic enforcement

## User Confirmation

After generating, prompt user to confirm or override:
- Proposed staging/intermediate model list and justification
- Materialization choices (view vs table vs incremental) for each model
- Incremental strategies and merge logic
- Unique key definitions
- Data contract definitions (nullability, cardinality, distribution rules)

## Implementation Notes

- Generate complete model files with `{{ config() }}` blocks
- For incremental models, include `unique_key`, `on_schema_change`, and `incremental_strategy`
- Use `{{ incremental_filter() }}` macro or `dbt_utils` patterns for efficient incremental builds
- Document business logic in SQL comments (revenue > 0 rules, dedupe logic, null handling)
- Align with naming conventions from `project_standards.md`
- Reference source tables via `source()` function, intermediate tables via `ref()`
