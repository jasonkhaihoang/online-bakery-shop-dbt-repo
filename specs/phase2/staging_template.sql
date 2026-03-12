-- stg_{source}__{entity}.sql
-- Staging: cast, rename, and passthrough only — no derived columns, no boolean flags.
-- Grain: one row per source {entity} record.

with

source as (
    select * from {{ source('{source}', 'brz_{entity}') }}
),

renamed as (
    select
        -- keys
        {pk_column}                             as {pk_column},

        -- foreign keys
        {fk_column}                             as {fk_column},

        -- properties
        {column_name},
        cast({column_name} as timestamp)        as {column_name},
        cast(created_at as timestamp)           as created_at,
        cast(updated_at as timestamp)           as updated_at

    from source
)

select * from renamed
