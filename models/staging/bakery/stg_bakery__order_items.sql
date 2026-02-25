-- stg_bakery__order_items.sql
-- Cleaned, typed order line items. Entry point into dbt.

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
        -- measures
        quantity,
        cast(unit_price as numeric)     as unit_price
    from source
)

select * from renamed
