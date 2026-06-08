/*
  dim_customers.sql
  ──────────────────
  Customer dimension table.
  Includes aggregated order metrics denormalized for BI performance.
*/

{{
  config(
    materialized = 'table'
  )
}}

with

customers as (
    select * from {{ ref('stg_tpch__customers') }}
),

order_summary as (
    -- Aggregate order-level metrics per customer for the dim
    select
        customer_id,
        count(*)                        as total_orders,
        sum(order_total_price)          as lifetime_order_value,
        min(order_date)                 as first_order_date,
        max(order_date)                 as most_recent_order_date,
        count_if(order_status = 'Open') as open_order_count
    from {{ ref('fct_orders') }}
    group by 1
),

final as (
    select
        -- Surrogate key
        {{ dbt_utils.generate_surrogate_key(['c.customer_id']) }} as customer_sk,

        -- Natural key
        c.customer_id,

        -- Customer attributes
        c.customer_name,
        c.customer_address,
        c.customer_phone,
        c.market_segment,
        c.account_balance,
        c.nation_id,

        -- Aggregated order metrics (denormalized for BI convenience)
        coalesce(o.total_orders, 0)             as total_orders,
        coalesce(o.lifetime_order_value, 0)     as lifetime_order_value,
        o.first_order_date,
        o.most_recent_order_date,
        coalesce(o.open_order_count, 0)         as open_order_count,

        -- Derived segments
        case
            when o.lifetime_order_value >= 1000000 then 'Platinum'
            when o.lifetime_order_value >= 500000  then 'Gold'
            when o.lifetime_order_value >= 100000  then 'Silver'
            else 'Bronze'
        end as customer_tier,

        -- Metadata
        current_timestamp() as dbt_loaded_at

    from customers c
    left join order_summary o on c.customer_id = o.customer_id
)

select * from final
