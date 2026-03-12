-- e2e_test__mart_matches_reference_data.sql
-- E2E test: Validate the full pipeline from raw seed data → mart against known
--   reference values computed from brz_* seed tables.
-- Critical business journey: order line items flow through staging → intermediate
--   → mart with correct revenue totals and order counts per category per month.
-- Reference data: seeds/e2e_ref__expected_revenue_by_category_monthly.csv
-- Tolerance: exact match required (no rounding variance acceptable for this dataset size).
-- Severity: error — any deviation from reference values indicates a pipeline regression.

{{ config(severity='error') }}

with

actual as (
    select
        revenue_month,
        product_category,
        total_revenue,
        order_count
    from {{ ref('fct_revenue_by_category_monthly') }}
),

expected as (
    select
        cast(revenue_month as date)        as revenue_month,
        product_category,
        cast(expected_total_revenue as numeric) as expected_total_revenue,
        cast(expected_order_count as integer)   as expected_order_count
    from {{ ref('e2e_ref__expected_revenue_by_category_monthly') }}
),

comparison as (
    select
        coalesce(a.revenue_month, e.revenue_month)       as revenue_month,
        coalesce(a.product_category, e.product_category) as product_category,
        a.total_revenue                                  as actual_total_revenue,
        e.expected_total_revenue,
        a.order_count                                    as actual_order_count,
        e.expected_order_count,
        case
            when a.revenue_month is null
                then 'MISSING_IN_ACTUAL'
            when e.revenue_month is null
                then 'EXTRA_IN_ACTUAL'
            when a.total_revenue <> e.expected_total_revenue
                then 'REVENUE_MISMATCH'
            when a.order_count <> e.expected_order_count
                then 'ORDER_COUNT_MISMATCH'
            else 'PASS'
        end                                              as check_result
    from actual as a
    full outer join expected as e
        on a.revenue_month = e.revenue_month
        and a.product_category = e.product_category
)

-- Return only failures — any rows returned will fail the test
select *
from comparison
where check_result <> 'PASS'
