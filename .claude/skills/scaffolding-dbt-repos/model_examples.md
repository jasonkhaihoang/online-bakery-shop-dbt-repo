# model_examples.md

Example models for each layer.

## Staging — `models/staging/salesforce/stg_salesforce__account.sql`

```sql
-- stg_salesforce__account.sql
-- Cleaned, typed, renamed. One model per source table.
-- Entry point into dbt: consumes bronze via source(), never ref().

with

source as (
    select * from {{ source('salesforce', 'account') }}
),

renamed as (
    select
        -- keys
        id                          as account_id,
        -- properties
        name                        as account_name,
        type                        as account_type,
        industry,
        annual_revenue,
        number_of_employees,
        -- relationships
        owner_id,
        parent_id                   as parent_account_id,
        -- timestamps
        cast(created_date as timestamp)       as created_at,
        cast(last_modified_date as timestamp) as updated_at,
        cast(is_deleted as boolean)           as is_deleted
    from source
)

select * from renamed
```

## Intermediate — `models/intermediate/customers/int_customers__unified.sql`

```sql
-- int_customers__unified.sql
-- Core business logic: unify customers across Salesforce and Stripe.

with

salesforce_accounts as (
    select * from {{ ref('stg_salesforce__account') }}
    where not is_deleted
),

stripe_customers as (
    select * from {{ ref('stg_stripe__customer') }}
),

unified as (
    select
        coalesce(sf.account_id, st.customer_id)   as customer_id,
        sf.account_name                            as customer_name,
        sf.industry,
        sf.account_type,
        st.email,
        st.currency,
        sf.created_at                              as sf_created_at,
        st.created_at                              as stripe_created_at,
        least(sf.created_at, st.created_at)        as first_seen_at
    from salesforce_accounts as sf
    full outer join stripe_customers as st
        on sf.account_id = st.metadata_salesforce_id
)

select * from unified
```

## Mart — `models/marts/customers/fct_customer_orders.sql`

```sql
-- fct_customer_orders.sql
-- Consumer-ready: one row per customer with order aggregates.

with

customers as (
    select * from {{ ref('int_customers__unified') }}
),

payments as (
    select * from {{ ref('int_payments__joined') }}
),

final as (
    select
        customers.customer_id,
        customers.customer_name,
        count(payments.payment_id)  as total_orders,
        sum(payments.amount)        as lifetime_revenue,
        min(payments.payment_date)  as first_order_date,
        max(payments.payment_date)  as last_order_date
    from customers
    left join payments
        on customers.customer_id = payments.customer_id
    group by
        customers.customer_id,
        customers.customer_name
)

select * from final
```
