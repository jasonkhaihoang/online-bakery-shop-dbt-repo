-- stg_bakery__customers.sql
-- Cleaned, typed, renamed customer records.
-- Grain: one row per customer.

with

source as (
    select * from {{ source('bakery', 'brz_customers') }}
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
        cast(created_at as date) as created_at
    from source
)

select * from renamed
