# Lesson 5: Testing & Data Quality

## Set Up for This Lesson

**Prerequisites:** Complete Lesson 4 (you should have all staging, intermediate, and mart models built).

**Starting state:**
- All models from Lesson 4 are built (`dbt run` completed successfully)
- You have `dim_customers` and `fct_orders` tables in your marts schema
- Seeds are loaded with **intentionally broken data** (orders.csv has incorrect amounts)

If you're starting fresh or need to reset:

```bash
# Copy the BROKEN orders seed (this is intentional for teaching!)
cp assets/seeds/orders_broken.csv seeds/orders.csv

# Reload seeds and rebuild models
dbt seed
dbt run
```

---

## Learning Objectives

By the end of this lesson you will be able to:
- Apply all four built-in generic tests
- Write custom singular tests
- **Debug failing tests and fix underlying data issues**
- Use the `dbt_utils` package for advanced tests
- Understand test severity levels
- Build a testing strategy across your project

---

## 5.1 Why Test?

Tests catch problems _before_ they reach your dashboards:
- A source system sends duplicate records
- A join produces unexpected NULLs
- An upstream table changes its schema
- Business logic produces impossible values

dbt tests are SQL queries that return rows when something is **wrong**. Zero rows = pass. Any rows = fail.

---

## 5.2 Generic Tests (Review)

You learned these in Lesson 2. Here's the complete reference:

```yaml
version: 2

models:
  - name: dim_customers
    columns:
      - name: customer_id
        tests:
          - not_null          # No NULLs
          - unique            # No duplicates
          - relationships:    # Referential integrity
              to: ref('stg_customers')
              field: customer_id

      - name: customer_tier
        tests:
          - accepted_values:  # Only these values allowed
              values: ['gold', 'silver', 'bronze']
```

Apply these to your marts. Create `models/marts/dim_customers.yml`:

```yaml
version: 2

models:
  - name: dim_customers
    description: "Customer dimension with lifetime value and tier classification"
    columns:
      - name: customer_id
        description: "Primary key"
        tests:
          - not_null
          - unique
      - name: customer_tier
        description: "Customer value tier based on lifetime spend"
        tests:
          - accepted_values:
              values: ['gold', 'silver', 'bronze']
```

Create `models/marts/fct_orders.yml`:

```yaml
version: 2

models:
  - name: fct_orders
    description: "Order fact table with payment and line item details"
    columns:
      - name: order_id
        description: "Primary key"
        tests:
          - not_null
          - unique
      - name: customer_id
        description: "Foreign key to dim_customers"
        tests:
          - relationships:
              to: ref('dim_customers')
              field: customer_id
```

---

## 5.3 Singular Tests (Custom SQL)

For business-specific validations, write custom SQL in the `tests/` directory. A singular test is any SQL query that returns rows representing failures.

Create `tests/assert_order_amount_matches_line_items.sql`:

```sql
-- Singular test: any SQL file in the tests/ directory that returns rows on failure.
-- dbt runs this query; if it returns 0 rows, the test passes.
-- If it returns any rows, those rows represent data quality violations.
--
-- This test checks: does each order's amount match the sum of its line items?
-- A mismatch could indicate missing line items, double-counted payments,
-- or rounding errors in upstream transformations.
select
    o.order_id,
    o.order_amount,
    oi.line_items_total,
    abs(o.order_amount - oi.line_items_total) as difference
from {{ ref('fct_orders') }} o
inner join (
    select
        order_id,
        sum(line_total) as line_items_total
    from {{ ref('int_order_items_with_products') }}
    group by order_id
) oi on o.order_id = oi.order_id
-- The 0.01 tolerance accounts for floating-point rounding.
-- Without a tolerance, tests would fail on penny-level precision differences.
where abs(o.order_amount - oi.line_items_total) > 0.01
```

**What this tests:** For every order that has line items, the order amount should roughly match the sum of line item totals. Any row returned means there's a discrepancy greater than $0.01.

Run it:

```bash
dbt test --select assert_order_amount_matches_line_items
```

> **Key concept:** Singular tests are just SQL files in the `tests/` folder. They return failing rows. If the query returns 0 rows, the test passes.

---

## 5.4 Working with Failing Tests (Hands-On Exercise)

In this section, you'll experience the full workflow of identifying, debugging, and fixing a data quality issue. This mirrors real-world scenarios where tests catch problems before they reach production.

### Step 1: Run the Test (It Should Fail!)

First, run your custom test:

```bash
dbt test --select assert_order_amount_matches_line_items
```

