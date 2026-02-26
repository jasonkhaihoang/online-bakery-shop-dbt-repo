# repo_conventions.md

## Folder Tree

```
.
├── dbt_project.yml
├── packages.yml
├── selectors.yml
├── sqlfluff.cfg
├── profiles.yml              # local only, git-ignored
├── docs/
│   └── repo_conventions.md
├── macros/
│   ├── generate_schema_name.sql
│   └── ...
├── seeds/                    # reference/lookup CSVs
├── snapshots/                # SCD-2 snapshots (if used)
├── tests/                    # singular tests (cross-model)
└── models/
    ├── staging/
    │   ├── salesforce/
    │   │   ├── _stg_salesforce.yml
    │   │   ├── stg_salesforce__account.sql
    │   │   └── stg_salesforce__opportunity.sql
    │   └── stripe/
    │       ├── _stg_stripe.yml
    │       ├── stg_stripe__charge.sql
    │       └── stg_stripe__customer.sql
    ├── intermediate/
    │   ├── finance/
    │   │   ├── _int_finance.yml
    │   │   ├── int_revenue__recognized.sql
    │   │   └── int_payments__joined.sql
    │   └── customers/
    │       ├── _int_customers.yml
    │       └── int_customers__unified.sql
    └── marts/
        ├── finance/
        │   ├── _mart_finance.yml
        │   ├── fct_revenue.sql
        │   └── dim_payment_method.sql
        └── customers/
            ├── _mart_customers.yml
            ├── fct_customer_orders.sql
            └── dim_customer.sql
```

### dbt_project.yml — use the template, nothing more

Copy `dbt_project.template.yml` from the skill. Do not add:
- Path declarations (`model-paths`, `seed-paths`, `macro-paths`, etc.) — these are dbt defaults
- A `seeds:` config block — seed schema is handled by `generate_schema_name.template.sql`
- A `vars:` block with meta defaults — dbt does not render `{{ var() }}` inside `+meta` config blocks

Required sections only: `models:` (per-layer materialisation, schema, tags, meta), `snapshots:`,
`tests:`, and `clean-targets:`.

## Naming Conventions

| Layer | Pattern | Example |
| --- | --- | --- |
| Staging | `stg_{source}__{entity}.sql` | `stg_salesforce__account.sql` |
| Intermediate | `int_{concept}__{descriptor}.sql` | `int_customers__unified.sql`, `int_orders__completed.sql`, `int_customers__order_history.sql` |
| Mart (fact) | `fct_{entity}.sql` | `fct_revenue.sql` |
| Mart (dim) | `dim_{entity}.sql` | `dim_customer.sql` |
| YAML schemas | `_{layer}_{source_or_area}.yml` | `_stg_salesforce.yml` |
| Sources | `_source.yml` | `_source.yml` |

### General rules

- **snake_case** everywhere — files, folders, model names, column names.
- **Double underscore** `__` separates source/concept from entity/descriptor.
- Intermediate descriptor can be a verb, past participle, or noun phrase — pick what best describes the transformation (e.g. `completed`, `unified`, `order_history`).
- **Pluralisation:** entity names are plural (`accounts`, `charges`) unless a widely-used singular term is more natural (`revenue`).
- Source abbreviations: use full source name (e.g. `salesforce`, `stripe`), not abbreviations, unless the name exceeds ~15 characters.

## DAG Dependency Rules

```
source()  ──►  Staging  ──►  Intermediate  ──►  Mart
                        ▲
                        └── (Mart may ref Staging
                             if no Intermediate needed)
```

### Enforcement rules (machine-readable)

1. `stg_*` models may ONLY use `source()` to reference bronze tables — never `ref()`.
2. `int_*` models may ONLY `ref()` models prefixed `stg_*` or `int_*`.
3. `fct_*` / `dim_*` models may ONLY `ref()` models prefixed `int_*` or `stg_*`.
4. **No backwards refs.** No downstream layer may be referenced by an upstream layer.
5. **No cross-domain refs** via `ref()`. Cross-domain dependencies require dbt mesh / packages (future).

