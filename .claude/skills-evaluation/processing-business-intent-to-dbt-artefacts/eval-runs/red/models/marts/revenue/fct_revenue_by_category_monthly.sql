-- fct_revenue_by_category_monthly.sql
-- Monthly revenue report by product category for the sales team.
--
-- Metrics:
--   total_revenue      — sum of net line item amounts (refunds already deducted)
--   order_count        — count of distinct orders contributing to each category-month
--   avg_order_value    — total_revenue / order_count
--   revenue_mom_growth — month-over-month revenue growth % per category;
--                        null when a category has no prior-month data (new category)
--
-- Grain: one row per product_category per month (year-month).

{{
    config(
        materialized = 'table'
    )
}}

with

line_items as (
    select
        product_category,
        order_id,
        order_date,
        net_line_total
    from {{ ref('int_orders__revenue_by_category') }}
),

-- Aggregate to category + month grain.
monthly_category as (
    select
        product_category,
        date_trunc('month', order_date)::date           as revenue_month,
        sum(net_line_total)                             as total_revenue,
        count(distinct order_id)                        as order_count
    from line_items
    group by
        product_category,
        date_trunc('month', order_date)::date
),

-- Compute avg_order_value and lag for MoM growth in a single pass.
with_metrics as (
    select
        product_category,
        revenue_month,
        total_revenue,
        order_count,
        -- avg_order_value: safe division — order_count is always >= 1 after
        -- aggregation, but guard with nullif for belt-and-braces.
        total_revenue / nullif(order_count, 0)          as avg_order_value,
        -- Prior month revenue for this category. NULL when the category is new.
        lag(total_revenue) over (
            partition by product_category
            order by revenue_month
        )                                               as prior_month_revenue
    from monthly_category
),

final as (
    select
        product_category,
        revenue_month,
        total_revenue,
        order_count,
        avg_order_value,
        -- revenue_mom_growth: null when prior month is null (new category),
        -- otherwise ((current - prior) / prior) * 100.
        case
            when prior_month_revenue is null then null
            else round(
                ((total_revenue - prior_month_revenue) / nullif(prior_month_revenue, 0)) * 100,
                2
            )
        end                                             as revenue_mom_growth
    from with_metrics
)

select * from final
