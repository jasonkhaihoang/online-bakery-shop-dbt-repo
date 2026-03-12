-- e2e_test__source_to_mart_revenue_totals.sql
-- End-to-End Test: validates the full pipeline from the bronze source tables
-- through staging and intermediate to the mart.
--
-- Asserts that the mart's overall total_revenue (summed across all categories
-- and all months) equals the sum of net_line_total computed directly from the
-- source, joining orders (status in ('completed','shipped')) to order_items
-- and deducting refunds.
--
-- A discrepancy here means revenue was lost or gained somewhere in the pipeline.
-- Returns rows when any discrepancy is found; test fails when any row is returned.

{{ config(severity='error') }}

with

-- Ground truth: compute revenue directly from source tables.
source_revenue as (
    select
        sum(
            cast(oi.quantity * oi.unit_price as numeric)
            - cast(coalesce(oi.refunded_amount, 0) as numeric)
        ) as expected_total_revenue
    from {{ source('bakery', 'brz_orders') }}        as o
    inner join {{ source('bakery', 'brz_order_items') }} as oi
        on o.order_id = oi.order_id
    inner join {{ source('bakery', 'brz_products') }}    as p
        on oi.product_id = p.product_id
    where o.status in ('completed', 'shipped')
      and p.category is not null
      and (
            cast(oi.quantity * oi.unit_price as numeric)
            - cast(coalesce(oi.refunded_amount, 0) as numeric)
          ) > 0
),

-- Mart total across all categories and months.
mart_revenue as (
    select sum(total_revenue) as actual_total_revenue
    from {{ ref('fct_revenue_by_category_monthly') }}
)

select
    s.expected_total_revenue,
    m.actual_total_revenue,
    abs(s.expected_total_revenue - m.actual_total_revenue) as discrepancy
from source_revenue as s
cross join mart_revenue as m
where abs(s.expected_total_revenue - m.actual_total_revenue) > 0.01
