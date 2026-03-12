-- int_orders__revenue_by_category.sql
-- Line-item grain revenue attributed to product category for eligible orders.
-- Business rules enforced here:
--   1. Only orders with status IN ('completed', 'shipped') contribute revenue.
--   2. Rows where product category is NULL are excluded before aggregation.
--   3. No duplicate order_line_item_id within a single order (deduplication via ROW_NUMBER).
--   4. Net line revenue = (quantity * unit_price) - refund_amount; must be > 0.
--   5. Multi-category orders: split at line-item grain — one row per item, not per order.
-- Grain: one row per deduplicated order line item (eligible orders only).

{{
    config(
        materialized         = 'incremental',
        unique_key           = 'order_item_id',
        incremental_strategy = 'merge',
        on_schema_change     = 'sync_all_columns'
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
    -- Business rule: only completed or shipped orders contribute to revenue
    where status in ('completed', 'shipped')
    {% if is_incremental() %}
        -- Incremental filter applies only to this events CTE
        and order_date > (select max(order_date) from {{ this }})
    {% endif %}
),

order_items as (
    -- Full refresh of line items on each run (lookup table, not filtered incrementally)
    select
        order_item_id,
        order_id,
        product_id,
        quantity,
        unit_price,
        refund_amount
    from {{ ref('stg_bakery__order_items') }}
),

products as (
    -- Full refresh of products (lookup table, not filtered incrementally)
    -- Business rule: category must not be null; null-category products excluded below
    select
        product_id,
        product_name,
        category
    from {{ ref('stg_bakery__products') }}
    where category is not null
),

joined as (
    select
        oi.order_item_id,
        oi.order_id,
        o.customer_id,
        oi.product_id,
        o.order_date,
        o.status,
        p.product_name,
        p.category                                      as product_category,
        oi.quantity,
        oi.unit_price,
        oi.refund_amount,
        -- Net line revenue after partial refund deduction
        cast(
            (oi.quantity * oi.unit_price) - oi.refund_amount
            as numeric
        )                                               as net_line_revenue,
        -- Deduplication: pick the first occurrence of each order_item_id per order
        row_number() over (
            partition by oi.order_id, oi.order_item_id
            order by oi.order_item_id
        )                                               as row_num
    from orders as o
    inner join order_items as oi
        on o.order_id = oi.order_id
    inner join products as p
        on oi.product_id = p.product_id
),

deduplicated as (
    select
        order_item_id,
        order_id,
        customer_id,
        product_id,
        order_date,
        status,
        product_name,
        product_category,
        quantity,
        unit_price,
        refund_amount,
        net_line_revenue
    from joined
    -- Business rule: remove duplicate order_line_item_id within a single order
    where row_num = 1
),

validated as (
    select *
    from deduplicated
    -- Business rule: net revenue must be > 0 (fully refunded lines excluded)
    where net_line_revenue > 0
)

select * from validated
