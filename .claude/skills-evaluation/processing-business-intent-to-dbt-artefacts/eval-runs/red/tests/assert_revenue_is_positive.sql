-- assert_revenue_is_positive.sql
-- DQ Check: total_revenue must be > 0 for every row in the mart.
-- A new category's first month can still have a null MoM growth, but
-- the revenue figure itself must always be positive.
--
-- Returns rows that violate the rule; the test fails when any row is returned.

{{ config(severity='error') }}

select
    product_category,
    revenue_month,
    total_revenue
from {{ ref('fct_revenue_by_category_monthly') }}
where total_revenue <= 0
   or total_revenue is null