**Expected output:**
```
Failed [X.XXs] test assert_order_amount_matches_line_items

Finished running 1 test:
  FAILED: 1
```

✅ **Good news:** The test is working correctly! It detected data quality issues in your `orders` seed data.

### Step 2: Investigate What's Failing

When a test fails, you need to understand _what_ data is causing the failure. The test SQL already returns the failing rows, so you can query it directly in Snowflake.

**Option A: Query the test directly in Snowflake**

The test creates a view in your `<user>_DBT_TEST__AUDIT` schema. Query it:

```sql
-- Replace MWINKEL with your user prefix
SELECT *
FROM DBT_LEARNING.MWINKEL_DBT_TEST__AUDIT.ASSERT_ORDER_AMOUNT_MATCHES_LINE_ITEMS
ORDER BY difference DESC
LIMIT 5;
```

**Option B: Run the test SQL manually**

Copy the SQL from `tests/assert_order_amount_matches_line_items.sql` and run it in Snowflake, replacing the `{{ ref() }}` macros:

```sql
-- Example for user MWINKEL - adjust schema names for your user prefix
SELECT
    o.order_id,
    o.order_amount,
    oi.line_items_total,
    ABS(o.order_amount - oi.line_items_total) as difference,
    ROUND(ABS(o.order_amount - oi.line_items_total) / o.order_amount * 100, 2) as pct_diff
FROM DBT_LEARNING.MWINKEL_MARTS.fct_orders o
INNER JOIN (
    SELECT order_id, SUM(line_total) as line_items_total
    FROM DBT_LEARNING.MWINKEL_INTERMEDIATE.int_order_items_with_products
    GROUP BY order_id
) oi ON o.order_id = oi.order_id
WHERE ABS(o.order_amount - oi.line_items_total) > 0.01
ORDER BY difference DESC;
```

**What you'll see:**

| ORDER_ID | ORDER_AMOUNT | LINE_ITEMS_TOTAL | DIFFERENCE | PCT_DIFF |
|----------|--------------|------------------|------------|----------|
| 1005     | 300.00       | 224.95           | 75.05      | 25.02    |
| 1011     | 410.00       | 399.88           | 10.12      | 2.47     |
| 1013     | 220.00       | 209.97           | 10.03      | 4.56     |
| 1008     | 90.00        | 79.98            | 10.02      | 11.13    |
| 1004     | 55.75        | 46.50            | 9.25       | 16.59    |

**Analysis:** Order 1005 is off by 25%! That's significant. The others have smaller discrepancies but still exceed our 1-cent tolerance.

### Step 3: Find the Root Cause

