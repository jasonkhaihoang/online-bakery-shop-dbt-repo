-- int_orders__completed.sql
-- Completed orders with line item detail and revenue contribution.
-- Business rule: revenue is recognised only on completed orders.
-- Grain: one row per order line item (completed orders only).

{{
    config(
        materialized         = 'incremental',
        unique_key           = 'order_item_id',
        incremental_strategy = 'merge'
    )
}}

with

orders as (
    select * from {{ ref('stg_bakery__orders') }}
    where status = 'completed'
    {% if is_incremental() %}
        and order_date > (select max(order_date) from {{ this }})
    {% endif %}
),

order_items as (
    select * from {{ ref('stg_bakery__order_items') }}
),

products as (
    select * from {{ ref('stg_bakery__products') }}
),

completed as (
    select
        -- keys
        oi.order_item_id,
        oi.order_id,
        o.customer_id,
        oi.product_id,
        -- order properties
        o.order_date,
        o.status,
        -- line item detail
        p.product_name,
        p.category,
        oi.quantity,
        oi.unit_price,
        cast(oi.quantity * oi.unit_price as numeric) as line_total
    from orders as o
    inner join order_items as oi
        on o.order_id = oi.order_id
    inner join products as p
        on oi.product_id = p.product_id
)

select * from completed
