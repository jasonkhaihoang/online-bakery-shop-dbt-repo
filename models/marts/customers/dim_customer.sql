-- dim_customer.sql
-- Customer dimension: attributes from staging layer.
-- PII: contains email, first_name, last_name.

with

customers as (
    select * from {{ ref('stg_bakery__customers') }}
)

select
    customer_id,
    first_name,
    last_name,
    email,
    city,
    created_at
from customers
