-- stg_bakery__order_items.sql
-- Cleaned, typed, renamed order line items.
-- Grain: one row per order line item.

with

source as (
    select * from {{ source('bakery', 'brz_order_items') }}
),

renamed as (
    select
        -- keys
        order_item_id,
        order_id,
        product_id,
        -- properties
        quantity,
        cast(unit_price as numeric) as unit_price
    from source
)

select * from renamed
