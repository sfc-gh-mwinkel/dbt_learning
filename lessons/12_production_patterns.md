# Lesson 12: Production Patterns

## Learning Objectives

By the end of this lesson, you will:
- Master incremental models with merge strategies and the `is_incremental()` macro
- Use `target.name` for environment-aware configurations
- Monitor data freshness with source freshness checks
- Document downstream dependencies with exposures

---

## Prerequisites

- **Completed:** Lessons 1-11
- **Models exist:** Full project including incremental models
- **Recommended:** Understanding of Jinja from Lesson 8

**Catch up:** If you're missing prerequisites, run:
```bash
python run.py catchup 12
# Or: ./scripts/catch_up.sh 12
```

---

## 12.1 Incremental Models Deep-Dive

In Lesson 4, we briefly touched on incremental models. Now let's master them.

### Why Incremental?

| Materialization | Behavior | Use Case |
|----------------|----------|----------|
| `view` | Rebuilds query each time | Small, simple transforms |
| `table` | Full rebuild every run | Medium tables, complex logic |
| `incremental` | Only processes new/changed rows | Large tables, append-heavy data |

For a table with 100M rows where 10K rows are added daily:
- **Table**: Rebuilds 100M rows every run (~minutes)
- **Incremental**: Processes only 10K new rows (~seconds)

### The is_incremental() Macro

The `is_incremental()` macro returns `true` when:
1. The model is configured as `incremental`
2. The target table already exists
3. You're NOT running with `--full-refresh`

```sql
-- models/marts/fct_orders_incremental.sql
{{
    config(
        materialized='incremental',
        unique_key='order_id'
    )
}}

select
    order_id,
    customer_id,
    order_date,
    status,
    total_amount,
    current_timestamp() as loaded_at

from {{ ref('int_orders_with_payments') }}

{% if is_incremental() %}
    -- This filter only applies on incremental runs
    where order_date > (select max(order_date) from {{ this }})
{% endif %}
```

Key concepts:
- `{{ this }}` refers to the current model's existing table
- The `where` clause only applies on incremental runs
- First run (or `--full-refresh`) loads ALL data

### Create an Incremental Model

Create the file:

```sql
-- models/marts/fct_orders_incremental.sql
{{
    config(
        materialized='incremental',
        unique_key='order_id'
    )
}}

with source_data as (
    select
        o.order_id,
        o.customer_id,
        o.order_date,
        o.status,
        p.payment_method,
        p.amount as total_amount,
        current_timestamp() as loaded_at
    
    from {{ ref('stg_orders') }} o
    left join {{ ref('stg_payments') }} p
        on o.order_id = p.order_id
)

select * from source_data

{% if is_incremental() %}
    where order_date > (select max(order_date) from {{ this }})
{% endif %}
```

Run it twice to see incremental behavior:

```bash
# First run - full load
dbt run --select fct_orders_incremental

# Second run - incremental (should be faster, process 0 rows)
dbt run --select fct_orders_incremental

# Force full rebuild
dbt run --select fct_orders_incremental --full-refresh
```

### Incremental Strategies

Snowflake supports multiple strategies via the `incremental_strategy` config:

| Strategy | Behavior | Best For |
|----------|----------|----------|
| `merge` (default) | MERGE statement, updates existing + inserts new | When rows can be updated |
| `delete+insert` | Deletes matching rows, then inserts | Large batch updates |
| `append` | Only INSERT, never update | Pure append-only logs |

```sql
{{
    config(
        materialized='incremental',
        unique_key='order_id',
        incremental_strategy='merge'  -- or 'delete+insert', 'append'
    )
}}
```

### Handling Late-Arriving Data

Real data often arrives late. Use a lookback window:

```sql
{% if is_incremental() %}
    -- Look back 3 days to catch late arrivals
    where order_date > (select dateadd(day, -3, max(order_date)) from {{ this }})
{% endif %}
```

---

## 12.2 Environment-Aware Configurations

Production dbt projects typically have multiple environments (dev, staging, prod). Use the `target` variable to handle differences.

### The target Variable

The `target` variable contains your profile configuration:

| Property | Example | Description |
|----------|---------|-------------|
| `target.name` | `'dev'` | Target name from profiles.yml |
| `target.database` | `'DBT_LEARNING'` | Database name |
| `target.schema` | `'public'` | Default schema |
| `target.user` | `'JDOE'` | Snowflake username |
| `target.warehouse` | `'COMPUTE_WH'` | Warehouse name |

### Conditional Logic by Environment

Use `target.name` for environment-specific behavior:

```sql
-- Different sample sizes for dev vs prod
select *
from {{ ref('stg_orders') }}

{% if target.name == 'dev' %}
    -- In dev, limit to recent data for faster iteration
    where order_date >= dateadd(month, -3, current_date())
{% endif %}
```

### Environment-Aware Warehouse Sizing

The best place for environment-specific warehouse config is in `dbt_project.yml`, not individual models:

```yaml
# dbt_project.yml
models:
  dbt_learning:
    marts:
      +materialized: table
      +snowflake_warehouse: "{{ 'LARGE_WH' if target.name == 'prod' else 'COMPUTE_WH' }}"
```

