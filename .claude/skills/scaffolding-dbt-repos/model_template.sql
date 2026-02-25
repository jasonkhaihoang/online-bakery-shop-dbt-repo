-- {model_name}.sql
-- Brief description of what this model does.
-- Layer: {staging|intermediate|mart}
-- Grain: {grain_description}

-- ============================================================
-- STAGING models: use source() — never ref()
-- INTERMEDIATE / MART models: use ref() — never source()
-- Replace the source CTE below accordingly:
--
--   Staging:            select * from {{ source('source_name', 'brz_table') }}
--   Intermediate/Mart:  select * from {{ ref('upstream_model') }}
-- ============================================================

with

source as (
    -- STAGING:  select * from {{ source('source_name', 'brz_table') }}
    -- INT/MART: select * from {{ ref('upstream_model') }}
),

transformed as (
    select
        -- keys

        -- properties

        -- timestamps

    from source
),

final as (
    select * from transformed
)

select * from final
