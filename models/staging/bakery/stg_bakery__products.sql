-- stg_bakery__products.sql
-- Cleaned, typed, renamed product records. Includes retired products.
-- Grain: one row per product.

with

source as (
    select * from {{ source('bakery', 'brz_products') }}
),

renamed as (
    select
        -- keys
        product_id,
        -- properties
        product_name,
        category,
        cast(price as numeric) as price,
        cast(is_active as boolean) as is_active
    from source
)

select * from renamed
