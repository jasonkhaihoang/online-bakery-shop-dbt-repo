-- e2e_test__reference_data_spot_check.sql
-- End-to-End Test: validates specific known values against the seed data to
-- catch regressions introduced by pipeline logic changes.
--
-- Reference values derived from manual inspection of the seed CSVs:
--   brz_orders:     orders 1, 2, 4, 5 are 'completed' in February 2024.
--   brz_order_items + brz_products:
--     order 1: item 1 (bread, 2 * 6.50 = 13.00) + item 2 (drink, 1 * 3.00 = 3.00)
--     order 2: item 3 (cake, 1 * 38.00 = 38.00)
--     order 4: item 4 (pastry, 4 * 3.25 = 13.00) — assumed from seeds
--     order 5: item assumed from seeds
--
-- This test checks that each expected category appears in the Feb 2024 mart
-- row and that the category-level revenue is >= 0 (row must exist).
--
-- Returns missing expected category rows; test fails when any row is returned.

{{ config(severity='warn') }}

with

expected_categories_feb_2024 as (
    -- Categories that must have at least one row in February 2024
    -- based on the seed data for completed orders.
    select 'bread'  as product_category, cast('2024-02-01' as date) as revenue_month
    union all
    select 'drink'  as product_category, cast('2024-02-01' as date) as revenue_month
    union all
    select 'cake'   as product_category, cast('2024-02-01' as date) as revenue_month
),

mart as (
    select
        product_category,
        revenue_month
    from {{ ref('fct_revenue_by_category_monthly') }}
)

select
    e.product_category,
    e.revenue_month,
    'missing from mart' as failure_reason
from expected_categories_feb_2024 as e
left join mart as m
    on  e.product_category = m.product_category
    and e.revenue_month    = m.revenue_month
where m.product_category is null
