-- integration_test__intermediate_to_mart_revenue_reconciliation.sql
-- Integration Test: verifies that the mart's total_revenue per category-month
-- exactly matches the sum of net_line_total in the intermediate model for the
-- same category-month partition.
--
-- Any discrepancy indicates an aggregation bug in the mart.
-- Returns rows where the values diverge; test fails when any row is returned.

{{ config(severity='error') }}

with

intermediate_agg as (
    select
        product_category,
        date_trunc('month', order_date)::date   as revenue_month,
        sum(net_line_total)                     as expected_revenue,
        count(distinct order_id)                as expected_order_count
    from {{ ref('int_orders__revenue_by_category') }}
    group by
        product_category,
        date_trunc('month', order_date)::date
),

mart as (
    select
        product_category,
        revenue_month,
        total_revenue,
        order_count
    from {{ ref('fct_revenue_by_category_monthly') }}
),

comparison as (
    select
        coalesce(i.product_category, m.product_category)    as product_category,
        coalesce(i.revenue_month,    m.revenue_month)       as revenue_month,
        i.expected_revenue,
        m.total_revenue,
        i.expected_order_count,
        m.order_count
    from intermediate_agg as i
    full outer join mart as m
        on  i.product_category = m.product_category
        and i.revenue_month    = m.revenue_month
)

select *
from comparison
where
    -- Revenue mismatch
    abs(coalesce(expected_revenue, 0) - coalesce(total_revenue, 0)) > 0.001
    -- Order count mismatch
    or coalesce(expected_order_count, 0) <> coalesce(order_count, 0)
    -- Rows present in one side but not the other
    or expected_revenue is null
    or total_revenue    is null
