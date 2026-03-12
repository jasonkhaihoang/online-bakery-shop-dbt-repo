-- fct_revenue_by_category_monthly.sql
-- Monthly revenue report by product category for the sales team.
-- Metrics: total_revenue, order_count, avg_order_value, revenue_mom_growth.
-- Grain: one row per product_category per calendar month (year-month).
-- Business rules inherited from int_orders__revenue_by_category:
--   - Only completed/shipped orders included
--   - product_category is never null
--   - Net revenue > 0 (partial refunds deducted, fully refunded lines excluded)
--   - No duplicate order_line_item_id per order
-- Edge cases:
--   - New category in current month (no prior month): revenue_mom_growth = null
--   - Multi-category orders: split at line-item grain (each category gets its share)
--   - Historical category name changes: category text is used as-is from products table;
--     if a name changes retroactively the new name will appear going forward with no failures.

{{
    config(
        materialized = 'table',
        tags         = ['mart', 'gold', 'revenue', 'monthly']
    )
}}

with

line_items as (
    select
        product_category,
        order_id,
        order_date,
        net_line_revenue,
        -- Truncate to first day of month for grouping
        date_trunc('month', order_date)::date as revenue_month
    from {{ ref('int_orders__revenue_by_category') }}
),

monthly_by_category as (
    select
        revenue_month,
        product_category,
        -- total_revenue: sum of net line revenues per category per month
        sum(net_line_revenue)                   as total_revenue,
        -- order_count: distinct orders touching this category in this month
        count(distinct order_id)                as order_count
    from line_items
    group by
        revenue_month,
        product_category
),

with_avg as (
    select
        revenue_month,
        product_category,
        total_revenue,
        order_count,
        -- avg_order_value: total_revenue / order_count
        -- order_count is always >= 1 here (rows only exist when there is revenue)
        cast(total_revenue / order_count as numeric) as avg_order_value
    from monthly_by_category
),

with_mom_growth as (
    select
        revenue_month,
        product_category,
        total_revenue,
        order_count,
        avg_order_value,
        -- revenue_mom_growth: month-over-month % change
        -- null when no prior month row exists for this category (new category edge case)
        lag(total_revenue) over (
            partition by product_category
            order by revenue_month
        )                                           as prior_month_revenue,
        case
            when lag(total_revenue) over (
                partition by product_category
                order by revenue_month
            ) is null
                -- New category: no prior month exists → null (not 0)
                then null
            when lag(total_revenue) over (
                partition by product_category
                order by revenue_month
            ) = 0
                -- Prior month had zero revenue — avoid division by zero → null
                then null
            else
                round(
                    cast(
                        (
                            total_revenue
                            - lag(total_revenue) over (
                                partition by product_category
                                order by revenue_month
                            )
                        )
                        / lag(total_revenue) over (
                            partition by product_category
                            order by revenue_month
                        )
                        * 100
                        as numeric
                    ),
                    2
                )
        end                                         as revenue_mom_growth
    from with_avg
)

select
    revenue_month,
    product_category,
    total_revenue,
    order_count,
    avg_order_value,
    revenue_mom_growth
from with_mom_growth
order by
    revenue_month,
    product_category
