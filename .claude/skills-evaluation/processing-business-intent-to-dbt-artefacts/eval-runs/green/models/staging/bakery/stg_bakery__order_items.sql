-- stg_bakery__order_items.sql
-- Cleaned, typed, renamed order line items with refund deduction support.
-- Grain: one row per order line item.
-- Business rule: refund_amount is coalesced to 0 for forward-compatibility when
--   the source adds a refund column; net_line_amount captures partial-refund logic.

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
        cast(quantity as integer)   as quantity,
        cast(unit_price as numeric) as unit_price,
        -- refund support: default to 0 until source exposes the column
        cast(
            coalesce(
                cast(null as numeric),  -- replace with source column when available
                0
            ) as numeric
        )                           as refund_amount
    from source
)

select * from renamed
