-- int_customers__unified.sql
-- Core business logic: unify customers across Salesforce and Stripe.
-- Grain: one row per customer (customer_id is the PK of this model).

{{
    config(
        materialized         = 'incremental',
        unique_key           = 'customer_id',   -- PK of THIS model's output grain (not a FK)
        incremental_strategy = 'merge'
    )
}}

-- unique_key selection rule:
--   Use the column that uniquely identifies one row in the OUTPUT of this model.
--   It must be the same column that has not_null + unique tests in the model's YAML.
--   Never use a FK: FKs are not unique at the model grain and cause silent data loss on merge.
--   Examples:
--     int_customers__unified   -> unique_key = 'customer_id'    (one row per customer)
--     int_orders__completed    -> unique_key = 'order_item_id'  (one row per line item)

with

-- ── Event / transactional source CTEs ────────────────────────────────────────────────────────
-- These tables have an updated_at column. Apply is_incremental() so only rows changed since
-- the last run are processed. Both CTEs here are transactional sources that need filtering.

salesforce_accounts as (
    select * from {{ ref('stg_salesforce__account') }}
    where not is_deleted
    {% if is_incremental() %}
        and updated_at > (select max(updated_at) from {{ this }})
    {% endif %}
),

stripe_customers as (
    select * from {{ ref('stg_stripe__customer') }}
    {% if is_incremental() %}
        where updated_at > (select max(updated_at) from {{ this }})
    {% endif %}
),

-- ── Lookup / reference source CTEs ───────────────────────────────────────────────────────────
-- Static reference tables have no updated_at to filter on.
-- DO NOT apply is_incremental() to these CTEs — all rows must always be available for joins.
-- Filtering a lookup table incrementally would cause missing join matches on incremental runs.

account_regions as (
    select * from {{ ref('stg_salesforce__region') }}
),

unified as (
    select
        coalesce(sf.account_id, st.customer_id)   as customer_id,
        sf.account_name                            as customer_name,
        sf.industry,
        sf.account_type,
        ar.region_name,
        st.email,
        st.currency,
        sf.created_at                              as sf_created_at,
        st.created_at                              as stripe_created_at,
        least(sf.created_at, st.created_at)        as first_seen_at,
        greatest(sf.updated_at, st.updated_at)     as updated_at

    from salesforce_accounts as sf
    full outer join stripe_customers as st
        on sf.account_id = st.metadata_salesforce_id
    left join account_regions as ar
        on sf.region_code = ar.region_code
)

select * from unified
