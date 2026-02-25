-- dim_product.sql
-- Active product dimension. Excludes retired products (is_active = false).

with

products as (
    select * from {{ ref('stg_bakery__products') }}
    where is_active = true
)

select
    product_id,
    product_name,
    category,
    price
from products
