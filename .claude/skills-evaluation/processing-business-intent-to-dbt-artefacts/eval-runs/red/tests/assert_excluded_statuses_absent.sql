-- assert_excluded_statuses_absent.sql
-- DQ Check: orders with status 'pending', 'processing', 'placed', or 'cancelled'
-- must not appear in the intermediate revenue model.
--
-- Returns any row with a disallowed status; fails when any row is returned.

{{ config(severity='error') }}

select
    order_item_id,
    order_id,
    status
from {{ ref('int_orders__revenue_by_category') }}
where status not in ('completed', 'shipped')