## Business Logic Placement

| Logic type | Layer | Example |
| --- | --- | --- |
| Cleaning (cast, rename, dedup) | Staging | Cast `created_at` from string to timestamp |
| Core business rules | **Intermediate** | Revenue recognition, identity resolution |
| Cross-source joins | **Intermediate** | Join Salesforce accounts with Stripe customers |
| Consumer-specific reshaping | **Mart** | Daily revenue rollup for exec dashboard |
| Metric aggregations | **Mart** | Trailing 7-day active users |

### Staging boundary — what is NOT allowed

Staging models are a strict passthrough. The following are forbidden:

| Forbidden pattern | Example | Correct layer |
| --- | --- | --- |
| Boolean flags derived from enums | `status = 'completed' as is_completed` | Intermediate (filter directly: `where status = 'completed'`) |
| String concatenations | `first_name \|\| ' ' \|\| last_name as full_name` | Intermediate or Mart |
| Computed metrics | `quantity * unit_price as line_total` | Intermediate |
| Business-rule filtering | `where status = 'completed'` | Intermediate |

**Why:** a flag like `is_completed` in staging means the revenue recognition rule is now split
across two files. If the status value ever changes, intermediate silently returns wrong data
because it still references the stale flag. Keeping the filter in intermediate makes the rule
visible and traceable in one place.

### Intermediate materialization — incremental (merge)

Intermediate models use `+materialized: incremental` with `incremental_strategy: merge`.
Each model must declare its own `unique_key` matching the model's primary or surrogate key:

```jinja
{{ config(
    materialized         = 'incremental',
    unique_key           = 'order_item_id',   -- primary key of this model
    incremental_strategy = 'merge'
) }}
```

The incremental filter (processing only new/changed rows) goes on the `source` CTE:

```jinja
{% if is_incremental() %}
    where updated_at > (select max(updated_at) from {{ this }})
{% endif %}
```

## Meta Keys

Every model should carry these four `meta` keys:

| Key | Type | Description | Example |
| --- | --- | --- | --- |
| `domain` | string | Business domain | `finance` |
| `owner` | string | Responsible team or person | `data-eng` |
| `pii` | boolean | Contains personally identifiable info | `true` / `false` |
| `tier` | int | Business criticality (1=critical, 3=exploratory) | `1` |

**How to satisfy this requirement by layer:**

- **Staging / Intermediate:** set `+meta` once in `dbt_project.yml` under the layer path. This propagates to all models in that layer and satisfies the requirement — no need to repeat `meta:` in individual model YAMLs unless a model overrides a value (e.g. `pii: true` for a specific model).
- **Mart (Gold):** `meta` must be declared explicitly in each model's YAML block (in addition to any `+meta` defaults), alongside `contract: enforced: true`, `columns` descriptions, and `data_tests`.

## YAML Co-file Requirements

- **Every model** must be described in its layer's co-located `.yml` file (one `.yml` per folder, shared by all models in that folder — not one file per model).
- Each model entry requires a `description` and at minimum `not_null` / `unique` tests on primary keys.
- Gold/contracted models additionally require: `columns` descriptions, explicit `meta` (all four keys), `contract: enforced: true`, and `data_tests`.
- `_source.yml` files belong inside `staging/{source}/` subfolders, declaring the bronze tables consumed via `source()`.

### Sentinel tests on filtered intermediate models

When an intermediate model filters to a single status value (e.g. `WHERE status = 'completed'`),
add an `accepted_values` test on that column:

```yaml
- name: status
  description: Always 'completed' in this model by construction.
  data_tests:
    - not_null
    - accepted_values:
        values: ['completed']
```

This sentinel turns a silent failure (filter accidentally removed → inflated revenue) into a
`dbt test` failure caught before the model reaches consumers.