The line items are the source of truth (they're the actual products purchased). Let's get the _correct_ amounts:

```sql
-- Get what the order amounts SHOULD be
SELECT
    order_id,
    SUM(line_total) as correct_amount,
    COUNT(*) as item_count
FROM DBT_LEARNING.MWINKEL_INTERMEDIATE.int_order_items_with_products
GROUP BY order_id
ORDER BY order_id;
```

**Result:** You now have a list of the correct order amounts based on actual line items.

### Step 4: Fix the Source Data

The issue is in `seeds/orders.csv`. The amounts don't match the line items. Fix it:

```bash
# Copy the FIXED version (answer key)
cp assets/seeds/orders_fixed.csv seeds/orders.csv
```

**What changed?** Compare the files to see:

```bash
diff assets/seeds/orders_broken.csv assets/seeds/orders_fixed.csv
```

You'll see 12 orders with corrected amounts:
- Order 1002: 85.00 → 80.99
- Order 1003: 200.00 → 195.00
- Order 1005: 300.00 → 224.95
- And 9 more...

### Step 5: Reload and Rebuild

Now that the seed file is fixed, reload it and rebuild your models:

```bash
# Reload the corrected orders seed
dbt seed --select orders

# Rebuild all downstream models (they depend on the seed)
dbt run
```

### Step 6: Verify the Test Passes

Run the test again:

```bash
dbt test --select assert_order_amount_matches_line_items
```

**Expected output:**
```
Passed [X.XXs] test assert_order_amount_matches_line_items

Finished running 1 test:
  PASSED: 1
```

✅ **Success!** The test now passes. The order amounts match the line item totals.

### Step 7: Run All Tests

Verify everything still works:

```bash
dbt test
```

All tests should pass. If any fail, review the error messages and use the same debugging process:
1. Identify what's failing
2. Investigate the data
3. Find the root cause
4. Fix the source
5. Rebuild and verify

---

## 5.5 Key Insights from This Exercise

**What you learned:**

| Concept | Insight |
|---------|--------|
| **Tests as guardrails** | Tests catch problems _before_ they reach dashboards or reports |
| **Failing tests are good** | A failing test means your quality checks are working! |
| **Investigate, don't guess** | Query the test results to understand what's wrong |
| **Fix upstream sources** | The seed file was the root cause; fixing it fixed everything downstream |
| **Rebuild the pipeline** | After fixing source data, always rebuild dependent models |
| **Verify the fix** | Re-run tests to confirm the issue is resolved |

> **Real-world parallel:** In production, you'd fix the issue in your source system (database, API, ETL job) rather than a CSV file. But the debugging workflow is identical: test fails → investigate → fix source → rebuild → verify.

---

## 5.6 Test Severity

By default, a failing test causes `dbt test` to exit with an error. You can soften this:

```yaml
columns:
  - name: email
    tests:
      - not_null:
          severity: warn    # Log a warning instead of failing
```

Severity options:
| Level | Behavior |
|-------|----------|
| `error` (default) | Fails the test run |
| `warn` | Logs a warning; test run still succeeds |

You can also set thresholds:

```yaml
- not_null:
    config:
      error_if: ">100"    # Fail if more than 100 nulls
      warn_if: ">10"      # Warn if more than 10 nulls
```

---

## 5.7 Using dbt_utils

The `dbt_utils` package provides additional test types. It's already in `packages.yml`:

```yaml
packages:
  - package: dbt-labs/dbt_utils
    version: [">=1.0.0", "<2.0.0"]
```

> **Important**: If you haven't already installed packages, run this now:

```bash
dbt deps
```

This command downloads and installs the `dbt_utils` package (and any other packages in `packages.yml`).

Now you can use tests like:

```yaml
models:
  - name: fct_orders
    tests:
      - dbt_utils.recency:
          datepart: day
          field: order_date
          interval: 365

    columns:
      - name: order_id
        tests:
          - dbt_utils.not_constant
      - name: order_amount
        tests:
          - dbt_utils.accepted_range:
              min_value: 0
              inclusive: true
```

Common `dbt_utils` tests:

| Test | What It Checks |
|------|---------------|
| `recency` | Most recent record is within a time window |
| `not_constant` | Column has more than one distinct value |
| `accepted_range` | Values fall within min/max bounds |
| `expression_is_true` | A SQL expression evaluates to true for all rows |
| `unique_combination_of_columns` | Composite uniqueness |

---

## 5.8 Building a Testing Strategy

| Layer | What to Test |
|-------|-------------|
| **Sources** | `not_null` and `unique` on primary keys |
| **Staging** | Primary keys (`not_null`, `unique`), foreign keys (`relationships`), value domains (`accepted_values`) |
| **Intermediate** | Referential integrity, computed column logic |
| **Marts** | Primary keys, foreign keys, business rules (singular tests), value ranges |

A good rule of thumb: every model should have at least `not_null` + `unique` on its primary key.

---

## 5.9 Running Tests

```bash
dbt test                          # Run all tests
dbt test --select staging         # Tests for staging models only
dbt test --select dim_customers   # Tests for one model
dbt test --select source:raw      # Tests on sources
dbt test --select tag:marts       # Tests on tagged models (tags covered in Lesson 6)
```

---

## 5.10 Exercises

1. Install `dbt_utils` with `dbt deps`
2. Add `accepted_range` tests on `fct_orders.order_amount` (min: 0) and `fct_orders.total_line_items` (min: 0)
3. Write a singular test in `tests/` that checks for customers in `dim_customers` with negative `lifetime_value`
4. Add `warn` severity to a test and observe the output
5. (Already completed!) You fixed the failing `assert_order_amount_matches_line_items` test

---

## 5.11 Key Takeaways

| Concept | What You Learned |
|---------|-----------------|
| Generic tests | `not_null`, `unique`, `accepted_values`, `relationships` in YAML |
| Singular tests | Custom SQL in `tests/` folder; return failing rows |
| `dbt_utils` | Package with advanced tests like `accepted_range`, `recency` |
| Severity | `error` (fail) vs `warn` (log only) |
| Test strategy | Every primary key tested; marts get business logic tests |
| `dbt test` | Runs tests; supports `--select` for targeting |

---

**Previous:** [Lesson 4 - Intermediate & Mart Models](04_intermediate_and_marts.md) | **Next:** [Lesson 6 - dbt_project.yml Deep Dive](06_dbt_project_yml.md)