This keeps environment logic centralized rather than scattered across models.

### Create an Environment-Aware Model

Let's create a model that behaves differently in dev:

```sql
-- models/marts/fct_orders_env_aware.sql
{{
    config(
        materialized='table'
    )
}}

with orders as (
    select *
    from {{ ref('int_orders_with_payments') }}
    
    {% if target.name == 'dev' %}
        -- Dev: only last 6 months of data
        where order_date >= dateadd(month, -6, current_date())
    {% endif %}
)

select
    order_id,
    customer_id,
    order_date,
    status,
    total_amount,
    '{{ target.name }}' as dbt_environment,  -- Track which env built this
    current_timestamp() as built_at

from orders
```

```bash
dbt run --select fct_orders_env_aware
dbt show --select fct_orders_env_aware --limit 3
```

---

## 12.3 Source Freshness

Source freshness monitoring helps you detect when upstream data pipelines are delayed or broken.

### Adding Freshness to Sources

Update your sources.yml to include freshness configuration:

```yaml
# models/staging/sources.yml
version: 2

sources:
  - name: raw
    description: "Raw data loaded by external processes"
    database: DBT_LEARNING
    schema: "{{ env_var('DBT_USER_PREFIX', target.user | upper) }}_RAW"
    
    freshness:
      warn_after: {count: 24, period: hour}
      error_after: {count: 48, period: hour}
    loaded_at_field: _loaded_at  # Column containing load timestamp
    
    tables:
      - name: customers
        description: "Customer master data"
        # Override freshness for this specific table
        freshness:
          warn_after: {count: 72, period: hour}  # Customers update less frequently
        
      - name: orders
        description: "Order transactions"
        # Uses default freshness from source level
        
      - name: products
        freshness: null  # Disable freshness check for static reference data
```

> **Note:** `env_var('DBT_USER_PREFIX', target.user | upper)` reads an optional environment variable. If `DBT_USER_PREFIX` is not set, it falls back to your Snowflake username uppercased (e.g., `MWINKEL_RAW`). See Lesson 1 for the full explanation.

### The loaded_at_field

For freshness checks to work, your source tables need a column indicating when rows were loaded. Common patterns:

| Column Name | Description |
|-------------|-------------|
| `_loaded_at` | Timestamp when ETL loaded the row |
| `_etl_loaded_ts` | Same concept, different naming |
| `updated_at` | Last modification timestamp |
| `created_at` | Works for append-only tables |

### Running Freshness Checks

```bash
# Check freshness of all sources
dbt source freshness

# Check specific source
dbt source freshness --select source:raw
```

Output shows status for each source:

```
Running freshness check on source raw.orders
  PASS: Last loaded 2 hours ago (warn threshold: 24 hours)
  
Running freshness check on source raw.customers  
  WARN: Last loaded 50 hours ago (warn threshold: 72 hours)
```

### Freshness in CI/CD

Add freshness checks to your deployment pipeline:

```bash
# Fail the pipeline if data is stale
dbt source freshness --select source:raw
if [ $? -ne 0 ]; then
    echo "Source data is stale! Investigate before proceeding."
    exit 1
fi

dbt build
```

---

## 12.4 Exposures

Exposures document how dbt models are used downstream - dashboards, applications, ML models, etc.

### Why Exposures?

- **Impact analysis**: Know what breaks when a model changes
- **Ownership**: Track who owns downstream assets
- **Documentation**: Complete picture of data flow
- **Lineage**: Exposures appear in dbt docs DAG

### Defining Exposures

Create an exposures file:

```yaml
# models/exposures.yml
version: 2

exposures:
  - name: executive_dashboard
    label: "Executive KPI Dashboard"
    type: dashboard
    maturity: high
    url: https://your-bi-tool.com/dashboards/executive
    description: >
      Weekly executive dashboard showing revenue, customer acquisition,
      and order metrics. Reviewed in Monday leadership meetings.
    
    depends_on:
      - ref('fct_orders')
      - ref('dim_customers')
    
    owner:
      name: Analytics Team
      email: analytics@company.com

  - name: customer_360_app
    label: "Customer 360 Application"
    type: application
    maturity: medium
    url: https://internal-apps.company.com/customer-360
    description: >
      Internal application for support team to view complete
      customer history and interactions.
    
    depends_on:
      - ref('dim_customers')
      - ref('fct_orders')
    
    owner:
      name: Engineering Team
      email: eng@company.com

  - name: churn_prediction_model
    label: "Customer Churn ML Model"
    type: ml
    maturity: low
    description: >
      Machine learning model predicting customer churn probability.
      Retrained weekly using customer order history.
    
    depends_on:
      - ref('dim_customers')
    
    owner:
      name: Data Science Team
      email: datascience@company.com
```

### Exposure Types

| Type | Use For |
|------|---------|
| `dashboard` | BI dashboards (Tableau, Looker, etc.) |
| `notebook` | Jupyter/analysis notebooks |
| `analysis` | Ad-hoc analyses or reports |
| `ml` | Machine learning models |
| `application` | Internal/external applications |

