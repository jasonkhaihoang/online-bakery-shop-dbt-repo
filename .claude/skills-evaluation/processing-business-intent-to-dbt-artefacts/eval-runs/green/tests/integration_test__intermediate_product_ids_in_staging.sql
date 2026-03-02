-- integration_test__intermediate_product_ids_in_staging.sql
-- Integration test: Every product_id in the intermediate revenue model must
--   exist in stg_bakery__products (referential integrity: int → staging).
-- Invariant: no orphaned product references in the intermediate layer.
-- Severity: error — orphaned product_ids indicate a broken join and unreliable
--   category attribution.

{{ config(severity='error') }}

select distinct
    i.product_id as orphaned_product_id
from {{ ref('int_orders__revenue_by_category') }} as i
left join {{ ref('stg_bakery__products') }} as p
    on i.product_id = p.product_id
where p.product_id is null
