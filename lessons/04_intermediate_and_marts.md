# Lesson 4: Intermediate & Mart Models

## Learning Objectives

By the end of this lesson you will be able to:
- Build intermediate models that join and enrich staging data
- Build mart models (dimensions and facts) for business users
- Understand materializations: `table`, `view`, and `incremental`
- Use CTEs to write clear, readable SQL
- Follow the full data flow: staging --> intermediate --> marts

---

## Prerequisites

- **Completed:** Lessons 1-3
- **Models exist:** All five staging models (`stg_customers`, `stg_orders`, `stg_products`, `stg_order_items`, `stg_payments`)
- **Seeds loaded:** All CSV files in `seeds/`
- **Verified:** `dbt run --select staging` completes successfully

**Catch up:** If you're missing prerequisites, run:
```bash
./scripts/catch_up.sh 4
```

---

## 4.1 The Three-Layer Architecture

```
Sources (raw)
    |
    v
Staging (stg_*)        <-- Clean, cast, rename. No joins.
    |
    v
Intermediate (int_*)   <-- Join, enrich, apply business logic
    |
    v
Marts (dim_*, fct_*)   <-- Final business-ready tables
```

Each layer has a clear responsibility. This lesson covers the last two.

---

## 4.2 Intermediate Models

Intermediate models combine staging models and add business logic. They are _internal_ building blocks — not exposed directly to business users.

**Naming:** `int_{entity}__{description}.sql`

### Example: Orders with Payments

Create `models/intermediate/int_orders_with_payments.sql`:

```sql
-- Import CTEs: each dependency gets its own CTE for clarity.
-- This pattern makes it obvious which models feed this one.
with orders as (
    select * from {{ ref('stg_orders') }}
),

payments as (
    select * from {{ ref('stg_payments') }}
)

select
    o.order_id,
    o.customer_id,
    o.order_date,
    o.status,
    o.amount as order_amount,
    p.payment_id,
    p.payment_method,
    p.amount as paid_amount,
    p.payment_date,

    -- Derived boolean flag: this is business logic that belongs in the intermediate
    -- layer, not staging. We check if a payment record exists for this order.
    -- Using a case expression (not just p.payment_id is not null) makes the
    -- intent explicit and the output a clean true/false.
    case
        when p.payment_id is not null then true
        else false
    end as is_paid

-- LEFT JOIN preserves all orders, even those without payments.
-- An INNER JOIN here would silently drop unpaid orders from the dataset.
from orders o
left join payments p on o.order_id = p.order_id
```

**What this does:**
- Joins orders with their payments
- Adds `is_paid` flag (business logic)
- Uses a LEFT JOIN so unpaid orders are still included

### Example: Order Items with Products

Create `models/intermediate/int_order_items_with_products.sql`:

```sql
with order_items as (
    select * from {{ ref('stg_order_items') }}
),

products as (
    select * from {{ ref('stg_products') }}
)

select
    oi.line_item_id,
    oi.order_id,
    oi.product_id,

    -- Enrichment: bringing in descriptive attributes from a related table.
    -- This is the core job of the intermediate layer — combining data from
    -- multiple staging models so mart models don't need complex joins.
    p.product_name,
    p.category,

    oi.quantity,
    oi.unit_price,
    oi.line_total
from order_items oi
left join products p on oi.product_id = p.product_id
```

---

## 4.3 CTE Best Practices

CTEs (Common Table Expressions) make SQL readable. Follow this pattern:

```sql
with

-- Step 1: Import CTEs pull in dependencies. Name them after the model they reference.
customers as (
    select * from {{ ref('stg_customers') }}
),

orders as (
    select * from {{ ref('stg_orders') }}
),

-- Step 2: Transform CTEs contain the actual logic. Keep each CTE focused
-- on one logical operation (here: aggregation).
aggregated as (
    select
        customer_id,
        count(*) as order_count
    from orders
    group by customer_id
)

-- Step 3: Final select assembles the output. This is the only place where
-- you combine the import and transform CTEs together.
select
    c.*,
    -- coalesce() handles customers with zero orders (NULL from the LEFT JOIN).
    -- Always coalesce aggregated metrics to avoid NULLs leaking into marts.
    coalesce(a.order_count, 0) as order_count
from customers c
left join aggregated a on c.customer_id = a.customer_id
```

**Rules:**
1. First CTEs are always "import" CTEs that pull from `ref()`
2. Middle CTEs do transformations
3. Final `select` assembles the output
4. One CTE per logical step

---

