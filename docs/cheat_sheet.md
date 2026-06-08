# dbt Cloud + Snowflake Foundations — Quick Reference Cheat Sheet

---

## dbt Commands

| Command | What it does |
|---------|-------------|
| `dbt debug` | Test connection & project configuration |
| `dbt deps` | Install packages from `packages.yml` |
| `dbt seed` | Load CSV seed files into the warehouse |
| `dbt source freshness` | Check freshness of declared sources |
| `dbt compile` | Compile models without executing SQL |
| `dbt run` | Execute all models |
| `dbt run --select my_model` | Run a specific model |
| `dbt run --select +my_model+` | Run model + all parents and children |
| `dbt run --select tag:daily` | Run all models tagged `daily` |
| `dbt run --full-refresh` | Rebuild incremental models from scratch |
| `dbt test` | Run all tests |
| `dbt test --select my_model` | Run tests for a specific model |
| `dbt snapshot` | Execute snapshot models |
| `dbt build` | Run + test + seed + snapshot (in order) |
| `dbt build --select state:modified+` | Slim CI: only changed nodes + children |
| `dbt docs generate` | Build JSON documentation artefacts |
| `dbt docs serve` | Serve docs site locally on port 8080 |

---

## dbt Project Structure

```
my_project/
├── dbt_project.yml        ← project config, model paths, materializations
├── packages.yml           ← external package dependencies
├── models/
│   ├── staging/           ← stg_<source>__<entity>.sql
│   ├── intermediate/      ← int_<verb>_<entity>.sql
│   └── marts/             ← fct_<entity>.sql  /  dim_<entity>.sql
├── macros/                ← reusable Jinja SQL functions
├── snapshots/             ← SCD Type 2 snapshot definitions
├── seeds/                 ← static CSV reference data
├── tests/                 ← singular SQL test files
└── docs/                  ← doc blocks (.md files)
```

### Naming Conventions

| Layer | Pattern | Example |
|-------|---------|---------|
| Staging | `stg_<source>__<entity>` | `stg_tpch__orders` |
| Intermediate | `int_<verb>_<entity>` | `int_orders_enriched` |
| Fact | `fct_<entity>` | `fct_orders` |
| Dimension | `dim_<entity>` | `dim_customers` |

---

## Jinja Templating

| Syntax | Purpose |
|--------|---------|
| `{{ ref('model_name') }}` | Reference another dbt model |
| `{{ source('schema', 'table') }}` | Reference a raw source table |
| `{{ this }}` | Current model's relation (for incremental) |
| `{{ config(materialized='table') }}` | Set model config inline |
| `{{ env_var('MY_VAR') }}` | Read an environment variable |
| `{{ target.schema }}` | Current target schema name |
| `{% if is_incremental() %}` | Conditional block for incremental logic |
| `{{ dbt_utils.generate_surrogate_key([...]) }}` | Create a surrogate key (dbt-utils) |

---

## Materializations

| Type | Description | Best For |
|------|-------------|----------|
| `view` | Rebuilt on every query (default) | Staging models, lightweight transforms |
| `table` | Physical table rebuilt on each run | Marts, frequently queried models |
| `incremental` | Appends/merges only new rows | Large fact tables, event data |
| `ephemeral` | CTE, never written to warehouse | Simple CTEs used in one place |

---

## Generic Tests

```yaml
columns:
  - name: order_id
    tests:
      - not_null
      - unique
  - name: status
    tests:
      - accepted_values:
          values: ['O', 'F', 'P']
  - name: customer_id
    tests:
      - relationships:
          to: ref('dim_customers')
          field: customer_id
```

---

## Incremental Model Pattern

```sql
{{ config(
    materialized = 'incremental',
    unique_key   = 'order_id'
) }}

SELECT * FROM {{ ref('stg_orders') }}

{% if is_incremental() %}
  WHERE updated_at > (SELECT MAX(updated_at) FROM {{ this }})
{% endif %}
```

---

## Snapshot Pattern

```sql
{% snapshot my_snapshot %}
{{ config(
    target_schema = 'snapshots',
    unique_key    = 'id',
    strategy      = 'timestamp',
    updated_at    = 'updated_at'
) }}
SELECT * FROM {{ source('raw', 'my_table') }}
{% endsnapshot %}
```

---

## Snowflake Quick Reference

| SQL | Purpose |
|-----|---------|
| `USE ROLE SYSADMIN;` | Switch to admin role |
| `USE WAREHOUSE COMPUTE_WH;` | Activate a warehouse |
| `USE DATABASE my_db;` | Set active database |
| `USE SCHEMA my_schema;` | Set active schema |
| `SHOW TABLES;` | List tables in current schema |
| `DESCRIBE TABLE my_table;` | Show column definitions |
| `SELECT CURRENT_USER();` | Check connected user |
| `CREATE WAREHOUSE ... AUTO_SUSPEND=60;` | Create warehouse with auto-suspend |
| `ALTER WAREHOUSE wh SUSPEND;` | Manually suspend warehouse |

---

## Key URLs

| Resource | URL |
|----------|-----|
| dbt Cloud | cloud.getdbt.com |
| dbt Docs | docs.getdbt.com |
| dbt Learn | courses.getdbt.com |
| dbt Slack | getdbt.com/community |
| Snowflake UI | app.snowflake.com |
| Snowflake Docs | docs.snowflake.com |
| Snowflake University | training.snowflake.com |
| dbt-utils (GitHub) | github.com/dbt-labs/dbt-utils |

---
