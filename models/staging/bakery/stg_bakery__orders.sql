-- stg_bakery__orders.sql
-- Cleaned, typed, renamed order records.
-- Grain: one row per order.

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
        cast(order_date as date) as order_date,
        status,
        cast(total_amount as numeric) as total_amount
    from source
)

select * from renamed
