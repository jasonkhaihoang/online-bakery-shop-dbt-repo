-- assert_revenue_is_positive.sql
-- DQ Check: Verify that every row in the mart has total_revenue > 0.
-- Business rule: cancelled or fully-refunded orders are excluded entirely;
--   remaining rows must have positive revenue.
-- Severity: error — revenue <= 0 is a data integrity failure.
-- Placement: post-publish (mart layer validation).

{{ config(severity='error') }}

select
    revenue_month,
    product_category,
    total_revenue
from {{ ref('fct_revenue_by_category_monthly') }}
where total_revenue <= 0
