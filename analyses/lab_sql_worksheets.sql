-- ─────────────────────────────────────────────────────────────────────────────
-- LAB 1.2 | Snowflake Core Concepts
-- ─────────────────────────────────────────────────────────────────────────────

-- 1. Set role and confirm identity
USE ROLE SYSADMIN;
SELECT CURRENT_USER(), CURRENT_ROLE(), CURRENT_WAREHOUSE(), CURRENT_DATABASE();


-- 2. Create course database and schemas
CREATE DATABASE IF NOT EXISTS DBT_COURSE_DB;
CREATE SCHEMA  IF NOT EXISTS DBT_COURSE_DB.STAGING;
CREATE SCHEMA  IF NOT EXISTS DBT_COURSE_DB.INTERMEDIATE;
CREATE SCHEMA  IF NOT EXISTS DBT_COURSE_DB.MARTS;
CREATE SCHEMA  IF NOT EXISTS DBT_COURSE_DB.SEEDS;
CREATE SCHEMA  IF NOT EXISTS DBT_COURSE_DB.SNAPSHOTS;


-- 3. Create a dedicated virtual warehouse for the course
CREATE WAREHOUSE IF NOT EXISTS COURSE_WH
    WAREHOUSE_SIZE = 'X-SMALL'
    AUTO_SUSPEND   = 60        -- suspend after 60s idle
    AUTO_RESUME    = TRUE
    INITIALLY_SUSPENDED = TRUE;

USE WAREHOUSE COURSE_WH;


-- 4. Explore TPC-H sample data (already in your account)
USE DATABASE SNOWFLAKE_SAMPLE_DATA;
USE SCHEMA TPCH_SF1;

SHOW TABLES;


-- 5. Preview each source table
SELECT * FROM ORDERS    LIMIT 10;
SELECT * FROM LINEITEM  LIMIT 10;
SELECT * FROM CUSTOMER  LIMIT 10;
SELECT * FROM NATION    LIMIT 10;
SELECT * FROM PART      LIMIT 10;
SELECT * FROM SUPPLIER  LIMIT 10;
SELECT * FROM REGION    LIMIT 10;


-- 6. Row counts
SELECT 'ORDERS'    AS tbl, COUNT(*) AS row_count FROM ORDERS   UNION ALL
SELECT 'LINEITEM'  AS tbl, COUNT(*) AS row_count FROM LINEITEM UNION ALL
SELECT 'CUSTOMER'  AS tbl, COUNT(*) AS row_count FROM CUSTOMER UNION ALL
SELECT 'NATION'    AS tbl, COUNT(*) AS row_count FROM NATION   UNION ALL
SELECT 'PART'      AS tbl, COUNT(*) AS row_count FROM PART     UNION ALL
SELECT 'SUPPLIER'  AS tbl, COUNT(*) AS row_count FROM SUPPLIER UNION ALL
SELECT 'REGION'    AS tbl, COUNT(*) AS row_count FROM REGION;


-- 7. Sample analytics query — total revenue by region
SELECT
    r.R_NAME                          AS region,
    SUM(l.L_EXTENDEDPRICE * (1 - l.L_DISCOUNT)) AS total_revenue
FROM ORDERS o
JOIN LINEITEM  l ON o.O_ORDERKEY  = l.L_ORDERKEY
JOIN CUSTOMER  c ON o.O_CUSTKEY   = c.C_CUSTKEY
JOIN NATION    n ON c.C_NATIONKEY = n.N_NATIONKEY
JOIN REGION    r ON n.N_REGIONKEY = r.R_REGIONKEY
GROUP BY 1
ORDER BY 2 DESC;
-- After running: click "Query Profile" to see the execution plan


-- 8. Explore INFORMATION_SCHEMA
SELECT
    TABLE_NAME,
    TABLE_TYPE,
    ROW_COUNT,
    BYTES
FROM SNOWFLAKE_SAMPLE_DATA.INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'TPCH_SF1'
ORDER BY ROW_COUNT DESC;


-- 9. Grant usage on course database to PUBLIC (so all participants can read)
GRANT USAGE  ON DATABASE DBT_COURSE_DB TO ROLE PUBLIC;
GRANT USAGE  ON ALL SCHEMAS IN DATABASE DBT_COURSE_DB TO ROLE PUBLIC;
GRANT SELECT ON ALL TABLES  IN DATABASE DBT_COURSE_DB TO ROLE PUBLIC;


-- ─────────────────────────────────────────────────────────────────────────────
-- LAB 2.1 | Sources & Source Freshness Verification
-- ─────────────────────────────────────────────────────────────────────────────

