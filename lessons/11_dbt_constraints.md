# Lesson 11: Enterprise Data Quality with dbt_constraints

## Learning Objectives

By the end of this lesson you will be able to:
- Understand database-level constraint enforcement vs. dbt tests
- Install and configure the `dbt_constraints` package
- Implement primary key and foreign key constraints
- Enforce unique constraints on business keys
- Understand when to use dbt_constraints vs. standard tests

---

## Prerequisites

- **Completed:** Lessons 1-10
- **Models exist:** `dim_customers`, `fct_orders` in marts

**Catch up:** If you're missing prerequisites, run:
```bash
./scripts/catch_up.sh 11
```

---

## 11.1 Why dbt_constraints?

Standard dbt tests (`not_null`, `unique`, `relationships`) only validate data **during `dbt test` runs**. They don't prevent bad data from entering through other channels (manual inserts, other ETL tools, etc.).

**dbt_constraints** creates actual database constraints in Snowflake AND validates data during tests:

| Feature | Standard dbt Tests | dbt_constraints |
|---------|-------------------|-----------------|
| Validation timing | Only during `dbt test` | During `dbt test` (validates data) |
| Constraint metadata | Not created | Created in Snowflake |
| Query optimization | No | Yes (optimizer uses constraints) |
| BI tool visibility | Not visible | Visible in metadata |
| Snowflake enforcement | N/A | Not enforced at write (metadata only) |
| Documentation | In dbt only | In database + dbt |

> **Key concept**: Database constraints document data relationships in metadata and can help query optimizers. In Snowflake specifically, constraints are **not enforced by default** at write time — they serve as metadata documentation. However, the `dbt_constraints` package validates data during `dbt test` runs AND creates the constraint metadata, giving you the best of both worlds.

---

## 11.2 Installation

Add to your `packages.yml`:

```yaml
packages:
  - package: dbt-labs/dbt_utils
    version: [">=1.0.0", "<2.0.0"]
    
  - package: Snowflake-Labs/dbt_constraints
    version: [">=0.8.0", "<1.0.0"]
```

Install:

```bash
dbt deps
```

