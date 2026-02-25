-- dim_product.sql
-- Product dimension with category attributes.
-- Includes active and retired products; filter on is_active for current catalogue.
-- Grain: one row per product.

with

products as (
    select * from {{ ref('stg_bakery__products') }}
)

select
    -- keys
    product_id,
    -- attributes
    product_name,
    category,
    price,
    is_active
from products
