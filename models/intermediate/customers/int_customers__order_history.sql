-- int_customers__order_history.sql
-- Enriches customers with completed-order aggregates.
-- Grain: one row per customer.

with

customers as (
    select * from {{ ref('stg_bakery__customers') }}
),

completed_orders as (
    select * from {{ ref('stg_bakery__orders') }}
    where status = 'completed'
),

order_agg as (
    select
        customer_id,
        count(order_id)                         as total_orders,
        cast(sum(total_amount) as numeric)      as total_revenue,
        min(order_date)                         as first_order_date,
        max(order_date)                         as last_order_date
    from completed_orders
    group by customer_id
),

final as (
    select
        c.customer_id,
        c.first_name,
        c.last_name,
        c.email,
        c.city,
        c.created_at,
        coalesce(a.total_orders, 0)             as total_orders,
        coalesce(a.total_revenue, 0.0)          as total_revenue,
        a.first_order_date,
        a.last_order_date
    from customers as c
    left join order_agg as a
        on c.customer_id = a.customer_id
)

select * from final
