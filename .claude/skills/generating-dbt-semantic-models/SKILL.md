# Generating dbt Semantic Models

**Skill Code:** 1.3
**Phase:** Phase 2 — Modeling & Data Quality
**Depends on:** 1.1 (generating-dbt-mart-models-and-data-contracts)
**Used by:** processing-business-intent
**Optional:** Yes, only if using dbt Semantic Layer

## Purpose

Generate dbt Semantic Layer models and metrics store to serve metrics and dimensions to downstream BI tools and consumers.

## When to Use

Use this skill when:
- Implementing dbt Semantic Layer for metrics governance and self-service consumption
- Defining metric implementations with formulas, filters, and aggregation logic
- Establishing metric ownership and versioning policy
- Building a metrics registry for BI/analytics tools to query

**This is optional.** Only invoke if the project uses dbt Semantic Layer for metrics serving.

## Input Requirements

From 1.1 (dimensional design):
- Fact tables and dimensions identified
- Business metrics and their definitions
- Metric ownership and stewardship

Decisions to make:
1. **Semantic model mappings** — which facts and dimensions map to semantic models?
2. **Metric implementations** — for each business metric, define formula, dimensions, filters
3. **Metric ownership** — who owns each metric? Governance policy?
4. **Aggregation logic** — sum, count, avg, max, etc. per metric?
5. **Time dimensions** — date grains to expose (day, week, month, quarter, year)?

## Output Artefacts

- **YAML:** `metrics.yml` (metrics store with formula, filters, dimensions, ownership)
- **YAML:** `semantic_models.yml` (semantic model definitions and entity mappings, if Semantic Layer used)
- **Docs:** `/docs/metrics_registry.md` (metrics governance, ownership, SLAs, versioning policy)

## User Confirmation

After generating, prompt user to confirm or override:
- Proposed semantic model mappings from facts/dimensions
- Metric implementations (formulas, filters, dimensions)
- Ownership assignments and governance policy
- Exposure definitions for downstream BI tools

## Implementation Notes

- Use dbt Semantic Layer YAML specification
- Document metric definitions with lineage to source facts/dimensions
- Include filter logic for data quality exclusions (e.g., test records, returns)
- Define time dimensions and grain options
- Establish versioning policy for metric changes
- Tag metrics with business area and ownership
