-- assert_unique_category_month_grain.sql
-- DQ Check: Verify that the mart has exactly one row per product_category per revenue_month.
-- Business rule: the grain of the primary output is one row per category per month.
-- Severity: error — duplicate grain rows mean the report will double-count metrics.
-- Placement: post-publish (mart layer validation).

{{ config(severity='error') }}

select
    revenue_month,
    product_category,
    count(*) as row_count
from {{ ref('fct_revenue_by_category_monthly') }}
group by
    revenue_month,
    product_category
having count(*) > 1
