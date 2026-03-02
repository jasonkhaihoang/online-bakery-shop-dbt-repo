-- assert_no_null_category_in_intermediate.sql
-- DQ Check: Verify that product_category is never null in the intermediate model.
-- Business rule: null product_category_id rows must be excluded before aggregation.
-- Severity: error — null category at the intermediate layer would cause nulls
--   to propagate into the mart and break the category grain.
-- Placement: pre-publish (intermediate layer validation).

{{ config(severity='error') }}

select
    order_item_id,
    order_id,
    product_id,
    product_category
from {{ ref('int_orders__revenue_by_category') }}
where product_category is null
