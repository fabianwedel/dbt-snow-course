/*
  customers_snapshot.sql
  ───────────────────────
  SCD Type 2 snapshot of the TPC-H CUSTOMER table.
  Captures the full history of changes to customer records.

  Added columns by dbt:
    dbt_scd_id       — hash of the row (unique row key)
    dbt_valid_from   — timestamp when this version became active
    dbt_valid_to     — timestamp when this version was superseded (NULL = current)
    dbt_updated_at   — source timestamp used to detect changes

  Run with:  dbt snapshot
  Query current state:
    SELECT * FROM snapshots.customers_snapshot WHERE dbt_valid_to IS NULL;
  Query history for one customer:
    SELECT * FROM snapshots.customers_snapshot WHERE customer_id = 12345 ORDER BY dbt_valid_from;
*/

{% snapshot customers_snapshot %}

{{
    config(
        target_schema = 'snapshots',
        unique_key    = 'customer_id',
        strategy      = 'check',
        check_cols    = [
            'customer_name',
            'customer_address',
            'customer_phone',
            'account_balance',
            'market_segment'
        ]
    )
}}

-- Source: use the staging model so column names are already clean
select
    customer_id,
    customer_name,
    customer_address,
    customer_phone,
    account_balance,
    market_segment,
    nation_id,
    customer_comment
from {{ ref('stg_tpch__customers') }}

{% endsnapshot %}
