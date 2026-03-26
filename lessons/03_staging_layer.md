# Lesson 3: The Staging Layer

## Learning Objectives

By the end of this lesson you will be able to:
- Understand the purpose of the staging layer
- Use `{{ ref() }}` to build model dependencies
- Apply naming conventions (`stg_` prefix)
- Choose materializations (view vs. ephemeral)
- Build a complete set of staging models

---

## Prerequisites

- **Completed:** Lessons 1-2
- **Models exist:** `stg_customers.sql` with basic tests
- **Seeds loaded:** `customers.csv`, `orders.csv` in `seeds/`

**Catch up:** If you're missing prerequisites, run:
```bash
python run.py catchup 3
# Or: ./scripts/catch_up.sh 3
```

---

## 3.1 What Is the Staging Layer?

The staging layer is the first transformation layer in your dbt project. It sits directly on top of your raw sources and has one job: **clean and standardize raw data**.

```
Raw Sources  -->  Staging  -->  Intermediate  -->  Marts
(source())       (stg_*)       (int_*)            (dim_*, fct_*)
```

Rules for staging models:
- **One-to-one** with source tables (one staging model per source table)
- **No joins** between tables
- **No business logic** or aggregation
- Only: renaming, casting, basic cleaning

---

## 3.2 The ref() Function

In Lesson 1 you used `{{ source() }}` to reference raw tables. From this point forward, every model you build will use `{{ ref() }}` to reference _other dbt models_.

```sql
-- ref() creates a dependency link between models. dbt uses these to build its DAG
-- (directed acyclic graph), which determines execution order automatically.
-- You never hard-code schema or table names — ref() resolves them for you.
select * from {{ ref('stg_customers') }}
```

> **Key concept:** `ref()` is what makes dbt powerful. It automatically builds a dependency graph (DAG) so dbt knows which models to run first. You never hard-code table names.

---

## 3.3 Naming Conventions

Every staging model follows this pattern:

```
stg_{source_name}__{table_name}.sql
```

Examples:
| Source Table | Staging Model |
|-------------|--------------|
| `raw.customers` | `stg_customers.sql` |
| `raw.orders` | `stg_orders.sql` |
| `raw.products` | `stg_products.sql` |
| `raw.order_items` | `stg_order_items.sql` |
| `raw.payments` | `stg_payments.sql` |

> **Note:** The double underscore (`__`) separates the source name from the table name. For this project we keep it simple, but in larger projects you'd use `stg_raw__customers` to distinguish from other sources.

---

## 3.4 The Standard Staging Template

Every staging model follows the same pattern:

```sql
-- Every staging model follows this same structure. Consistency across staging models
-- makes the codebase predictable and easy to onboard new contributors.
with source as (
    -- Import CTE: isolate raw data access to a single location.
    select * from {{ source('raw', 'table_name') }}
)

select
    -- Primary key: always list first for readability.
    id_column as entity_id,

    -- Attributes: rename columns to consistent, business-friendly names.
    -- This is the only place renaming should happen — downstream models
    -- inherit these clean names via ref().
    some_column as clean_name,

    -- Explicit type casting: raw data often loads as varchar/string.
    -- Casting here ensures every downstream model gets the correct type
    -- without needing to worry about implicit conversions.
    cast(date_column as date) as date_field,
    cast(amount_column as decimal(10, 2)) as amount_field

from source
```

---

## 3.5 Build All Staging Models

Make sure all five seed files are loaded:

**Linux/macOS:**
```bash
# Copy all seed files
cp assets/seeds/customers.csv seeds/
cp assets/seeds/orders.csv seeds/
cp assets/seeds/products.csv seeds/
cp assets/seeds/order_items.csv seeds/
cp assets/seeds/payments.csv seeds/

# Load seeds into Snowflake
dbt seed
```

**Windows:**
```powershell
# Copy all seed files
Copy-Item assets\seeds\customers.csv seeds\
Copy-Item assets\seeds\orders.csv seeds\
Copy-Item assets\seeds\products.csv seeds\
Copy-Item assets\seeds\order_items.csv seeds\
Copy-Item assets\seeds\payments.csv seeds\

# Load seeds into Snowflake
dbt seed
```

Now update your `sources.yml` to include all five tables. Add these entries to your `models/staging/sources.yml`:

```yaml
version: 2

sources:
  - name: raw
    description: "Raw seed data loaded via dbt seed"
    schema: "{{ generate_schema_name('raw') }}"
    tables:
      - name: customers
        description: "Raw customer records"
      - name: orders
        description: "Raw order records"
      - name: products
        description: "Raw product catalog"
      - name: order_items
        description: "Raw order line items"
      - name: payments
        description: "Raw payment transactions"
```

> **Tip**: You can also copy the complete template with `cp assets/yml_templates/sources.yml models/staging/`
>
> **Note:** The `generate_schema_name` macro creates user-specific schemas (e.g., `JDOE_RAW`). This macro is explained in detail in Lesson 8 — for now, just use the code as shown.

