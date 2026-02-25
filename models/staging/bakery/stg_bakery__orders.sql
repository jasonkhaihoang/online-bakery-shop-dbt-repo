-- stg_bakery__orders.sql
-- Cleaned, typed order records. Entry point into dbt.

with

source as (
    select * from {{ source('bakery', 'brz_orders') }}
),

renamed as (
    select
        -- keys
        order_id,
        customer_id,
        -- properties
        status,
        cast(total_amount as numeric)   as total_amount,
        -- dates
        cast(order_date as date)        as order_date
    from source
)

select * from renamed
