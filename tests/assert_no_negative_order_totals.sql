/*
  tests/assert_no_negative_order_totals.sql
  ─────────────────────────────────────────
  Singular test: verifies that no order has a negative total price.

  Convention: any rows returned by this query = TEST FAILURE.
  An empty result set = TEST PASS.

  Run with:
    dbt test --select assert_no_negative_order_totals
*/

select
    order_id,
    order_total_price
from {{ ref('fct_orders') }}
where order_total_price < 0
