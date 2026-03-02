-- stg_salesforce__account.sql
-- Staging: cast, rename, and passthrough only — no derived columns, no boolean flags.
-- Grain: one row per source account record.

with

source as (
    select * from {{ source('salesforce', 'brz_accounts') }}
),

renamed as (
    select
        -- keys
        account_id                              as account_id,

        -- foreign keys
        owner_id                                as owner_id,

        -- properties
        account_name                            as account_name,
        industry,
        account_type,
        cast(created_at as timestamp)           as created_at,
        cast(updated_at as timestamp)           as updated_at,
        is_deleted

    from source
)

select * from renamed
