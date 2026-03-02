-- fct_{entity}.sql / dim_{entity}.sql
-- Consumer-ready: {describe what this model produces}.
-- Grain: one row per {entity}.

with

{primary_cte} as (
    select * from {{ ref('int_{concept}__{descriptor}') }}
),

{secondary_cte} as (
    select * from {{ ref('int_{concept}__{descriptor}') }}
),

final as (
    select
        {primary_cte}.{pk_column},

        -- foreign keys
        {primary_cte}.{fk_column},

        -- measures / aggregates
        count({secondary_cte}.{pk_column})      as {count_metric},
        sum({secondary_cte}.{amount_column})    as {sum_metric},
        min({secondary_cte}.{date_column})      as {min_date},
        max({secondary_cte}.{date_column})      as {max_date}

    from {primary_cte}
    left join {secondary_cte}
        on {primary_cte}.{pk_column} = {secondary_cte}.{fk_column}

    group by
        {primary_cte}.{pk_column},
        {primary_cte}.{fk_column}
)

select * from final
