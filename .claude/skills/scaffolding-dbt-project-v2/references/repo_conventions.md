# repo_conventions.md

## Folder Tree

```
.
├── dbt_project.yml
├── packages.yml
├── selectors.yml
├── sqlfluff.cfg
├── profiles.yml              # local only, git-ignored
├── project_standards.md
├── source.md
├── docs/
├── macros/
│   ├── generate_schema_name.sql
│   └── ...
├── seeds/                    # reference/lookup CSVs
├── snapshots/                # SCD-2 snapshots (if used)
├── tests/                    # singular tests (cross-model)
└── models/
    ├── _templates/
    │   ├── staging_template.sql
    │   ├── intermediate_template.sql
    │   └── mart_template.sql
    ├── staging/
    │   └── {source}/
    │       ├── _source.yml
    │       ├── _{layer}_{source}.yml
    │       └── stg_{source}__{entity}.sql
    ├── intermediate/
    │   └── {concept}/
    │       ├── _{layer}_{concept}.yml
    │       └── int_{concept}__{descriptor}.sql
    └── marts/
        └── {consumer_area}/
            ├── _{layer}_{consumer_area}.yml
            ├── fct_{entity}.sql
            └── dim_{entity}.sql
```

## Naming Conventions

| Layer | Pattern | Example |
| --- | --- | --- |
| Staging | `stg_{source}__{entity}.sql` | `stg_salesforce__account.sql` |
| Intermediate | `int_{concept}__{descriptor}.sql` | `int_orders__completed.sql` |
| Mart (fact) | `fct_{entity}.sql` | `fct_revenue.sql` |
| Mart (dim) | `dim_{entity}.sql` | `dim_customer.sql` |
| YAML co-files | `_{layer}_{source_or_area}.yml` | `_stg_salesforce.yml` |
| Sources file | `_source.yml` | `_source.yml` |

- **snake_case** everywhere — files, folders, model names, column names
- **Double underscore** `__` separates source/concept from entity/descriptor
- One YAML co-file per folder — not one file per model

## DAG Dependency Rules

```
source()  ──►  Staging  ──►  Intermediate  ──►  Mart
                                            ▲
                        └── (Mart may ref Staging if no Intermediate needed)
```

1. `stg_*` → ONLY `source()` — never `ref()`
2. `int_*` → ONLY `ref()` to `stg_*` or `int_*`
3. `fct_*` / `dim_*` → ONLY `ref()` to `int_*` or `stg_*`
4. No backwards refs; no cross-domain refs

## Business Logic Placement

| Logic type | Layer |
| --- | --- |
| Cleaning (cast, rename, dedup) | Staging |
| Core business rules | Intermediate |
| Cross-source joins | Intermediate |
| Consumer-specific reshaping | Mart |
| Metric aggregations | Mart |

### Staging boundary — forbidden patterns

| Forbidden | Correct layer |
| --- | --- |
| Boolean flags derived from enums | Intermediate |
| String concatenations | Intermediate or Mart |
| Computed metrics | Intermediate |
| Business-rule filtering | Intermediate |

## Meta Keys

Every model must carry these `meta` keys (set at project level in `dbt_project.yml`, override per model as needed):

| Key | Type | Example |
| --- | --- | --- |
| `owner` | string | `"data-engineering"` |
| `domain` | string | `"sales"` |
| `sla` | string | `"07:00"` |
| `contains_pii` | boolean | `false` |

- Staging / Intermediate: set via `+meta` in `dbt_project.yml` — propagates to all models in the layer
- Mart (Gold): must also be declared explicitly per model alongside `contract: enforced: true`

## YAML Co-file Requirements

- One `.yml` per folder, shared by all models in that folder
- Each model entry requires a `description` and `not_null` + `unique` tests on PK
- Gold models additionally require: `columns` descriptions, explicit `meta`, `contract: enforced: true`, `data_tests`
- Use `data_tests:` not `tests:` in YAML