## 4.4 Mart Models: Dimensions

Dimensions describe business entities (customers, products, locations). They change slowly.

**Naming:** `dim_{entity}.sql`

Before creating the dimension, we need its supporting intermediate model. Let's build that first.

### Supporting Model: Customer Order Summary

Create `models/intermediate/int_customers__order_summary.sql`:

```sql
with customers as (
    select * from {{ ref('stg_customers') }}
),

orders as (
    select * from {{ ref('stg_orders') }}
),

-- Aggregation CTE: compute order-level metrics per customer.
-- Keeping aggregation in a separate CTE (not in the final select) makes
-- the logic testable and the SQL easier to debug.
customer_orders as (
    select
        customer_id,
        count(*) as total_orders,
        sum(amount) as lifetime_value,
        min(order_date) as first_order_date,
        max(order_date) as last_order_date
    from orders
    group by customer_id
)

select
    c.customer_id,
    c.first_name,
    c.last_name,
    c.email,
    c.created_at,
    c.is_active,

    -- coalesce() turns NULLs into 0 for customers with no orders.
    -- Without this, customers who haven't ordered would show NULL
    -- instead of 0 in reports and break downstream arithmetic.
    coalesce(co.total_orders, 0) as total_orders,
    coalesce(co.lifetime_value, 0) as lifetime_value,
    co.first_order_date,
    co.last_order_date,

    -- Tier classification: business logic that converts a numeric metric
    -- into a categorical label. This lives in intermediate (not marts)
    -- because multiple mart models may need the same tier logic.
    case
        when co.lifetime_value >= 300 then 'gold'
        when co.lifetime_value >= 100 then 'silver'
        else 'bronze'
    end as customer_tier
from customers c
left join customer_orders co on c.customer_id = co.customer_id
```

Add a YML file for the intermediate model. Create `models/intermediate/int_customers__order_summary.yml`:

```yaml
version: 2

models:
  - name: int_customers__order_summary
    description: "Customer data enriched with order metrics and tier classification"
    columns:
      - name: customer_id
        description: "Primary key for customers"
        tests:
          - not_null
          - unique
      - name: lifetime_value
        description: "Sum of all order amounts for this customer"
      - name: customer_tier
        description: "Customer value tier: gold (>=$300), silver (>=$100), bronze (<$100)"
```

### The Dimension Model

Now create `models/marts/dim_customers.sql`:

```sql
-- Thin mart pattern: dim_customers delegates all heavy logic to the intermediate
-- layer and simply selects the final columns. This keeps marts clean, auditable,
-- and easy to extend — add a new metric in the intermediate model and it flows here.
with customer_summary as (
    select * from {{ ref('int_customers__order_summary') }}
)

select
    customer_id,
    first_name,
    last_name,
    email,
    created_at,
    is_active,
    total_orders,
    lifetime_value,
    first_order_date,
    last_order_date,
    customer_tier
from customer_summary
```

> **Key concept:** The mart model (`dim_customers`) is intentionally thin. All the heavy lifting — joins, aggregation, tier logic — lives in the intermediate model. This keeps marts clean and intermediate models reusable.

---

## 4.5 Mart Models: Facts

Facts record business events (orders, transactions, clicks). They grow over time.

**Naming:** `fct_{process}.sql`

Create `models/marts/fct_orders.sql`:

```sql
-- Fact table: assembles event-level data from multiple intermediate models.
-- Facts grow over time (new orders arrive daily), so they're candidates
-- for incremental materialization in production.
with orders_with_payments as (
    select * from {{ ref('int_orders_with_payments') }}
),

order_items as (
    select * from {{ ref('int_order_items_with_products') }}
),

-- Pre-aggregate line items per order before joining, so the final select
-- stays one row per order. Joining un-aggregated line items would fan out
-- the order rows (one order x many items = many rows).
order_line_summary as (
    select
        order_id,
        count(*) as total_line_items,
        sum(line_total) as line_items_total
    from order_items
    group by order_id
)

select
    owp.order_id,
    owp.customer_id,
    owp.order_date,
    owp.status,
    owp.order_amount,
    owp.payment_method,
    owp.is_paid,
    coalesce(ols.total_line_items, 0) as total_line_items,
    coalesce(ols.line_items_total, 0) as line_items_total
from orders_with_payments owp
left join order_line_summary ols on owp.order_id = ols.order_id
```

---

## 4.6 Materializations

dbt supports several materializations. Here's when to use each:

