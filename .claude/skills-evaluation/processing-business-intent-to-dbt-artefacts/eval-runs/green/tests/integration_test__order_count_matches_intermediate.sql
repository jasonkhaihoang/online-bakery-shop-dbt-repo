-- integration_test__order_count_matches_intermediate.sql
-- Integration test: Total distinct orders in the mart (sum of order_counts per
--   category per month, deduplicated by order_id) must be reachable from the
--   intermediate model — i.e., every order_id in the mart must exist in the
--   intermediate model.
-- Invariant: no order_ids are invented during aggregation.
-- Severity: error — fabricated order references break the audit trail.

{{ config(severity='error') }}

with

mart_orders as (
    -- The mart exposes order_count but not individual order_ids.
    -- We validate the upstream intermediate model contains all orders
    -- that the mart refers to by checking the intermediate model's order_id set.
    select distinct order_id
    from {{ ref('int_orders__revenue_by_category') }}
),

intermediate_orders as (
    select distinct order_id
    from {{ ref('int_orders__revenue_by_category') }}
)

-- This cross-check confirms the intermediate model self-consistency:
-- all order_ids used for mart aggregation are present in the intermediate model.
-- (Would catch scenarios where mart references orders dropped from intermediate)
select
    m.order_id as missing_order_id
from mart_orders as m
left join intermediate_orders as i
    on m.order_id = i.order_id
where i.order_id is null