### Exposure Maturity

| Maturity | Meaning |
|----------|---------|
| `high` | Business-critical, heavily used |
| `medium` | Regular use, some dependencies |
| `low` | Experimental or limited use |

### Viewing Exposures

Exposures appear in dbt docs:

```bash
dbt docs generate
dbt docs serve
```

Navigate to the **Exposures** section or view them in the DAG connected to their source models.

### Selecting by Exposure

Run all models that an exposure depends on:

```bash
# Build everything the executive dashboard needs
dbt build --select +exposure:executive_dashboard
```

---

## 12.5 Putting It All Together

Let's create a production-ready model that combines these patterns:

```sql
-- models/marts/fct_daily_revenue.sql
{{
    config(
        materialized='incremental',
        unique_key='revenue_date',
        incremental_strategy='merge',
        snowflake_warehouse='COMPUTE_WH'
    )
}}

with daily_orders as (
    select
        date_trunc('day', order_date) as revenue_date,
        count(distinct order_id) as order_count,
        count(distinct customer_id) as unique_customers,
        sum(order_amount) as total_revenue
    
    from {{ ref('int_orders_with_payments') }}
    
    {% if is_incremental() %}
        -- Lookback 3 days to catch late-arriving data
        where order_date > (select dateadd(day, -3, max(revenue_date)) from {{ this }})
    {% elif target.name == 'dev' %}
        -- In dev, only process last 6 months
        where order_date >= dateadd(month, -6, current_date())
    {% endif %}
    
    group by 1
)

select
    revenue_date,
    order_count,
    unique_customers,
    total_revenue,
    total_revenue / nullif(order_count, 0) as avg_order_value,
    '{{ target.name }}' as built_in_environment,
    current_timestamp() as last_updated_at

from daily_orders
```

Add the YML:

```yaml
# models/marts/fct_daily_revenue.yml
version: 2

models:
  - name: fct_daily_revenue
    description: "Daily revenue aggregation with incremental loading"
    columns:
      - name: revenue_date
        description: "Date of revenue (day granularity)"
        tests:
          - not_null
          - unique
      - name: total_revenue
        description: "Sum of all order amounts for the day"
      - name: avg_order_value
        description: "Average order value (revenue / orders)"
```

Run and verify:

```bash
# Initial full load
dbt run --select fct_daily_revenue

# Incremental run
dbt run --select fct_daily_revenue

# Check the data
dbt show --select fct_daily_revenue --limit 5
```

---

## Exercise: Build Your Production Pipeline

1. **Add freshness monitoring**: Add a `_loaded_at` column concept to your seeds (simulate with `current_timestamp()` in staging) and configure freshness on your sources

2. **Create an exposure**: Document a fictional "Sales Dashboard" that depends on `fct_orders` and `dim_customers`

3. **Environment optimization**: Modify an existing model to limit data in dev but process everything in prod

4. **Test incremental behavior**:
   ```bash
   # Run these commands and observe the row counts
   dbt run --select fct_orders_incremental
   dbt run --select fct_orders_incremental
   dbt run --select fct_orders_incremental --full-refresh
   ```

---

## Key Takeaways

| Pattern | When to Use |
|---------|-------------|
| **Incremental models** | Large tables with append-heavy or slowly changing data |
| **is_incremental()** | Filter to only new/changed rows on incremental runs |
| **target.name** | Different behavior for dev/staging/prod |
| **Source freshness** | Monitor upstream data pipeline health |
| **Exposures** | Document downstream consumers for impact analysis |

---

## Production Checklist

Before deploying to production, verify:

- [ ] Large tables use incremental materialization
- [ ] Incremental models have appropriate lookback windows
- [ ] Dev environment limits data for fast iteration
- [ ] Source freshness is configured for critical sources
- [ ] Exposures document key dashboards and applications
- [ ] CI/CD pipeline includes freshness checks

---

## What's Next?

Congratulations! You've completed the dbt Learning Platform. You now have the skills to:

- Build a complete dbt project from scratch
- Implement proper testing and documentation
- Write custom macros and manage environments
- Deploy production-ready incremental pipelines

**Continue learning:**
- Explore the [dbt documentation](https://docs.getdbt.com/)
- Try packages like `dbt_expectations`, `audit_helper`, `codegen`
- Experiment with Python models for ML workflows
- Set up CI/CD with GitHub Actions or similar

---

## Further Reading

- [Incremental models](https://docs.getdbt.com/docs/build/incremental-models) - Complete incremental guide
- [Incremental strategies](https://docs.getdbt.com/docs/build/incremental-strategy) - Merge, append, delete+insert
- [Target variables](https://docs.getdbt.com/reference/dbt-jinja-functions/target) - Using target.name for environments
- [Exposures](https://docs.getdbt.com/docs/build/exposures) - Documenting downstream dependencies
- [Source freshness](https://docs.getdbt.com/docs/build/sources#snapshotting-source-data-freshness) - Freshness monitoring

Happy modeling! 🎉
