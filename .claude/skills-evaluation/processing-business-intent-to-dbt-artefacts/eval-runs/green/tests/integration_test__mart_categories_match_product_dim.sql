-- integration_test__mart_categories_match_product_dim.sql
-- Integration test: Every product_category in the mart must exist as a valid
--   category value in stg_bakery__products.
-- Invariant: the mart does not contain category values that aren't in the product catalogue.
-- Severity: warn — a new category in the mart not yet in dim_product is unusual but
--   may occur during product catalogue updates; warn rather than block.

{{ config(severity='warn') }}

select distinct
    m.product_category as unknown_category
from {{ ref('fct_revenue_by_category_monthly') }} as m
left join (
    select distinct category
    from {{ ref('stg_bakery__products') }}
    where category is not null
) as p
    on m.product_category = p.category
where p.category is null