Then create each staging model. If you completed the Lesson 1 exercises, you already have `stg_customers` and `stg_products`. If not, copy them from assets first:

**Linux/macOS:**
```bash
# Only if you skipped the Lesson 1 exercises
cp assets/models/staging/stg_customers.sql models/staging/
cp assets/models/staging/stg_products.sql models/staging/
```

**Windows:**
```powershell
# Only if you skipped the Lesson 1 exercises
Copy-Item assets\models\staging\stg_customers.sql models\staging\
Copy-Item assets\models\staging\stg_products.sql models\staging\
```

Now add the remaining staging models:

**`models/staging/stg_orders.sql`**
```sql
with source as (
    select * from {{ source('raw', 'orders') }}
)

select
    order_id,
    customer_id,
    cast(order_date as date) as order_date,
    status,
    cast(amount as decimal(10, 2)) as amount
from source
```

**`models/staging/stg_order_items.sql`**
```sql
with source as (
    select * from {{ source('raw', 'order_items') }}
)

select
    line_item_id,
    order_id,
    product_id,
    quantity,
    cast(unit_price as decimal(10, 2)) as unit_price,

    -- Computed column: row-level math using only columns from this same table.
    -- This is acceptable in staging because it adds no cross-table logic.
    -- If this calculation involved data from another table, it would belong
    -- in the intermediate layer instead.
    quantity * cast(unit_price as decimal(10, 2)) as line_total
from source
```

**`models/staging/stg_payments.sql`**
```sql
with source as (
    select * from {{ source('raw', 'payments') }}
)

select
    payment_id,
    order_id,
    payment_method,
    cast(amount as decimal(10, 2)) as amount,
    cast(payment_date as date) as payment_date
from source
```

> **Note:** `stg_order_items` introduces a _computed column_ (`line_total`). This is acceptable in staging because it's a direct calculation on the same row, not business logic involving other tables.

---

## 3.6 Materialization: View vs. Ephemeral

In `dbt_project.yml`, staging models are configured as `view` by default:

```yaml
models:
  dbt_learning:
    staging:
      +materialized: view
```

Two common options for staging:

| Materialization | What Happens | When to Use |
|----------------|-------------|-------------|
| `view` | Creates a SQL view in Snowflake | Good for learning; you can query it directly |
| `ephemeral` | Compiled as a CTE (no object created) | Production; reduces warehouse clutter |

To try ephemeral, add a config block to any staging model:

```sql
-- config() at the top of a model overrides the folder-level default in dbt_project.yml.
-- 'ephemeral' means this model compiles to an inline CTE — no view or table is created
-- in Snowflake. This reduces warehouse clutter but means you can't query it directly.
{{ config(materialized='ephemeral') }}

with source as (
    ...
```

Or change the project-level config. For now, keep `view` so you can inspect results.

---

## 3.7 Run and Verify

Build all staging models:

```bash
dbt run --select staging
```

Verify they were created:

```bash
dbt show --select stg_orders --limit 5
dbt show --select stg_order_items --limit 5
dbt show --select stg_payments --limit 5
```

Run tests:

```bash
dbt test --select staging
```

---

## 3.8 Understanding the DAG

Run this to see your project's dependency graph:

```bash
dbt ls --resource-type model
```

Right now all staging models depend only on sources. In the next lesson, you'll build intermediate models that reference these staging models, creating a multi-layer DAG.

---

## 3.9 Exercises

1. Add a `line_total` computed column to `stg_order_items` if you haven't already
2. Try changing `stg_customers` to `ephemeral` materialization and run `dbt run`. What happens when you try `dbt show --select stg_customers`?
3. Create `.yml` files for all five staging models (e.g., `stg_products.yml`, `stg_order_items.yml`, `stg_payments.yml`) with `not_null` and `unique` tests on primary keys
4. Run `dbt test` and ensure all tests pass

---

## 3.10 Key Takeaways

| Concept | What You Learned |
|---------|-----------------|
| Staging layer | One-to-one with sources; clean and cast only |
| `{{ ref() }}` | References other dbt models; builds the DAG |
| Naming: `stg_` | Prefix identifies staging models |
| `view` | Creates a queryable view; good for development |
| `ephemeral` | Compiled as CTE; no warehouse object created |
| Computed columns | Simple row-level calculations are OK in staging |

---

## Further Reading

- [How we structure our dbt projects](https://docs.getdbt.com/best-practices/how-we-structure/1-guide-overview) - dbt Labs' official project structure guide
- [Staging models](https://docs.getdbt.com/best-practices/how-we-structure/2-staging) - Best practices for staging layer
- [The ref function](https://docs.getdbt.com/reference/dbt-jinja-functions/ref) - Complete ref() documentation
- [Materializations](https://docs.getdbt.com/docs/build/materializations) - All materialization types explained

---

**Previous:** [Lesson 2 - YML Files](02_yml_files.md) | **Next:** [Lesson 4 - Intermediate & Mart Models](04_intermediate_and_marts.md)
