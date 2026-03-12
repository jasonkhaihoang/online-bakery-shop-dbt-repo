-- assert_net_line_total_positive_in_intermediate.sql
-- DQ Check: net_line_total must be > 0 for every row in the intermediate model.
-- Fully-refunded or zero-value line items must be excluded before aggregation.
--
-- Returns rows that violate the rule; fails when any row is returned.

{{ config(severity='error') }}

select
    order_item_id,
    order_id,
    product_category,
    net_line_total
from {{ ref('int_orders__revenue_by_category') }}
where net_line_total <= 0
   or net_line_total is null
