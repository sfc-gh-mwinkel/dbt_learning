# Lesson 5: Testing & Data Quality

## Learning Objectives

By the end of this lesson you will be able to:
- Apply all four built-in generic tests
- Write custom singular tests
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

Apply these to your marts. Create `models/marts/schema.yml`:

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

## 5.4 Test Severity

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

## 5.5 Using dbt_utils

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

## 5.6 Building a Testing Strategy

| Layer | What to Test |
|-------|-------------|
| **Sources** | `not_null` and `unique` on primary keys |
| **Staging** | Primary keys (`not_null`, `unique`), foreign keys (`relationships`), value domains (`accepted_values`) |
| **Intermediate** | Referential integrity, computed column logic |
| **Marts** | Primary keys, foreign keys, business rules (singular tests), value ranges |

A good rule of thumb: every model should have at least `not_null` + `unique` on its primary key.

---

## 5.7 Running Tests

```bash
dbt test                          # Run all tests
dbt test --select staging         # Tests for staging models only
dbt test --select dim_customers   # Tests for one model
dbt test --select source:raw      # Tests on sources
dbt test --select tag:marts       # Tests on tagged models
```

---

## 5.8 Exercises

1. Install `dbt_utils` with `dbt deps`
2. Add `accepted_range` tests on `fct_orders.order_amount` (min: 0) and `fct_orders.total_line_items` (min: 0)
3. Write a singular test in `tests/` that checks for customers in `dim_customers` with negative `lifetime_value`
4. Add `warn` severity to a test and observe the output
5. Run `dbt test` and ensure everything passes

---

## 5.9 Key Takeaways

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
