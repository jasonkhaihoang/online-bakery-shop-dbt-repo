-- e2e_test__excluded_orders_absent_from_mart.sql
-- E2E test: Validate that orders with ineligible statuses (cancelled, processing, placed)
--   do NOT contribute any revenue to the mart.
-- Critical business journey: status filtering must work end-to-end from source to mart.
-- Known ineligible orders from seed data:
--   order_id=3  (cancelled, Feb 2024)
--   order_id=6  (processing, Mar 2024)
--   order_id=9  (placed, Mar 2024)
--   order_id=13 (cancelled, Apr 2024)
--   order_id=15 (processing, May 2024)
-- These orders have items in categories that also have eligible orders — so if they
--   leaked, the revenue totals would be inflated vs. reference.
-- This test verifies via the intermediate model that none of these order_ids appear.
-- Severity: error — ineligible orders in the pipeline inflate revenue figures.

{{ config(severity='error') }}

select
    order_id,
    status,
    order_date,
    product_category,
    net_line_revenue
from {{ ref('int_orders__revenue_by_category') }}
where order_id in (3, 6, 9, 13, 15)
