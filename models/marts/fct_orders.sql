/*
  fct_orders.sql
  ───────────────
  Fact table: one row per customer order with all header-level metrics.
  Source of truth for order-level revenue and status reporting.

  Materialisation: incremental (merge on order_id)
  Unique key: order_id
*/

{{
  config(
    materialized = 'incremental',
    unique_key   = 'order_id',
    on_schema_change = 'sync_all_columns'
  )
}}

with

orders_enriched as (
    select * from {{ ref('int_orders_enriched') }}
),

lineitems_agg as (
    -- Roll up line-level metrics to the order level
    select
        order_id,
        count(*)                     as line_item_count,
        sum(quantity)                as total_quantity,
        sum(extended_price)          as total_extended_price,
        sum(net_price)               as total_net_price,
        sum(gross_price)             as total_gross_price,
        avg(discount_fraction)       as avg_discount,
        min(ship_date)               as first_ship_date,
        max(ship_date)               as last_ship_date,
        count_if(return_flag = 'R')  as returned_line_count
    from {{ ref('stg_tpch__lineitems') }}
    group by 1
),

final as (
    select
        -- Surrogate key (dbt-utils)
        {{ dbt_utils.generate_surrogate_key(['o.order_id']) }} as order_sk,

        -- Natural key
        o.order_id,

        -- Dimensions
        o.customer_id,
        o.customer_name,
        o.customer_market_segment,
        o.nation_id,
        o.nation_name,
        o.region_name,
        o.order_status_code,
        o.order_status,
        o.order_priority,
        o.clerk_id,

        -- Date dimensions
        o.order_date,
        o.order_year,
        o.order_month,
        o.order_quarter,
        o.order_month_start,

        -- Source metrics (from order header)
        o.order_total_price,

        -- Computed line-level rollups
        l.line_item_count,
        l.total_quantity,
        l.total_extended_price,
        l.total_net_price,
        l.total_gross_price,
        l.avg_discount,
        l.first_ship_date,
        l.last_ship_date,
        l.returned_line_count,

        -- Derived flags
        case when l.returned_line_count > 0 then true else false end as has_returns,
        case when o.order_status = 'Fulfilled' then true else false end as is_fulfilled,

        -- Metadata
        current_timestamp() as dbt_loaded_at

    from orders_enriched o
    left join lineitems_agg l on o.order_id = l.order_id
)

select * from final

{% if is_incremental() %}
-- Only process orders placed after the latest order already in this table
where order_date > (select max(order_date) from {{ this }})
{% endif %}
