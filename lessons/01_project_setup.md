# Lesson 1: Project Setup & Your First Model

## Learning Objectives

By the end of this lesson you will be able to:
- Understand what a dbt project looks like
- Configure a connection to Snowflake using `profiles.yml`
- Load raw data with `dbt seed`
- Define a source in YML
- Write and run your first staging model

---

## 1.1 Prerequisites

Before starting, ensure you have:
- **dbt-core** and **dbt-snowflake** installed (`pip install dbt-core dbt-snowflake`)
- A Snowflake account with a database, warehouse, and role you can use
- This repository cloned locally

Verify your install:

```bash
dbt --version
```

---

## 1.2 Configure Your Connection

Copy the example profile and edit it with your Snowflake credentials:

**Linux/macOS:**
```bash
cp profiles.yml.example ~/.dbt/profiles.yml
```

**Windows:**
```powershell
Copy-Item profiles.yml.example $HOME\.dbt\profiles.yml
```

Open `~/.dbt/profiles.yml` (Linux/macOS) or `$HOME\.dbt\profiles.yml` (Windows) and replace the placeholder values:

```yaml
dbt_learning:
  target: dev
  outputs:
    dev:
      type: snowflake
      account: YOUR_ACCOUNT       # e.g. abc12345.us-east-1
      user: YOUR_EMAIL            # Your Okta SSO email address
      authenticator: externalbrowser
      role: YOUR_ROLE
      database: YOUR_DATABASE
      warehouse: YOUR_WAREHOUSE
      schema: public
      threads: 4
```

> **Key concept:** The `authenticator: externalbrowser` setting tells dbt to open your default browser for Okta SSO login. No password is stored in the file. When you run any dbt command, a browser tab will open for you to authenticate.

Test the connection:

```bash
dbt debug
```

You should see "All checks passed!" at the end of the output.

---

## 1.3 Load Seed Data

Seeds are CSV files that dbt loads directly into your warehouse. Copy the seed files from the assets folder:

**Linux/macOS:**
```bash
cp assets/seeds/customers.csv seeds/
cp assets/seeds/orders.csv seeds/
```

**Windows:**
```powershell
Copy-Item assets\seeds\customers.csv seeds\
Copy-Item assets\seeds\orders.csv seeds\
```

Run the seed command:

```bash
dbt seed
```

This creates two tables in your Snowflake schema (suffixed `_raw` per our project config):
- `customers`
- `orders`

> **Key concept:** Seeds are for small, static reference data. For large datasets, use Snowflake's `COPY INTO` or other loading tools.

---

## 1.4 Define Your Source

Before writing models, tell dbt where the raw data lives. Create a source definition:

```bash
mkdir -p models/staging
```

Create `models/staging/sources.yml`:

```yaml
version: 2

sources:
  - name: raw                              # Logical name you'll use in source() calls
    description: "Raw seed data loaded via dbt seed"
    schema: "{{ target.schema }}_raw"      # Points to the actual Snowflake schema where seeds land
    tables:
      - name: customers                    # Must match the actual table name in Snowflake
        description: "Raw customer records"
      - name: orders
        description: "Raw order records"
```

> **Key concept:** The `source()` function in dbt points to tables that exist outside of your dbt project. It enables lineage tracking, freshness checks, and documentation.

---

## 1.5 Write Your First Staging Model

Create `models/staging/stg_customers.sql`:

```sql
-- CTE pattern: always start with an "import" CTE to isolate your raw data access.
-- This keeps the source() call in one place; if the source changes, you edit one line.
with source as (

    -- source('raw', 'customers') maps to the source defined in sources.yml.
    -- dbt resolves this to the fully qualified Snowflake table name at compile time.
    select * from {{ source('raw', 'customers') }}
)

select
    customer_id,
    first_name,
    last_name,
    email,

    -- Explicit casting ensures consistent data types across environments.
    -- Raw data often arrives as varchar; casting at the staging layer catches type
    -- issues early rather than letting them surface in downstream models.
    cast(created_at as date) as created_at,

    is_active
from source
```

This model:
- References the raw `customers` table via `{{ source() }}`
- Renames nothing yet, but casts `created_at` to a proper date type
- Uses a CTE pattern (`with source as ...`) that is standard in dbt

Run it:

```bash
dbt run --select stg_customers
```

---

## 1.6 Verify Your Work

Check that the model was created in Snowflake. You can run:

```bash
dbt show --select stg_customers
```

This previews the first rows of your model without leaving the terminal.

---

## 1.7 Exercises

1. Copy `assets/seeds/products.csv` into `seeds/` and run `dbt seed` again
2. Add a `products` table entry to your `sources.yml`
3. Create `models/staging/stg_products.sql` that selects from `{{ source('raw', 'products') }}` and casts `price` to `decimal(10, 2)`
4. Run `dbt run --select stg_products` and verify with `dbt show`

---

## 1.8 Key Takeaways

| Concept | What You Learned |
|---------|-----------------|
| `profiles.yml` | Configures your Snowflake connection |
| `dbt seed` | Loads CSV files into your warehouse |
| `sources.yml` | Declares external tables for dbt to reference |
| `{{ source() }}` | Function that references a declared source table |
| `dbt run` | Builds models into your warehouse |
| `dbt show` | Previews model output in the terminal |

---

**Next:** [Lesson 2 - Understanding YML Files](02_yml_files.md)
