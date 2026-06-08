/*
  stg_tpch__lineitems.sql
  ────────────────────────
  Staging model for the TPC-H LINEITEM source table.
  Each row represents one line within a customer order.
*/

with

source as (
    select * from {{ source('tpch', 'lineitem') }}
),

renamed as (
    select
        -- Composite natural key  (orderkey + linenumber)
        L_ORDERKEY          as order_id,
        L_LINENUMBER        as line_number,

        -- Foreign keys
        L_PARTKEY           as part_id,
        L_SUPPKEY           as supplier_id,

        -- Quantities & pricing
        L_QUANTITY          as quantity,
        L_EXTENDEDPRICE     as extended_price,
        L_DISCOUNT          as discount_fraction,
        L_TAX               as tax_fraction,

        -- Derived financials (calculated here once, used everywhere downstream)
        round(L_EXTENDEDPRICE * (1 - L_DISCOUNT), 2)          as net_price,
        round(L_EXTENDEDPRICE * (1 - L_DISCOUNT) * (1 + L_TAX), 2) as gross_price,

        -- Status codes
        L_RETURNFLAG        as return_flag,
        L_LINESTATUS        as line_status,

        -- Dates
        L_SHIPDATE::date    as ship_date,
        L_COMMITDATE::date  as commit_date,
        L_RECEIPTDATE::date as receipt_date,

        -- Descriptive
        L_SHIPINSTRUCT      as ship_instructions,
        L_SHIPMODE          as ship_mode,
        L_COMMENT           as line_comment

    from source
)

select * from renamed
