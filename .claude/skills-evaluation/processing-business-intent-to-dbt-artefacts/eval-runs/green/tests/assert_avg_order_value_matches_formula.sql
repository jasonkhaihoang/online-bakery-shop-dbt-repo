-- assert_avg_order_value_matches_formula.sql
-- DQ Check: Verify that avg_order_value = total_revenue / order_count for every row.
-- Severity: warn — a mismatch indicates a calculation bug but does not block publishing.
-- Placement: post-publish (mart layer validation).

{{ config(severity='warn') }}

select
    revenue_month,
    product_category,
    total_revenue,
    order_count,
    avg_order_value,
    round(cast(total_revenue / order_count as numeric), 2) as expected_avg_order_value
from {{ ref('fct_revenue_by_category_monthly') }}
where
    -- Allow rounding tolerance of 0.01
    abs(
        avg_order_value
        - round(cast(total_revenue / order_count as numeric), 2)
    ) > 0.01
