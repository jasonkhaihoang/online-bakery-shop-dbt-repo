-- assert_no_null_product_category.sql
-- DQ Check: Verify that product_category is never null in the mart.
-- Business rule: rows with null product_category_id must be excluded before aggregation.
-- Severity: error — null category breaks the grain and makes the report unusable.
-- Placement: post-publish (mart layer validation).

{{ config(severity='error') }}

select
    revenue_month,
    product_category,
    total_revenue
from {{ ref('fct_revenue_by_category_monthly') }}
where product_category is null
