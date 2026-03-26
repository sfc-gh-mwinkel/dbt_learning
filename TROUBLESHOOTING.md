# dbt Learning Platform Troubleshooting Guide

## Common Errors & Solutions

This guide covers the most common issues students encounter and how to fix them.

---

## Connection & Setup Issues

### Error: `dbt debug` fails with "Could not find profile named 'dbt_learning'"

**Cause**: `profiles.yml` not found or incorrectly configured

**Solution**:
```bash
# Check if profiles.yml exists
ls -la ~/.dbt/profiles.yml

# If missing, copy the example
cp profiles.yml.example ~/.dbt/profiles.yml

# Edit with your credentials
vi ~/.dbt/profiles.yml
```

**Verify**: The `profile:` name in `dbt_project.yml` must match the profile name in `~/.dbt/profiles.yml`.

---

### Error: "Connection refused" or "Cannot connect to Snowflake"

**Cause**: Incorrect Snowflake credentials or SSO not configured

**Solutions**:

1. **Check account identifier format**:
   ```yaml
   # Correct formats:
   account: abc12345.us-east-1
   account: abc12345.us-west-2.aws
   account: abc12345.east-us-2.azure
   
   # NOT:
   account: https://abc12345.us-east-1.snowflakecomputing.com
   ```

2. **Verify authenticator**:
   ```yaml
   # For SSO/Okta:
   authenticator: externalbrowser
   
   # For username/password:
   authenticator: snowflake
   ```

3. **Test connection**:
   ```bash
   dbt debug
   ```

---

## Model Errors

### Error: "Compilation Error: Model 'stg_customers' depends on a node named 'source.raw.customers' which was not found"

**Cause**: Missing or incorrectly named source in `sources.yml`

**Solution**:

1. Verify `sources.yml` exists:
   ```bash
   ls models/staging/sources.yml
   ```

2. Check source configuration:
   ```yaml
   version: 2
   
   sources:
     - name: raw  # Must match source() first argument
       schema: "{{ target.schema }}_raw"
       tables:
         - name: customers  # Must match source() second argument
   ```

3. Verify seeds were loaded:
   ```bash
   dbt seed
   ```

---

### Error: "Compilation Error: Model 'dim_customers' depends on a node named 'int_customers__order_summary' which was not found"

**Cause**: Referenced model doesn't exist yet

**Solution**:

1. Check which models are missing:
   ```bash
   python run.py check 4
   # Or: ./scripts/check_lesson_prerequisites.sh 4
   ```

2. Either:
   - **Option A**: Create the missing model (follow lesson instructions)
   - **Option B**: Copy from assets (catch up):
     ```bash
     cp assets/models/intermediate/int_customers__order_summary.sql models/intermediate/
     ```
   - **Option C**: Use catch-up script:
     ```bash
     python run.py catchup 4
     # Or: ./scripts/catch_up.sh 4
     ```

---

### Error: "Database Error: SQL compilation error: Object 'STG_CUSTOMERS' does not exist"

**Cause**: Model compiled but wasn't run

**Solution**:
```bash
# Build all upstream dependencies
dbt run --select +dim_customers

# Or build everything
dbt run
```

**Prevention**: Use `dbt build` instead of `dbt run` to build and test in dependency order.

---

## Jinja & Syntax Errors

### Error: "Compilation Error: unexpected 'end of template'"

**Cause**: Missing `{% endif %}`, `{% endfor %}`, or `{% endmacro %}`

**Solution**:

1. Count your Jinja blocks:
   ```sql
   {% if ... %}     -- Opens block
   {% endif %}      -- Must close
   
   {% for ... %}    -- Opens block
   {% endfor %}     -- Must close
   ```

2. Check macro syntax:
   ```sql
   {% macro clean_string(column_name) %}
       trim(lower({{ column_name }}))
   {% endmacro %}  -- Required!
   ```

---

### Error: "Compilation Error: 'loop' is undefined"

**Cause**: Using `loop.last` outside a `{% for %}` block

**Solution**: Only use `loop.last` inside for loops:
```sql
{% for status in ['pending', 'shipped', 'completed'] %}
    sum(case when status = '{{ status }}' then 1 else 0 end) as {{ status }}_count
    {% if not loop.last %},{% endif %}  -- Only here!
{% endfor %}
```

---

## Test Failures

### Error: "FAIL 1 unique_dim_customers_customer_id"

**Cause**: Duplicate customer_id values in dim_customers

**Solution**:

1. Store failures for analysis:
   ```bash
   dbt test --select dim_customers --store-failures
   ```

2. Query the failure table:
   ```sql
   select * from dbt_test_failures.unique_dim_customers_customer_id;
   ```

3. Find the root cause:
   ```sql
   -- Check for duplicates in source
   select customer_id, count(*)
   from {{ source('raw', 'customers') }}
   group by customer_id
   having count(*) > 1;
   ```

4. Fix:
   - Clean source data, OR
   - Add deduplication logic in staging model:
     ```sql
     select * from {{ source('raw', 'customers') }}
     qualify row_number() over (partition by customer_id order by created_at desc) = 1
     ```

---

### Error: "FAIL 3 relationships_fct_orders_customer_id__customer_id__ref_dim_customers_"

**Cause**: Orphaned records - `customer_id` values in `fct_orders` that don't exist in `dim_customers`

**Solution**:

1. Find orphaned records:
   ```bash
   dbt test --select fct_orders --store-failures
   ```

2. Query failures:
   ```sql
   select * from dbt_test_failures.relationships_fct_orders_customer_id__customer_id__ref_dim_customers_;
   ```

