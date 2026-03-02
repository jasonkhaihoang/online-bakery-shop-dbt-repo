-- int_orders__revenue_by_category.sql
-- Line-item level revenue facts filtered to qualifying order statuses,
-- with product category resolved and partial-refund deductions applied.
--
-- Business rules enforced here:
--   1. Order status must be in ('completed', 'shipped') — pending/processing excluded.
--   2. net_line_total must be > 0 — cancelled or fully-refunded line items excluded.
--   3. product category must not be null — orphaned line items excluded.
--   4. Duplicate order_item_id within an order is guarded via the unique_key config.
--
-- Grain: one row per qualifying order line item.

{{
    config(
        materialized         = 'incremental',
        unique_key           = 'order_item_id',
        incremental_strategy = 'merge'
    )
}}

with

orders as (
    select
        order_id,
        customer_id,
        order_date,
        status
    from {{ ref('stg_bakery__orders') }}
    where status in ('completed', 'shipped')
    {% if is_incremental() %}
        and order_date > (select max(order_date) from {{ this }})
    {% endif %}
),

order_items as (
    select
        order_item_id,
        order_id,
        product_id,
        quantity,
        unit_price,
        refunded_amount,
        gross_line_total,
        net_line_total
    from {{ ref('stg_bakery__order_items') }}
),

products as (
    select
        product_id,
        product_name,
        -- Gracefully handle retroactive category name changes: the value
        -- from the products table at query time is used as-is.
        category
    from {{ ref('stg_bakery__products') }}
    -- Exclude products with a null category so the grain is always clean.
    where category is not null
),

joined as (
    select
        -- keys
        oi.order_item_id,
        oi.order_id,
        o.customer_id,
        oi.product_id,
        -- order properties
        o.order_date,
        o.status,
        -- product attributes
        p.product_name,
        p.category                                        as product_category,
        -- line item financials
        oi.quantity,
        oi.unit_price,
        oi.refunded_amount,
        oi.gross_line_total,
        oi.net_line_total
    from orders as o
    inner join order_items as oi
        on o.order_id = oi.order_id
    inner join products as p
        on oi.product_id = p.product_id
),

filtered as (
    select *
    from joined
    -- Business rule: revenue must be positive; fully refunded lines excluded.
    where net_line_total > 0
      -- Defensive null guard even though the products join already excludes nulls.
      and product_category is not null
)

select * from filtered
