-- assert_net_line_revenue_is_positive.sql
-- DQ Check: Verify that every row in the intermediate model has net_line_revenue > 0.
-- Business rule: revenue values must be > 0; fully refunded lines must be excluded.
-- Severity: error — zero or negative net revenue at line-item grain means
--   cancelled/fully-refunded lines are leaking into the revenue pipeline.
-- Placement: pre-publish (intermediate layer validation).

{{ config(severity='error') }}

select
    order_item_id,
    order_id,
    product_category,
    net_line_revenue
from {{ ref('int_orders__revenue_by_category') }}
where net_line_revenue <= 0
