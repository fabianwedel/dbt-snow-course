/*
  stg_tpch__orders.sql
  ─────────────────────
  Staging model for the TPC-H ORDERS source table.
  Applies:
    • Consistent snake_case column naming
    • Explicit data-type casts
    • Status code mapping to human-readable labels
    • No business logic — that lives in intermediate/mart layers
*/

with

source as (
    select * from {{ source('tpch', 'orders') }}
),

renamed as (
    select
        -- Primary key
        O_ORDERKEY          as order_id,

        -- Foreign keys
        O_CUSTKEY           as customer_id,

        -- Order attributes
        O_ORDERSTATUS       as order_status_code,
        case O_ORDERSTATUS
            when 'O' then 'Open'
            when 'F' then 'Fulfilled'
            when 'P' then 'In Progress'
            else          'Unknown'
        end                 as order_status,

        -- Financial
        O_TOTALPRICE        as order_total_price,

        -- Dates
        O_ORDERDATE::date   as order_date,

        -- Descriptive
        O_ORDERPRIORITY     as order_priority,
        O_CLERK             as clerk_id,
        O_SHIPPRIORITY      as ship_priority,
        O_COMMENT           as order_comment

    from source
)

select * from renamed
