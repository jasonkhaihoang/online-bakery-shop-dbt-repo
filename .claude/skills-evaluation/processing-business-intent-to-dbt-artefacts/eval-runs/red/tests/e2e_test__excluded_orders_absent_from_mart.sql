-- e2e_test__excluded_orders_absent_from_mart.sql
-- End-to-End Test: verifies that no revenue from excluded orders
-- (status: 'placed', 'processing', 'cancelled') leaks into the mart.
--
-- Strategy: compute order_ids from the source that should be excluded,
-- then assert none of those orders contributed line items to the intermediate
-- model (which feeds the mart).
--
-- Returns order_ids that violated the exclusion rule;
-- test fails when any row is returned.

{{ config(severity='error') }}

with

excluded_order_ids as (
    select order_id
    from {{ source('bakery', 'brz_orders') }}
    where status not in ('completed', 'shipped')
),

leaked_items as (
    select
        i.order_item_id,
        i.order_id,
        i.product_category,
        i.status
    from {{ ref('int_orders__revenue_by_category') }} as i
    inner join excluded_order_ids as ex
        on i.order_id = ex.order_id
)

select * from leaked_items
