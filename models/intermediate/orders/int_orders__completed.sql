-- int_orders__completed.sql
-- Revenue recognition rule: joins completed orders, order items, and products.
-- Grain: one row per order item on a completed order.

with

orders as (
    select * from {{ ref('stg_bakery__orders') }}
    where status = 'completed'
),

order_items as (
    select * from {{ ref('stg_bakery__order_items') }}
),

products as (
    select * from {{ ref('stg_bakery__products') }}
),

final as (
    select
        oi.order_item_id,
        o.order_id,
        o.customer_id,
        o.order_date,
        oi.product_id,
        p.product_name,
        p.category,
        oi.quantity,
        oi.unit_price,
        cast(oi.quantity * oi.unit_price as numeric)    as line_total
    from orders as o
    inner join order_items as oi
        on o.order_id = oi.order_id
    inner join products as p
        on oi.product_id = p.product_id
)

select * from final
