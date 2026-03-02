-- int_{concept}__{descriptor}.sql
-- Core business logic: {describe what this model produces}.
-- Grain: one row per {entity} ({pk_column} is the PK of this model).

{{
    config(
        materialized         = 'incremental',
        unique_key           = '{pk_column}',   -- PK of THIS model's output grain (not a FK)
        incremental_strategy = 'merge'
    )
}}

-- unique_key selection rule:
--   Use the column that uniquely identifies one row in the OUTPUT of this model.
--   It must be the same column that has not_null + unique tests in the model's YAML.
--   Never use a FK: FKs are not unique at the model grain and cause silent data loss on merge.

with

-- ── Event / transactional source CTEs ────────────────────────────────────────────────────────
-- These tables have an updated_at column. Apply is_incremental() so only rows changed since
-- the last run are processed.

{source_cte} as (
    select * from {{ ref('stg_{source}__{entity}') }}
    {% if is_incremental() %}
        where updated_at > (select max(updated_at) from {{ this }})
    {% endif %}
),

-- ── Lookup / reference source CTEs ───────────────────────────────────────────────────────────
-- Static reference tables have no updated_at to filter on.
-- DO NOT apply is_incremental() to these CTEs — all rows must always be available for joins.

{lookup_cte} as (
    select * from {{ ref('stg_{source}__{lookup_entity}') }}
),

transformed as (
    select
        {pk_column},
        {fk_column},
        {column_name},
        {col_a} * {col_b}                       as {derived_metric}

    from {source_cte}
    left join {lookup_cte}
        on {source_cte}.{join_key} = {lookup_cte}.{join_key}
)

select * from transformed
