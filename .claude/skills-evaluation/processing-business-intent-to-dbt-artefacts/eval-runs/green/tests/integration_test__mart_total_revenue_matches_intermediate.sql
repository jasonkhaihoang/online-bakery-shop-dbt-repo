-- integration_test__mart_total_revenue_matches_intermediate.sql
-- Integration test: The sum of total_revenue in the mart must equal the sum of
--   net_line_revenue in the intermediate model.
-- Invariant: no revenue is lost or invented during aggregation from int → mart.
-- Severity: error — a mismatch means the mart is mis-aggregating the intermediate model.

{{ config(severity='error') }}

with

intermediate_total as (
    select sum(net_line_revenue) as total_net_revenue
    from {{ ref('int_orders__revenue_by_category') }}
),

mart_total as (
    select sum(total_revenue) as total_mart_revenue
    from {{ ref('fct_revenue_by_category_monthly') }}
)

select
    intermediate_total.total_net_revenue,
    mart_total.total_mart_revenue,
    intermediate_total.total_net_revenue - mart_total.total_mart_revenue as discrepancy
from intermediate_total
cross join mart_total
where
    -- Allow no discrepancy — revenue totals must match exactly
    intermediate_total.total_net_revenue <> mart_total.total_mart_revenue
    or intermediate_total.total_net_revenue is null
    or mart_total.total_mart_revenue is null
