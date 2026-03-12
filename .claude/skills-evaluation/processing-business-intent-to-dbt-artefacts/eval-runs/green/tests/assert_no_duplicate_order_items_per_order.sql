-- assert_no_duplicate_order_items_per_order.sql
-- DQ Check: Verify no duplicate order_item_id exists within a single order
--   in the intermediate model after deduplication.
-- Business rule: no duplicate order_line_item_id within a single order.
-- Severity: error — duplicates inflate revenue counts and break the grain.
-- Placement: pre-publish (intermediate layer validation).

{{ config(severity='error') }}

select
    order_id,
    order_item_id,
    count(*) as duplicate_count
from {{ ref('int_orders__revenue_by_category') }}
group by
    order_id,
    order_item_id
having count(*) > 1
