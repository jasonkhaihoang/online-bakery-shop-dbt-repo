-- assert_no_null_product_category.sql
-- DQ Check: product_category must never be null in the intermediate model
-- or the mart. Null categories would corrupt the category-month grain.
--
-- Returns rows that violate the rule; the test fails when any row is returned.

{{ config(severity='error') }}

select
    order_item_id,
    order_id,
    product_id,
    product_category
from {{ ref('int_orders__revenue_by_category') }}
where product_category is null
