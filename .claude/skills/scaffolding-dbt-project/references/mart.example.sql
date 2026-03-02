-- fct_customer_orders.sql
-- Consumer-ready: one row per customer with lifetime order aggregates.
-- Grain: customer_id.

with

customers as (
    select * from {{ ref('int_customers__unified') }}
),

payments as (
    select * from {{ ref('int_payments__joined') }}
),

final as (
    select
        customers.customer_id,
        customers.customer_name,
        count(payments.payment_id)  as total_orders,
        sum(payments.amount)        as lifetime_revenue,
        min(payments.payment_date)  as first_order_date,
        max(payments.payment_date)  as last_order_date

    from customers
    left join payments
        on customers.customer_id = payments.customer_id

    group by
        customers.customer_id,
        customers.customer_name
)

select * from final
