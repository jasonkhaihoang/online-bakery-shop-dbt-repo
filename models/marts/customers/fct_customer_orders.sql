-- fct_customer_orders.sql
-- One row per customer with lifetime order metrics.

with

customer_history as (
    select * from {{ ref('int_customers__order_history') }}
)

select
    customer_id,
    first_name,
    last_name,
    total_orders,
    total_revenue,
    first_order_date,
    last_order_date
from customer_history