3. Options:
   - **Option A**: Fix source data (add missing customers)
   - **Option B**: Use ghost keys (recommended):
     ```sql
     select
         o.order_id,
         coalesce(c.customer_id, -1) as customer_id,  -- -1 for unknown
         ...
     from orders o
     left join customers c on o.customer_id = c.customer_id
     ```

---

## Seed Issues

### Error: "Database Error: Duplicate column name in CSV: 'CUSTOMER_ID'"

**Cause**: CSV headers are being treated as case-insensitive by Snowflake

**Solution**: Check your CSV file for duplicate column names (case-insensitive):
```bash
head -1 seeds/customers.csv
# Should show: customer_id,first_name,last_name
# NOT: customer_id,Customer_ID,first_name
```

---

### Error: "Cannot create seed table because it already exists"

**Cause**: Seed table exists from previous run

**Solution**:
```bash
# Option 1: Full refresh (drops and recreates)
dbt seed --full-refresh

# Option 2: Manually drop
# In Snowflake: DROP TABLE customers;
dbt seed
```

---

## Package Issues

### Error: "Macro 'dbt_utils.star' not found"

**Cause**: `dbt_utils` package not installed

**Solution**:
```bash
# Install packages
dbt deps

# Verify packages installed
ls dbt_packages/
# Should show: dbt_utils/
```

**Prevention**: Always run `dbt deps` after cloning repo or adding packages to `packages.yml`.

---

### Error: "Package 'dbt_constraints' not found"

**Cause**: Package not in `packages.yml`

**Solution**:

1. Add to `packages.yml`:
   ```yaml
   packages:
     - package: Snowflake-Labs/dbt_constraints
       version: [">=0.8.0", "<1.0.0"]
   ```

2. Install:
   ```bash
   dbt deps
   ```

---

## Incremental Model Issues

### Error: "Incremental model runs but processes all rows every time"

**Cause**: Missing `{% if is_incremental() %}` filter

**Solution**:
```sql
{{ config(materialized='incremental', unique_key='order_id') }}

select * from {{ ref('stg_orders') }}

{% if is_incremental() %}
    where order_date > (select max(order_date) from {{ this }})
{% endif %}
```

---

### Error: "Object 'THIS' does not exist"

**Cause**: Using `{{ this }}` when table doesn't exist yet (first run)

**Solution**: Always wrap in `{% if is_incremental() %}`:
```sql
{% if is_incremental() %}
    -- Only runs when table exists
    where order_date > (select max(order_date) from {{ this }})
{% endif %}
```

---

## Schema Issues

### Error: Models created in wrong schema (e.g., `PUBLIC_STAGING` instead of `STAGING`)

**Cause**: Default dbt behavior concatenates target schema + custom schema

**Solution**:

1. Copy the override macro:
   ```bash
   cp assets/macros/generate_schema_name.sql macros/
   ```

2. Rebuild models:
   ```bash
   dbt run --full-refresh
   ```

3. Verify:
   ```sql
   show schemas like '%STAGING%';
   -- Should show: STAGING
   -- NOT: PUBLIC_STAGING
   ```

---

## Snapshot Issues

### Error: "Snapshot table not found"

**Cause**: Snapshots haven't been run yet

**Solution**:
```bash
# Run snapshots (separate from dbt run)
dbt snapshot
```

**Remember**: Snapshots use `dbt snapshot`, not `dbt run`.

---

### Error: "Snapshot doesn't capture changes"

**Cause**: Source data hasn't changed, or `updated_at` column not updating

**Solution**:

1. Verify source data changed:
   ```sql
   select * from {{ source('raw', 'orders') }} where order_id = 1009;
   ```

2. For timestamp strategy, ensure `updated_at` updates:
   ```yaml
   strategy: timestamp
   updated_at: updated_at  # This column must change!
   ```

3. Try check strategy instead:
   ```yaml
   strategy: check
   check_cols: ['status', 'amount']
   ```

---

## Documentation Issues

### Error: `dbt docs serve` - "Address already in use"

**Cause**: Port 8080 is already occupied

**Solution**:
```bash
# Use different port
dbt docs serve --port 8001

# Or kill existing process
lsof -ti:8080 | xargs kill -9
```

---

## Getting Help

If you're still stuck after trying these solutions:

1. **Check dbt logs**:
   ```bash
   cat logs/dbt.log | grep ERROR
   tail -100 logs/dbt.log
   ```

2. **Verify prerequisites**:
   ```bash
   python run.py check <lesson_number>
   # Or: ./scripts/check_lesson_prerequisites.sh <lesson_number>
   ```

3. **Catch up to current lesson**:
   ```bash
   python run.py catchup <lesson_number>
   # Or: ./scripts/catch_up.sh <lesson_number>
   ```

4. **Check compiled SQL**:
   ```bash
   dbt compile --select model_name
   cat target/compiled/dbt_learning/models/path/to/model.sql
   ```

5. **Run with debug logging**:
   ```bash
   dbt run --select model_name --debug
   ```

---

## Prevention Tips

1. **Always run checkpoint before lessons**:
   ```bash
   python run.py check 4
   # Or: ./scripts/check_lesson_prerequisites.sh 4
   ```

2. **Use `dbt build` instead of separate run + test**:
   ```bash
   dbt build  # Not: dbt run && dbt test
   ```

3. **Install packages immediately**:
   ```bash
   dbt deps  # After cloning or adding packages
   ```

4. **Test incrementally**:
   ```bash
   dbt build --select +model_name  # Build with dependencies
   ```

5. **Read error messages carefully** - they usually tell you exactly what's wrong!

---

**Tip**: Most errors fall into one of three categories:
1. **Missing files** → Use catch-up script
2. **Wrong configuration** → Check examples in `/assets/`
3. **Data issues** → Use `--store-failures` to investigate

Happy debugging! 🔧
