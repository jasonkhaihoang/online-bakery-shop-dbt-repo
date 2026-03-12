# Generating dbt Mart Models and Data Contracts

**Skill Code:** 1.1
**Phase:** Phase 2 — Modeling & Data Quality
**Depends on:** `project_standards.md` + business intent from entry point
**Used by:** processing-business-intent

## Purpose

Design dimensional schema, generate Gold/Mart SQL models, and define business metrics with accompanying data contracts.

## When to Use

Use this skill when:
- Generating or modifying dimensional models (star schema, snowflake schema, OBT patterns)
- Creating Gold/Mart layer SQL models for final consumption
- Defining business metrics and their ownership
- Establishing data contracts (schema validation, cardinality, distribution rules)

**Always run first** in the modeling sequence before generating staging/intermediate models.

## Input Requirements

From entry point:
- Clear business intent description
- Business metrics and rules
- Grain of primary output
- Edge cases and data conditions

Decisions to make:
1. **Dimensional schema shape** — star schema, snowflake, OBT (one big table), or combination?
2. **Fact/dimension structure** — which tables are facts (measurable events) vs dimensions (context)?
3. **Primary/foreign keys** — define PKs/FKs for referential integrity
4. **Metric definitions** — name, formula, grain, filters, business owner
5. **Materialization strategy** — table, view, or incremental for each mart?
6. **Data contracts** — unique key constraints, distribution rules, value domain constraints

## Output Artefacts

- **Docs:** `/docs/mart_contract.md` (dimensional design, schema diagram, grain definitions)
- **Docs:** `/docs/metrics_mapping.md` (business metric definitions, ownership, formulas)
- **SQL:** `models/marts/**/*.sql` (complete Gold/Mart model files with `config()` blocks)
- **YAML:** `models/marts/**/schema.yml` (data contracts, tests, meta tags)
- **YAML:** `models/**/schema.yml` (metric tags and business logic ownership markers)

## User Confirmation

After generating, prompt user to confirm or override:
- Proposed dimensional schema shape and justification
- Metric definitions and ownership assignments
- Materialization choices (table vs view vs incremental)
- Data contract thresholds (e.g., max nulls %, cardinality bounds)

## Implementation Notes

- Generate complete model files with `{{ config() }}` blocks specifying materialization
- Include unique_key definition if materialization is incremental
- Document metric lineage and business rule enforcement in comments
- Align schema names with naming conventions in `project_standards.md`
- Use dbt refs for all upstream dependencies (staging/intermediate models)
