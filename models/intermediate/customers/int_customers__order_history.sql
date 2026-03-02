-- int_customers__order_history.sql
-- Customer profile enriched with completed order history.
-- Grain: one row per customer.

{{
    config(
        materialized         = 'incremental',
        unique_key           = 'customer_id',
        incremental_strategy = 'merge'
    )
}}

with

customers as (
    select * from {{ ref('stg_bakery__customers') }}
),

completed_orders as (
    select
        customer_id,
        count(distinct order_id)    as total_orders,
        sum(line_total)             as lifetime_revenue,
        min(order_date)             as first_order_date,
        max(order_date)             as last_order_date
    from {{ ref('int_orders__completed') }}
    group by customer_id
),

final as (
    select
        -- keys
        c.customer_id,
        -- customer attributes
        c.first_name,
        c.last_name,
        c.email,
        c.city,
        c.created_at,
        -- order history
        coalesce(o.total_orders, 0)         as total_orders,
        coalesce(o.lifetime_revenue, 0)     as lifetime_revenue,
        o.first_order_date,
        o.last_order_date
    from customers as c
    left join completed_orders as o
        on c.customer_id = o.customer_id
)

select * from final