| Materialization | Creates | Best For |
|----------------|---------|----------|
| `view` | SQL view | Development, small datasets |
| `table` | Physical table | Dimensions, small facts, frequently queried models |
| `incremental` | Table + append logic | Large fact tables that grow over time |
| `ephemeral` | Nothing (CTE only) | Internal models not queried directly |

**Project-level config** (in `dbt_project.yml`):
```yaml
models:
  dbt_learning:
    staging:
      +materialized: view
    intermediate:
      +materialized: view
    marts:
      +materialized: table
```

**Model-level override** (in the SQL file):
```sql
{{ config(materialized='incremental', unique_key='order_id') }}
```

Model-level configs always override project-level configs.

---

## 4.7 Incremental Models (Preview)

For large fact tables, `incremental` avoids reprocessing all data on every run:

```sql
-- config() block: model-level configuration overrides the folder default.
-- 'incremental' tells dbt to append new rows instead of rebuilding the full table.
-- 'unique_key' enables merge behavior: if an existing order_id arrives again,
-- dbt updates that row instead of creating a duplicate.
{{ config(
    materialized='incremental',
    unique_key='order_id'
) }}

select
    order_id,
    customer_id,
    order_date,
    status,
    amount
from {{ ref('stg_orders') }}

-- is_incremental() returns true only when:
--   1. The model is configured as incremental, AND
--   2. The target table already exists in the warehouse.
-- On the very first run, this block is skipped and the full table is built.
-- On subsequent runs, only rows newer than the current max are processed.
{% if is_incremental() %}
    -- {{ this }} refers to the already-materialized table in Snowflake.
    -- This is how incremental models "know" what data they already have.
    where order_date > (select max(order_date) from {{ this }})
{% endif %}
```

**How it works:**
- First run: creates the full table
- Subsequent runs: only processes new rows (where `order_date` is after the max existing date)
- `{{ this }}` refers to the existing table in the warehouse

---

## 4.8 Run the Full Project

Build everything in order:

```bash
dbt run
```

dbt automatically runs models in dependency order:
1. Staging models (depend on sources)
2. Intermediate models (depend on staging)
3. Mart models (depend on intermediate/staging)

Verify your marts:

```bash
dbt show --select dim_customers --limit 5
dbt show --select fct_orders --limit 5
```

---

## 4.9 Exercises

1. Run `dbt run` and verify all models compile and execute
2. Run `dbt ls --resource-type model` to see the full model list
3. **Convert `fct_orders` to incremental** (detailed instructions below)
4. Create `.yml` files for each intermediate model (e.g., `int_orders_with_payments.yml`, `int_order_items_with_products.yml`, `int_customers__order_summary.yml`) with `not_null` + `unique` tests on primary keys

### Exercise 3: Convert fct_orders to Incremental (Detailed Steps)

**Step 1**: Open `models/marts/fct_orders.sql` and add the config block at the top:

```sql
{{ config(
    materialized='incremental',
    unique_key='order_id',
    incremental_strategy='merge',
    cluster_by=['order_date']
) }}

-- Rest of your model below...
```

**Step 2**: Add the incremental filter at the end of your SQL (before the final semicolon):

```sql
-- Your existing SQL above...

from orders_with_payments owp
left join order_line_summary ols on owp.order_id = ols.order_id

{% if is_incremental() %}
    -- Only process new orders on subsequent runs
    where owp.order_date > (select max(order_date) from {{ this }})
{% endif %}
```

**Step 3**: Test the incremental behavior:

```bash
# First run: builds full table
dbt run --select fct_orders

# Second run: processes 0 rows (no new data)
dbt run --select fct_orders

# Force full refresh
dbt run --select fct_orders --full-refresh
```

**Expected output on second run:**
```
Completed successfully

Done. PASS=1 WARN=0 ERROR=0 SKIP=0 TOTAL=1
```

> **What you learned**: Incremental models dramatically improve performance for large tables by only processing new data on subsequent runs.

---

## 4.10 Key Takeaways

| Concept | What You Learned |
|---------|-----------------|
| Intermediate (`int_`) | Joins and enriches staging models |
| Dimensions (`dim_`) | Describe business entities; materialized as tables |
| Facts (`fct_`) | Record business events; can be incremental |
| CTEs | Import --> Transform --> Select pattern |
| `table` | Full rebuild on every run |
| `incremental` | Only processes new/changed rows |
| `{{ this }}` | References the current model's existing table |

---

**Previous:** [Lesson 3 - The Staging Layer](03_staging_layer.md) | **Next:** [Lesson 5 - Testing & Data Quality](05_testing.md)
