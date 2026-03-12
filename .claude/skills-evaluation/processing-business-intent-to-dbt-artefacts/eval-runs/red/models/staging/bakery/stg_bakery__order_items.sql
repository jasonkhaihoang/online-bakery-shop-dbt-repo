-- stg_bakery__order_items.sql
-- Cleaned, typed, renamed order line items with refund support.
-- Grain: one row per order line item.
--
-- NOTE: refunded_amount is cast to numeric with a 0 default so downstream
-- models can safely deduct partial refunds without null-handling at each
-- consumption layer.

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
        cast(unit_price as numeric)                                      as unit_price,
        cast(coalesce(refunded_amount, 0) as numeric)                    as refunded_amount,
        cast(quantity * unit_price as numeric)                           as gross_line_total,
        cast(quantity * unit_price - coalesce(refunded_amount, 0) as numeric) as net_line_total
    from source
)

select * from renamed