-- After running  dbt source freshness  in dbt Cloud, check results:
SELECT
    DATABASE_NAME,
    SCHEMA_NAME,
    TABLE_NAME,
    LAST_ALTERED
FROM SNOWFLAKE.ACCOUNT_USAGE.TABLES
WHERE SCHEMA_NAME = 'TPCH_SF1'
ORDER BY LAST_ALTERED DESC;


-- ─────────────────────────────────────────────────────────────────────────────
-- LAB 2.3 | Incremental Models — Simulate New Data
-- ─────────────────────────────────────────────────────────────────────────────

-- After building fct_orders as incremental, check the watermark:
USE DATABASE DBT_COURSE_DB;
USE SCHEMA MARTS;

SELECT
    MAX(order_date)  AS latest_order_date,
    COUNT(*)         AS total_rows
FROM fct_orders;

-- The incremental model's WHERE clause will use this max date
-- on the next run to only process newer orders.


-- ─────────────────────────────────────────────────────────────────────────────
-- LAB 2.4 | Snapshot History Query
-- ─────────────────────────────────────────────────────────────────────────────

-- After running  dbt snapshot  and simulating a change:
USE SCHEMA SNAPSHOTS;
SHOW TABLES LIKE '%CUSTOMER%';

-- View all rows for a specific customer (demonstrates SCD Type 2 history)
SELECT
    customer_id,
    customer_name,
    market_segment,
    account_balance,
    dbt_valid_from,
    dbt_valid_to,
    CASE WHEN dbt_valid_to IS NULL THEN 'CURRENT' ELSE 'HISTORICAL' END AS row_type
FROM customers_snapshot
WHERE customer_id = 1
ORDER BY dbt_valid_from;

-- Count current vs historical rows
SELECT
    CASE WHEN dbt_valid_to IS NULL THEN 'Current' ELSE 'Historical' END AS row_type,
    COUNT(*) AS row_count
FROM customers_snapshot
GROUP BY 1;


-- ─────────────────────────────────────────────────────────────────────────────
-- LAB 3.1 | Verify Test Results
-- ─────────────────────────────────────────────────────────────────────────────

-- After  dbt test --store-failures , query failure tables:
USE SCHEMA DBT_COURSE_DB.DBT_TEST__AUDIT;
SHOW TABLES;

-- Query a specific failure table (naming convention: <test>_<model>_<column>)
-- Example:
-- SELECT * FROM not_null_fct_orders_order_id LIMIT 20;


-- ─────────────────────────────────────────────────────────────────────────────
-- LAB 3.4 | Inspect dbt Artefacts stored in Snowflake
-- ─────────────────────────────────────────────────────────────────────────────

-- dbt Cloud stores run results in dbt Cloud UI (not Snowflake directly),
-- but you can see the objects created by each environment here:

SHOW SCHEMAS IN DATABASE DBT_COURSE_DB;

-- Count objects per schema
SELECT
    s.SCHEMA_NAME,
    COUNT(t.TABLE_NAME) AS object_count
FROM INFORMATION_SCHEMA.SCHEMATA     s
LEFT JOIN INFORMATION_SCHEMA.TABLES  t
    ON s.SCHEMA_NAME = t.TABLE_SCHEMA
GROUP BY 1
ORDER BY 2 DESC;


-- ─────────────────────────────────────────────────────────────────────────────
-- CAPSTONE | Verification Queries
-- ─────────────────────────────────────────────────────────────────────────────

-- Verify all marts are populated
SELECT 'fct_orders'   AS model, COUNT(*) AS rows FROM DBT_COURSE_DB.MARTS.FCT_ORDERS
UNION ALL
SELECT 'dim_customers', COUNT(*) FROM DBT_COURSE_DB.MARTS.DIM_CUSTOMERS;

-- Sample revenue by customer tier
SELECT
    customer_tier,
    COUNT(*)                         AS customer_count,
    SUM(lifetime_order_value)        AS total_lifetime_value,
    AVG(lifetime_order_value)        AS avg_lifetime_value
FROM DBT_COURSE_DB.MARTS.DIM_CUSTOMERS
GROUP BY 1
ORDER BY total_lifetime_value DESC;

-- Order volume trend
SELECT
    order_year,
    order_quarter,
    COUNT(*)                         AS order_count,
    SUM(total_gross_price)           AS gross_revenue
FROM DBT_COURSE_DB.MARTS.FCT_ORDERS
GROUP BY 1, 2
ORDER BY 1, 2;
