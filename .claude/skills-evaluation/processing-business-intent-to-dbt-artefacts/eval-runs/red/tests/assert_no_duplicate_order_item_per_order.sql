-- assert_no_duplicate_order_item_per_order.sql
-- DQ Check: no order_item_id should appear more than once within the same
-- order_id in the intermediate model. Duplicates would double-count revenue.
--
-- Returns offending (order_id, order_item_id) pairs; fails when any row returned.

{{ config(severity='error') }}

select
    order_id,
    order_item_id,
    count(*) as occurrences
from {{ ref('int_orders__revenue_by_category') }}
group by
    order_id,
    order_item_id
having count(*) > 1
