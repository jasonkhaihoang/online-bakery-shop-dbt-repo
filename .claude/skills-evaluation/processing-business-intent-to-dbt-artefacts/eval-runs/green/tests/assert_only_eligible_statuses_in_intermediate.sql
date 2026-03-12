-- assert_only_eligible_statuses_in_intermediate.sql
-- DQ Check: Verify that only 'completed' and 'shipped' order statuses exist
--   in the intermediate revenue model.
-- Business rule: pending, processing, placed, and cancelled orders must be excluded.
-- Severity: error — ineligible statuses would inflate revenue and break business rules.
-- Placement: pre-publish (intermediate layer validation).

{{ config(severity='error') }}

select
    order_id,
    order_item_id,
    status
from {{ ref('int_orders__revenue_by_category') }}
where status not in ('completed', 'shipped')
