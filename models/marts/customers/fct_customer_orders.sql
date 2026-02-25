-- fct_customer_orders.sql
-- Customer-level lifetime order aggregates.
-- Grain: one row per customer.

with

customer_history as (
    select * from {{ ref('int_customers__order_history') }}
)

select
    -- keys
    customer_id,
    -- metrics
    total_orders,
    lifetime_revenue,
    first_order_date,
    last_order_date
from customer_history
