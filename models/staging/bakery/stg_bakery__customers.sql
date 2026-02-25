-- stg_bakery__customers.sql
-- Cleaned, typed customer records. Entry point into dbt.

with

source as (
    select * from {{ source('bakery', 'raw_customers') }}
),

renamed as (
    select
        -- keys
        customer_id,
        -- properties
        first_name,
        last_name,
        email,
        city,
        -- timestamps
        cast(created_at as date)    as created_at
    from source
)

select * from renamed
