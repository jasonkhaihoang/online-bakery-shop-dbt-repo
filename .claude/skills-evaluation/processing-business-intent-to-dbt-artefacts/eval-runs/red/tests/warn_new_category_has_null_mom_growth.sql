-- warn_new_category_has_null_mom_growth.sql
-- DQ Check (WARN): validates that revenue_mom_growth is null only for a
-- category's debut month (i.e. no prior-month row for that category exists).
-- If a non-debut row has null MoM growth, that indicates a data gap worth
-- investigating but is not blocking.
--
-- Returns rows where MoM growth is null but a prior month row DOES exist;
-- these suggest a computation error rather than a legitimate new-category debut.

{{ config(severity='warn') }}

with ranked as (
    select
        product_category,
        revenue_month,
        revenue_mom_growth,
        row_number() over (
            partition by product_category
            order by revenue_month
        ) as month_rank
    from {{ ref('fct_revenue_by_category_monthly') }}
)

select
    product_category,
    revenue_month,
    revenue_mom_growth,
    month_rank
from ranked
-- MoM growth should only be null on the first month (rank = 1).
-- Flag any subsequent month that also has a null value.
where month_rank > 1
  and revenue_mom_growth is null
