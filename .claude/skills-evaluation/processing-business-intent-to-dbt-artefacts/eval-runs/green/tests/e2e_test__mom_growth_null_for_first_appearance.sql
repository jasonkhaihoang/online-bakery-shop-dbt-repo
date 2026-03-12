-- e2e_test__mom_growth_null_for_first_appearance.sql
-- E2E test: For each product_category, verify that the earliest revenue_month row
--   has revenue_mom_growth = null (new category edge case).
-- Business rule: If a product category exists in the current month but not the prior
--   month, revenue_mom_growth should be null (not 0, not an error).
-- Severity: error — a non-null value for the first month of a category means the
--   MoM growth calculation is fabricating a prior-period comparison.

{{ config(severity='error') }}

with

first_month_per_category as (
    select
        product_category,
        min(revenue_month) as first_revenue_month
    from {{ ref('fct_revenue_by_category_monthly') }}
    group by product_category
),

first_month_rows as (
    select
        m.revenue_month,
        m.product_category,
        m.revenue_mom_growth
    from {{ ref('fct_revenue_by_category_monthly') }} as m
    inner join first_month_per_category as f
        on m.product_category = f.product_category
        and m.revenue_month = f.first_revenue_month
)

-- Return rows where the first month has non-null revenue_mom_growth (should be empty)
select *
from first_month_rows
where revenue_mom_growth is not null
