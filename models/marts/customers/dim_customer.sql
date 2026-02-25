-- dim_customer.sql
-- Customer dimension with current attributes.
-- Contains all customers including those with no completed orders.
-- Grain: one row per customer.

with

customer_history as (
    select * from {{ ref('int_customers__order_history') }}
)

select
    -- keys
    customer_id,
    -- attributes
    first_name,
    last_name,
    email,
    city,
    created_at
from customer_history
