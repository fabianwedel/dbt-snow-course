/*
  stg_tpch__customers.sql
  ────────────────────────
  Staging model for the TPC-H CUSTOMER source table.
*/

with

source as (
    select * from {{ source('tpch', 'customer') }}
),

renamed as (
    select
        -- Primary key
        C_CUSTKEY           as customer_id,

        -- Foreign key
        C_NATIONKEY         as nation_id,

        -- Customer attributes
        C_NAME              as customer_name,
        C_ADDRESS           as customer_address,
        C_PHONE             as customer_phone,
        C_ACCTBAL           as account_balance,
        C_MKTSEGMENT        as market_segment,
        C_COMMENT           as customer_comment

    from source
)

select * from renamed
