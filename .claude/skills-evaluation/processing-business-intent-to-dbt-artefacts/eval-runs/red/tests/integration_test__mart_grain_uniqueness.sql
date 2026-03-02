-- integration_test__mart_grain_uniqueness.sql
-- Integration Test: verifies that the mart contains exactly one row per
-- (product_category, revenue_month) combination. Duplicate grain rows
-- would cause double-counting in any BI tool consuming the mart.
--
-- Returns duplicate grain keys; test fails when any row is returned.

{{ config(severity='error') }}

select
    product_category,
    revenue_month,
    count(*) as row_count
from {{ ref('fct_revenue_by_category_monthly') }}
group by
    product_category,
    revenue_month
having count(*) > 1
