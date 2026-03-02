-- integration_test__intermediate_referential_integrity.sql
-- Integration Test: verifies that every product_id in the intermediate
-- revenue model has a matching row in the staging products model, and that
-- every order_id matches a row in the staging orders model.
--
-- Orphaned references indicate a join problem or seed data issue.
-- Returns orphaned rows; test fails when any row is returned.

{{ config(severity='error') }}

with

line_items as (
    select
        order_item_id,
        order_id,
        product_id,
        product_category
    from {{ ref('int_orders__revenue_by_category') }}
),

known_products as (
    select product_id
    from {{ ref('stg_bakery__products') }}
    where category is not null
),

known_orders as (
    select order_id
    from {{ ref('stg_bakery__orders') }}
    where status in ('completed', 'shipped')
),

orphaned_products as (
    select
        li.order_item_id,
        li.product_id,
        'orphaned_product'   as violation_type
    from line_items as li
    left join known_products as kp
        on li.product_id = kp.product_id
    where kp.product_id is null
),

orphaned_orders as (
    select
        li.order_item_id,
        li.order_id        as product_id,   -- re-use column for union
        'orphaned_order'   as violation_type
    from line_items as li
    left join known_orders as ko
        on li.order_id = ko.order_id
    where ko.order_id is null
)

select * from orphaned_products
union all
select * from orphaned_orders
