-- fct_revenue.sql
-- Order-level revenue facts for completed orders.
-- Grain: one row per completed order.

with

completed_orders as (
    select * from {{ ref('int_orders__completed') }}
),

order_revenue as (
    select
        -- keys
        order_id,
        customer_id,
        -- order properties
        order_date,
        -- revenue metrics
        count(order_item_id)    as total_items,
        sum(quantity)           as total_units,
        sum(line_total)         as order_revenue
    from completed_orders
    group by
        order_id,
        customer_id,
        order_date
)

select * from order_revenue
