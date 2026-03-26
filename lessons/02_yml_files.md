# Lesson 2: Understanding YML Files

## Learning Objectives

By the end of this lesson you will be able to:
- Understand the role of YML files in a dbt project
- Write `sources.yml` with descriptions and basic tests
- Write model-specific `.yml` files to document and test your models
- Run `dbt test` to validate your data

---

## Prerequisites

- **Completed:** Lesson 1 (Project Setup)
- **Models exist:** `stg_customers.sql` in `models/staging/`
- **Seeds loaded:** `dbt seed` completed successfully
- **Connection verified:** `dbt debug` passes

**Catch up:** If you're missing prerequisites, run:
```bash
python run.py catchup 2
# Or: ./scripts/catch_up.sh 2
```

---

## 2.1 YML Files in dbt

dbt uses YAML files (`.yml`) for three main purposes:

| File | Purpose |
|------|---------|
| `dbt_project.yml` | Project-level configuration (covered in Lesson 6) |
| `sources.yml` | Declare raw data tables that exist outside dbt |
| `<model_name>.yml` | Document and test individual dbt models |

You already created a basic `sources.yml` in Lesson 1. Now let's deepen it.

---

## 2.2 Enriching sources.yml

Open `models/staging/sources.yml` and add column-level documentation and tests:

```yaml
version: 2

sources:
  - name: raw
    description: "Raw seed data loaded via dbt seed"
    schema: "{{ target.schema }}_raw"
    tables:
      - name: customers
        description: "Raw customer records"
        columns:
          - name: customer_id
            description: "Unique identifier for each customer"
            tests:
              - not_null        # Rejects any NULL primary key — data integrity starts here
              - unique          # Guarantees no duplicate rows sneak in from upstream
          - name: email
            description: "Customer email address"
            tests:
              - not_null

      - name: orders
        description: "Raw order records"
        columns:
          - name: order_id
            description: "Unique identifier for each order"
            tests:
              - not_null
              - unique
          - name: status
            description: "Current order status"
            tests:
              # accepted_values acts as a domain constraint — if a new, unexpected
              # status appears in the source system, this test fails immediately,
              # alerting you before bad data flows downstream.
              - accepted_values:
                  values: ['completed', 'pending', 'shipped', 'returned', 'cancelled']
```

Run the source tests:

```bash
dbt test --select source:raw
```

> **Key concept:** Tests on sources validate your raw data _before_ any transformation. This catches data quality issues at the door.

---

## 2.3 Creating Model YML Files (1:1 Pattern)

Each model gets its own `.yml` file with the same name. This keeps documentation close to the code and makes it easy to find.

Create `models/staging/stg_customers.yml`:

```yaml
version: 2

models:
  - name: stg_customers
    description: "Cleaned and typed customer data from raw source"
    columns:
      - name: customer_id
        description: "Primary key for customers"
        tests:
          # Every model's primary key should have both not_null and unique.
          # Together they enforce entity integrity at the transformation layer.
          - not_null
          - unique
      - name: email
        description: "Customer email address"
        tests:
          - not_null
```

Create `models/staging/stg_orders.yml`:

```yaml
version: 2

models:
  - name: stg_orders
    description: "Cleaned and typed order data from raw source"
    columns:
      - name: order_id
        description: "Primary key for orders"
        tests:
          - not_null
          - unique
      - name: customer_id
        description: "Foreign key to customers"
        tests:
          - not_null
          # relationships test enforces referential integrity — every customer_id
          # in stg_orders must exist in stg_customers. This catches orphaned records
          # caused by late-arriving data or source system bugs.
          - relationships:
              to: ref('stg_customers')
              field: customer_id
      - name: status
        description: "Current order status"
        tests:
          - accepted_values:
              values: ['completed', 'pending', 'shipped', 'returned', 'cancelled']
```

---

## 2.4 The Four Built-in Tests

dbt ships with four generic tests you can apply to any column:

| Test | What It Checks |
|------|---------------|
| `not_null` | No NULL values in the column |
| `unique` | No duplicate values in the column |
| `accepted_values` | All values are in a defined list |
| `relationships` | Every value exists in another model's column (referential integrity) |

These are declared in YAML and run with:

```bash
dbt test
```

Or target specific models:

```bash
dbt test --select stg_customers
dbt test --select stg_orders
```

---

## 2.5 Reading Test Output

When you run `dbt test`, the output shows:

```
Completed with 0 errors and 0 warnings
```

If a test fails, dbt tells you which test and how many rows failed. For example:

```
Failure in test unique_stg_customers_customer_id
  Got 3 results, configured to fail if != 0
```

This means 3 duplicate `customer_id` values were found. You'd go fix your source data or staging model.

---

## 2.6 Where to Put YML Files

The recommended convention is **1:1 model-to-yml files**:

```
models/staging/
  sources.yml           # Source definitions
  stg_customers.sql     # Model SQL
  stg_customers.yml     # Model documentation & tests
  stg_orders.sql
  stg_orders.yml
  stg_products.sql
  stg_products.yml
```

This approach:
- Keeps documentation close to the code
- Makes it easy to find tests for a specific model
- Reduces merge conflicts when multiple developers work on different models
- Scales well as projects grow

---

## 2.7 Exercises

1. Add the `products` and `order_items` tables to your `sources.yml` with at least one test each
2. Create `stg_products.yml` and `stg_order_items.yml` files with appropriate tests
3. Run `dbt test` and fix any failures
4. Verify the `relationships` test on `stg_orders.customer_id` works by running `dbt test --select stg_orders`

---

## 2.8 Key Takeaways

| Concept | What You Learned |
|---------|-----------------|
| `sources.yml` | Declares and documents raw tables; can include source-level tests |
| `<model>.yml` | Documents and tests individual dbt models (1:1 pattern) |
| `not_null` | Ensures a column has no NULL values |
| `unique` | Ensures a column has no duplicate values |
| `accepted_values` | Ensures column values belong to a defined set |
| `relationships` | Ensures referential integrity between models |
| `dbt test` | Runs all declared tests and reports pass/fail |

---

## Further Reading

- [Add data tests to your DAG](https://docs.getdbt.com/docs/build/data-tests) - Complete guide to dbt testing
- [Test configurations](https://docs.getdbt.com/reference/test-configs) - All test configuration options
- [Sources](https://docs.getdbt.com/docs/build/sources) - Source properties and configurations
- [Model properties](https://docs.getdbt.com/reference/model-properties) - All available model YAML properties

---

**Previous:** [Lesson 1 - Project Setup](01_project_setup.md) | **Next:** [Lesson 3 - The Staging Layer](03_staging_layer.md)
