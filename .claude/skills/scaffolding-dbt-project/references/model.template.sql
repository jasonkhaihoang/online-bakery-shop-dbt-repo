-- {model_name}.sql
-- {brief description of what this model produces}
-- Layer: {staging | intermediate | mart}
-- Grain: {one row per ...}

-- ============================================================
-- REF GUIDE
--   Staging:      select * from {{ source('source_name', 'brz_table') }}
--   Intermediate: select * from {{ ref('stg_model') }}  or ref('int_model')
--   Mart:         select * from {{ ref('int_model') }}
--
-- Materialization guide (set in config block below):
--   Staging:      view  (default — no config block needed)
--   Intermediate: incremental + unique_key  (see config block)
--   Mart:         table (default — no config block needed)
-- ============================================================

-- INTERMEDIATE ONLY: remove this config block for staging and mart models
{{
    config(
        materialized         = 'incremental',
        unique_key           = '{primary_or_surrogate_key_column}',
        incremental_strategy = 'merge'
    )
}}

with

source as (
    select * from {{ ref('{upstream_model}') }}
    -- STAGING only: replace ref() above with source():
    --   select * from {{ source('{source_name}', '{brz_table}') }}

    -- INCREMENTAL only: append this block to process new rows only
    {% if is_incremental() %}
        where updated_at > (select max(updated_at) from {{ this }})
    {% endif %}
),

transformed as (
    -- Cast, rename, and apply business-rule filters here.
    -- Staging: cast + rename only — no derived columns or filters.
    -- Intermediate: apply WHERE filters for business rules (e.g. status = 'completed').
    select
        -- keys
        {pk_column}                             as {pk_column},

        -- foreign keys
        {fk_column},

        -- properties
        {column_name},
        cast({column_name} as {type})           as {column_name},

        -- computed (intermediate / mart only — never staging)
        {col_a} * {col_b}                       as {derived_metric}

    from source
    where
        -- business-rule filter (intermediate layer — omit in staging and mart)
        {status_column} = '{target_value}'
        -- and {other_filter}
),

aggregated as (
    -- Use this CTE when the model needs to roll up rows (GROUP BY).
    -- Omit entirely for passthrough models (staging, most intermediate enrichments).
    select
        {group_key},
        count({pk_column})                      as {count_metric},
        sum({amount_column})                    as {sum_metric},
        min({date_column})                      as {min_date},
        max({date_column})                      as {max_date}

    from transformed
    group by
        {group_key}

    having
        -- optional: filter groups after aggregation
        count({pk_column}) > 0
),

final as (
    -- Final selection or join. Keep this CTE even if it is just "select * from …"
    -- so the shape of the output is always in one predictable place.
    select * from aggregated
    -- or: select * from transformed   (when no aggregation needed)
)

select * from final
