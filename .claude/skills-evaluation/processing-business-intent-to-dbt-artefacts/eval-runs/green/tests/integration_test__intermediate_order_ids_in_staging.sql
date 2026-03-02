-- integration_test__intermediate_order_ids_in_staging.sql
-- Integration test: Every order_id in the intermediate revenue model must
--   exist in stg_bakery__orders (referential integrity: int → staging).
-- Invariant: no fabricated orders in the intermediate layer.
-- Severity: error — orders that don't exist in staging are a data integrity violation.

{{ config(severity='error') }}

select distinct
    i.order_id as orphaned_order_id
from {{ ref('int_orders__revenue_by_category') }} as i
left join {{ ref('stg_bakery__orders') }} as o
    on i.order_id = o.order_id
where o.order_id is null
