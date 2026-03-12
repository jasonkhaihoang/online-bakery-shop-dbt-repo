-- e2e_test__pipeline_row_count_in_expected_range.sql
-- E2E test: Verify the mart has the expected number of rows given the seed dataset.
-- Reference: 9 category-month combinations expected from the seed data
--   (Feb: 3 categories, Mar: 3 categories, Apr: 3 categories = 9 rows).
-- Severity: warn — row count outside range may indicate filtering regression or
--   new data, not necessarily a critical failure.

{{ config(severity='warn') }}

with

mart_count as (
    select count(*) as actual_row_count
    from {{ ref('fct_revenue_by_category_monthly') }}
),

expected_bounds as (
    select
        9 as expected_min_rows,
        9 as expected_max_rows
)

select
    actual_row_count,
    expected_min_rows,
    expected_max_rows,
    case
        when actual_row_count < expected_min_rows then 'TOO_FEW_ROWS'
        when actual_row_count > expected_max_rows then 'TOO_MANY_ROWS'
        else 'PASS'
    end as check_result
from mart_count
cross join expected_bounds
where actual_row_count < expected_min_rows
   or actual_row_count > expected_max_rows