**Official Package**: [Snowflake-Labs/dbt_constraints](https://github.com/Snowflake-Labs/dbt_constraints)

---

## 11.3 Primary Key Constraints

Every dimension table must have a primary key. This guarantees uniqueness and enables foreign key relationships.

### Simple Primary Key

Update `models/marts/dim_customers.yml`:

```yaml
version: 2

models:
  - name: dim_customers
    description: "Customer dimension with lifetime value and tier classification"
    columns:
      - name: customer_id
        description: "Primary key for customers"
        tests:
          - dbt_constraints.primary_key
          
      - name: customer_tier
        description: "Customer value tier based on lifetime spend"
        tests:
          - accepted_values:
              values: ['gold', 'silver', 'bronze']
```

Run:

```bash
dbt run --select dim_customers
dbt test --select dim_customers
```

**What happens**: dbt_constraints creates a `PRIMARY KEY` constraint in Snowflake on the `customer_id` column.

### Composite Primary Key

For tables where the primary key spans multiple columns:

```yaml
models:
  - name: fct_order_lines
    description: "Order line items fact table"
    tests:
      - dbt_constraints.primary_key:
          column_names:
            - order_id
            - line_number
```

> **Note**: Since our lessons don't include an `fct_order_lines` model, this is shown as an example pattern.

---

## 11.4 Foreign Key Constraints

Foreign keys ensure referential integrity between tables. Every value in a foreign key column must exist in the referenced table's primary key.

### Simple Foreign Key

Update `models/marts/fct_orders.yml`:

```yaml
version: 2

models:
  - name: fct_orders
    description: "Order fact table with payment and line item details"
    columns:
      - name: order_id
        description: "Primary key"
        tests:
          - dbt_constraints.primary_key
          
      - name: customer_id
        description: "Foreign key to dim_customers"
        tests:
          - dbt_constraints.foreign_key:
              pk_table_name: ref('dim_customers')
              pk_column_name: customer_id
```

Run:

```bash
dbt run --select dim_customers fct_orders
dbt test --select fct_orders
```

**What this does**:
1. Creates a `FOREIGN KEY` constraint on `fct_orders.customer_id`
2. References `dim_customers.customer_id`
3. Database prevents inserting invalid customer_id values

### Why This Matters

Without foreign key constraints:
```sql
-- This would succeed (bad!)
insert into fct_orders (order_id, customer_id, order_amount)
values (99999, 'INVALID_ID', 100.00);
```

With foreign key constraints:
```sql
-- This fails with constraint violation (good!)
-- Error: Foreign key constraint violated
```

---

## 11.5 Unique Constraints

Use unique constraints for business keys that aren't primary keys but must be unique (e.g., email addresses, order numbers).

```yaml
columns:
  - name: email
    description: "Customer email address (unique business key)"
    tests:
      - dbt_constraints.unique_key
```

---

## 11.6 Complete Example: Enterprise-Grade Marts

Here's how your mart `.yml` files should look with full constraint enforcement:

**`models/marts/dim_customers.yml`**:
```yaml
version: 2

models:
  - name: dim_customers
    description: "Customer dimension with lifetime value and tier classification"
    columns:
      - name: customer_id
        description: "Primary key for customers"
        tests:
          - dbt_constraints.primary_key
          
      - name: email
        description: "Customer email address"
        tests:
          - not_null
          - dbt_constraints.unique_key
          
      - name: customer_tier
        description: "Customer value tier based on lifetime spend"
        tests:
          - accepted_values:
              values: ['gold', 'silver', 'bronze']
              
      - name: lifetime_value
        description: "Total amount spent by customer"
        tests:
          - not_null
```

**`models/marts/fct_orders.yml`**:
```yaml
version: 2

models:
  - name: fct_orders
    description: "Order fact table with payment and line item details"
    columns:
      - name: order_id
        description: "Primary key"
        tests:
          - dbt_constraints.primary_key
          
      - name: customer_id
        description: "Foreign key to dim_customers"
        tests:
          - not_null
          - dbt_constraints.foreign_key:
              pk_table_name: ref('dim_customers')
              pk_column_name: customer_id
              
      - name: order_amount
        description: "Total order amount"
        tests:
          - not_null
          
      - name: order_date
        description: "Date order was placed"
        tests:
          - not_null
```

---

## 11.7 Verification

After running tests, verify constraints were created in Snowflake:

```sql
-- Check constraints on dim_customers
show primary keys in table dim_customers;

-- Check constraints on fct_orders
show primary keys in table fct_orders;
show foreign keys in table fct_orders;

-- Or use information schema
select
    table_name,
    constraint_name,
    constraint_type
from information_schema.table_constraints
where table_schema = current_schema()
  and table_name in ('DIM_CUSTOMERS', 'FCT_ORDERS')
order by table_name, constraint_type;
```

**Expected output**:
```
TABLE_NAME      | CONSTRAINT_NAME           | CONSTRAINT_TYPE
----------------+---------------------------+----------------
DIM_CUSTOMERS   | dim_customers_pk          | PRIMARY KEY
FCT_ORDERS      | fct_orders_pk             | PRIMARY KEY
FCT_ORDERS      | fct_orders_customer_fk    | FOREIGN KEY
```

---

## 11.8 When to Use dbt_constraints

| Use Case | Use dbt_constraints? | Why |
|----------|---------------------|-----|
| Production marts | ✅ Yes | 24/7 enforcement, query optimization |
| Development models | ❌ No | Standard tests are faster for iteration |
| Staging models | ❌ No | Source validation only, not business entities |
| Intermediate models | ⚠️ Maybe | If reused by multiple downstream models |
| Ad-hoc analysis | ❌ No | Standard tests sufficient |

**Rule of thumb**: Use `dbt_constraints` for:
- All gold layer dimensions
- All gold layer facts
- Production-critical intermediate models

---

## 11.9 Performance Considerations

**Benefits**:
- Query optimizer uses constraints for better execution plans
- Join elimination when referencing unique keys
- BI tools can discover relationships from metadata
- Documentation visible in Snowflake UI and information_schema

**Important Snowflake Behavior**:
- Snowflake constraints are **NOT enforced** at write time by default
- They serve as **metadata documentation** for query optimization and BI tools
- The `dbt_constraints` package validates data during `dbt test`, ensuring data integrity
- This gives you: validation at dbt runtime + metadata benefits in Snowflake

---

## 11.10 Exercises

1. **Add dbt_constraints package**:
   ```bash
   # Already done if you followed instructions above
   dbt deps
   ```

2. **Add primary key constraint to dim_customers**:
   - Update `models/marts/dim_customers.yml`
   - Add `dbt_constraints.primary_key` test to `customer_id`

3. **Add foreign key constraint to fct_orders**:
   - Update `models/marts/fct_orders.yml`
   - Add `dbt_constraints.foreign_key` test to `customer_id`
   - Reference `dim_customers.customer_id`

4. **Run and verify**:
   ```bash
   dbt run --select dim_customers fct_orders
   dbt test --select fct_orders
   ```

5. **Test constraint enforcement**:
   ```sql
   -- In Snowflake, try inserting invalid data
   insert into fct_orders (order_id, customer_id, order_date, order_amount)
   values (99999, 'FAKE_ID', current_date(), 100.00);
   -- This should fail with foreign key violation
   ```

6. **Verify constraints exist**:
   ```sql
   show primary keys in table dim_customers;
   show foreign keys in table fct_orders;
   ```

---

## 11.11 Troubleshooting

### Constraint Creation Fails

**Error**: `Foreign key constraint cannot be created`

**Cause**: Existing data violates constraint (orphaned records)

**Solution**:
```bash
# Find orphaned records
dbt test --select fct_orders --store-failures

# Query failure table
select * from dbt_test_failures.relationships_fct_orders_customer_id__customer_id__ref_dim_customers_;

# Fix data or update model to exclude bad records
```

### Constraint Already Exists

**Error**: `Constraint already exists`

**Solution**: dbt_constraints is idempotent; run `dbt test` again or manually drop constraint:
```sql
alter table fct_orders drop constraint fct_orders_customer_fk;
```

---

## 11.12 Key Takeaways

| Concept | What You Learned |
|---------|------------------|
| dbt_constraints | Creates database-level constraint metadata + validates during dbt test |
| Primary keys | Guarantee uniqueness, enable foreign key relationships |
| Foreign keys | Enforce referential integrity between tables |
| Unique constraints | Business keys that must be unique |
| When to use | Production marts, gold layer models |
| Verification | Use `SHOW` commands to verify constraints |
| Performance | Query optimizer benefits, BI tool discovery |

---

## Further Reading

- [dbt_constraints package](https://hub.getdbt.com/Snowflake-Labs/dbt_constraints/latest/) - Official package documentation
- [Snowflake constraints](https://docs.snowflake.com/en/sql-reference/constraints-overview) - How constraints work in Snowflake
- [Primary keys in dbt](https://docs.getdbt.com/terms/primary-key) - Understanding primary keys
- [dbt packages](https://docs.getdbt.com/docs/build/packages) - Installing and using packages

---

**Congratulations!** You now understand how to implement enterprise-grade data quality with database-enforced constraints. This is essential for production data platforms where data integrity must be guaranteed across all access patterns.

---

**Previous:** [Lesson 10 - Graph Operators & dbt build](10_graph_operators.md) | **Back to:** [README](../README.md)
