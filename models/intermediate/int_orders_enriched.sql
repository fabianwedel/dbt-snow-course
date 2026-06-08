/*
  int_orders_enriched.sql
  ────────────────────────
  Intermediate model: joins orders with customers and nations
  to produce an enriched order record ready for mart consumption.

  Grain: one row per customer order.
*/

with

orders as (
    select * from {{ ref('stg_tpch__orders') }}
),

customers as (
    select * from {{ ref('stg_tpch__customers') }}
),

-- Use the seed table for nation names instead of a source join
-- (demonstrates seed vs source usage)
nations as (
    select * from {{ ref('nation_codes') }}
),

enriched as (
    select
        -- Order keys
        o.order_id,
        o.customer_id,

        -- Order attributes
        o.order_status_code,
        o.order_status,
        o.order_total_price,
        o.order_date,
        o.order_priority,
        o.clerk_id,
        o.ship_priority,

        -- Customer attributes (denormalized for easy downstream consumption)
        c.customer_name,
        c.market_segment    as customer_market_segment,
        c.account_balance   as customer_account_balance,

        -- Nation attributes
        n.nation_id,
        n.nation_name,
        n.region_name,

        -- Derived date parts (avoid re-computing downstream)
        year(o.order_date)          as order_year,
        month(o.order_date)         as order_month,
        quarter(o.order_date)       as order_quarter,
        date_trunc('month', o.order_date)::date as order_month_start

    from orders       o
    left join customers c on o.customer_id  = c.customer_id
    left join nations   n on c.nation_id    = n.nation_id
)

select * from enriched
