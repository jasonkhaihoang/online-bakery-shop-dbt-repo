-- fct_revenue.sql
-- One row per completed order with revenue totals.
-- Aggregates line items from int_orders__completed.

with

completed_items as (
    select * from {{ ref('int_orders__completed') }}
),

final as (
    select
        order_id,
        customer_id,
        order_date,
        count(order_item_id)                        as line_item_count,
        sum(quantity)                               as total_units,
        cast(sum(line_total) as numeric)            as order_revenue
    from completed_items
    group by
        order_id,
        customer_id,
        order_date
)

select * from final
