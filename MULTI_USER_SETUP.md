# Multi-User Production Setup Guide

## Overview

This dbt Learning Platform is configured for **multi-user production environments** where multiple students work simultaneously in the same Snowflake database (`SANDBOX_DBT_TRAINING`).

Each user gets their own isolated schemas to prevent conflicts, using the naming pattern:

```
<first_initial><last_name>_<schema_name>
```

---

## Quick Start

### 1. Configure Your Profile

Edit `~/.dbt/profiles.yml`:

```yaml
dbt_learning:
  target: dev
  outputs:
    dev:
      type: snowflake
      account: abc12345.us-east-1
      
      # IMPORTANT: Use your actual name
      user: john.doe@company.com  # ← Your email or username
      
      authenticator: externalbrowser
      role: YOUR_ROLE
      
      # SHARED DATABASE - all users use this
      database: SANDBOX_DBT_TRAINING
      
      warehouse: YOUR_WAREHOUSE
      schema: public
      threads: 4
```

### 2. Verify Your Schema Names

Run a test build:

```bash
dbt run --select stg_customers
```

Check what schemas were created:

```sql
-- In Snowflake
SHOW SCHEMAS LIKE 'JDOE_%' IN DATABASE SANDBOX_DBT_TRAINING;
```

**Expected output**:
```
JDOE_STAGING
JDOE_INTERMEDIATE
JDOE_MARTS
JDOE_PUBLIC
```

---

## How the Schema Naming Works

### Step-by-Step Example

**Given** `profiles.yml`:
```yaml
user: john.doe@company.com
database: SANDBOX_DBT_TRAINING
```

**And** `dbt_project.yml`:
```yaml
models:
  dbt_learning:
    staging:
      +schema: staging
```

**Result**:
1. Extract username: `john.doe@company.com`
2. Remove email domain: `john.doe`
3. Split on `.`: `["john", "doe"]`
4. Get first initial + last name: `j` + `doe` = `jdoe`
5. Convert to uppercase: `JDOE`
6. Combine with schema: `JDOE_STAGING`

**Full model path**: `SANDBOX_DBT_TRAINING.JDOE_STAGING.STG_CUSTOMERS`

---

## Supported Username Formats

The macro automatically handles multiple formats:

| Format | Example | Resulting Prefix |
|--------|---------|------------------|
| Email (Okta/SSO) | `john.doe@company.com` | `JDOE` |
| Snowflake username | `JOHN.DOE` | `JDOE` |
| Simple format | `john.doe` | `JDOE` |
| Underscore separator | `jane_smith` | `JSMITH` |
| No separator | `bobsmith` | `BOBSMITH` |

---

## Schema Layout by User

### John Doe (`john.doe@company.com`)
```
SANDBOX_DBT_TRAINING/
├── JDOE_STAGING/
│   ├── STG_CUSTOMERS
│   ├── STG_ORDERS
│   └── STG_PRODUCTS
├── JDOE_INTERMEDIATE/
│   ├── INT_ORDERS_WITH_PAYMENTS
│   └── INT_CUSTOMERS__ORDER_SUMMARY
└── JDOE_MARTS/
    ├── DIM_CUSTOMERS
    └── FCT_ORDERS
```

### Jane Smith (`jane.smith@company.com`)
```
SANDBOX_DBT_TRAINING/
├── JSMITH_STAGING/
│   ├── STG_CUSTOMERS
│   ├── STG_ORDERS
│   └── STG_PRODUCTS
├── JSMITH_INTERMEDIATE/
│   ├── INT_ORDERS_WITH_PAYMENTS
│   └── INT_CUSTOMERS__ORDER_SUMMARY
└── JSMITH_MARTS/
    ├── DIM_CUSTOMERS
    └── FCT_ORDERS
```

**Each user has complete isolation** - models never conflict.

---

## Benefits of This Approach

✅ **No Conflicts**: Multiple users can work simultaneously
✅ **Shared Database**: Everyone uses `SANDBOX_DBT_TRAINING`
✅ **Shared Seeds**: All users can load the same seed data
✅ **Clean Naming**: Easy to identify who owns which schemas
✅ **Easy Cleanup**: Drop all schemas for a user with `DROP SCHEMA JDOE_*`

---

## Verification Queries

### Check Your Schemas

```sql
-- Show all your schemas
SHOW SCHEMAS LIKE 'JDOE_%' IN DATABASE SANDBOX_DBT_TRAINING;
```

### Find All Your Models

```sql
-- List all tables/views in your schemas
SELECT 
  table_catalog as database,
  table_schema as schema,
  table_name,
  table_type
FROM SANDBOX_DBT_TRAINING.information_schema.tables
WHERE table_schema LIKE 'JDOE_%'
ORDER BY table_schema, table_name;
```

### Check Specific Model Location

```sql
-- Verify a staging model
SELECT * 
FROM SANDBOX_DBT_TRAINING.JDOE_STAGING.STG_CUSTOMERS
LIMIT 5;

-- Verify a mart model
SELECT * 
FROM SANDBOX_DBT_TRAINING.JDOE_MARTS.DIM_CUSTOMERS
LIMIT 5;
```

---

## Troubleshooting

### Issue: Schemas created with wrong prefix

**Example**: Schemas are `_STAGING` instead of `JDOE_STAGING`

**Cause**: Username parsing failed

**Solution**: Check your `profiles.yml` user field:

```yaml
# ✅ GOOD - will work
user: john.doe@company.com
user: john.doe
user: JOHN.DOE

# ❌ BAD - won't parse correctly
user: johndoe  # No separator between first/last
user: j.d      # Too short
```

**Fix**: Use format `first.last@domain.com` or `first.last`

---

### Issue: Schemas have multiple underscores

**Example**: `J_MIDDLE_DOE_STAGING`

**Cause**: Username has middle name or multiple parts

**Solution**: Use only first and last name:

```yaml
# Instead of: john.middle.doe@company.com
# Use: john.doe@company.com
```

---

### Issue: Can't see other users' schemas

**Cause**: This is expected and correct! You should only see your own schemas.

**Verification**: Each user should only have access to their own schemas:

```sql
-- You should see only your schemas
SHOW SCHEMAS IN DATABASE SANDBOX_DBT_TRAINING;

-- Expected: JDOE_STAGING, JDOE_MARTS, etc.
-- NOT: JSMITH_STAGING, BJOHNSON_MARTS, etc.
```

**Exception**: If you need to view another user's work (for teaching/review):

```sql
-- Requires appropriate grants
SELECT * FROM SANDBOX_DBT_TRAINING.JSMITH_STAGING.STG_CUSTOMERS;
```

---

## Administrator Setup

### Database Preparation

Administrators should create the shared database:

```sql
-- Create shared database
CREATE DATABASE IF NOT EXISTS SANDBOX_DBT_TRAINING;

-- Grant usage to training role
GRANT USAGE ON DATABASE SANDBOX_DBT_TRAINING TO ROLE TRAINING_ROLE;

-- Allow users to create their own schemas
GRANT CREATE SCHEMA ON DATABASE SANDBOX_DBT_TRAINING TO ROLE TRAINING_ROLE;
```

### User Permissions

Each user needs:

```sql
-- Grant warehouse access
GRANT USAGE ON WAREHOUSE TRAINING_WH TO ROLE TRAINING_ROLE;

-- Grant database access
GRANT USAGE ON DATABASE SANDBOX_DBT_TRAINING TO ROLE TRAINING_ROLE;
GRANT CREATE SCHEMA ON DATABASE SANDBOX_DBT_TRAINING TO ROLE TRAINING_ROLE;

-- Users will automatically own their created schemas
-- (owner of schema = creator of schema)
```

### Cleanup After Training

Remove all schemas for a specific user:

```sql
-- List schemas for user
SHOW SCHEMAS LIKE 'JDOE_%' IN DATABASE SANDBOX_DBT_TRAINING;

-- Drop schemas (run for each schema)
DROP SCHEMA IF EXISTS SANDBOX_DBT_TRAINING.JDOE_STAGING CASCADE;
DROP SCHEMA IF EXISTS SANDBOX_DBT_TRAINING.JDOE_INTERMEDIATE CASCADE;
DROP SCHEMA IF EXISTS SANDBOX_DBT_TRAINING.JDOE_MARTS CASCADE;
DROP SCHEMA IF EXISTS SANDBOX_DBT_TRAINING.JDOE_PUBLIC CASCADE;
```

Or with a stored procedure (requires ACCOUNTADMIN):

```sql
-- Cleanup stored procedure
CREATE OR REPLACE PROCEDURE cleanup_user_schemas(USER_PREFIX STRING)
RETURNS STRING
LANGUAGE JAVASCRIPT
EXECUTE AS CALLER
AS
$$
  var prefix = USER_PREFIX.toLowerCase();
  var db = 'SANDBOX_DBT_TRAINING';
  
  var schemas_query = `SHOW SCHEMAS LIKE '${prefix}_%' IN DATABASE ${db}`;
  var schemas = snowflake.execute({sqlText: schemas_query});
  
  var dropped = [];
  while (schemas.next()) {
    var schema_name = schemas.getColumnValue(2);  // name column
    var drop_query = `DROP SCHEMA IF EXISTS ${db}.${schema_name} CASCADE`;
    snowflake.execute({sqlText: drop_query});
    dropped.push(schema_name);
  }
  
  return 'Dropped schemas: ' + dropped.join(', ');
$$;

-- Usage
CALL cleanup_user_schemas('JDOE');
```

---

## FAQs

### Q: Can I change my schema prefix?

**A**: The prefix is automatically generated from your Snowflake username. To change it, you would need to:
1. Update your Snowflake username (not recommended)
2. Modify the `generate_schema_name` macro (advanced)

### Q: What if two users have the same first initial + last name?

**A**: Very rare, but if it happens (e.g., John Smith and Jane Smith both → `JSMITH`):
- Add middle initial to username: `john.m.smith@company.com`
- Or use a unique identifier: `john.smith1@company.com`

The macro will handle it correctly.

### Q: Can I work in a different database?

**A**: Yes, change the `database:` field in your `profiles.yml`:

```yaml
database: MY_PERSONAL_DATABASE
```

You'll have full control but won't share seed data with other users.

### Q: Do I need to create my schemas manually?

**A**: No! dbt automatically creates schemas when you run `dbt run`. The first time you build models, dbt will create `JDOE_STAGING`, `JDOE_MARTS`, etc. for you.

---

## Testing the Setup

### End-to-End Test

1. **Configure profile**:
   ```bash
   vi ~/.dbt/profiles.yml
   # Set user: john.doe@company.com
   # Set database: SANDBOX_DBT_TRAINING
   ```

2. **Load seeds**:
   ```bash
   cp assets/seeds/*.csv seeds/
   dbt seed
   ```

3. **Run staging models**:
   ```bash
   dbt run --select staging
   ```

4. **Verify in Snowflake**:
   ```sql
   SHOW SCHEMAS LIKE 'JDOE_%';
   SELECT * FROM SANDBOX_DBT_TRAINING.JDOE_STAGING.STG_CUSTOMERS LIMIT 5;
   ```

5. **Build everything**:
   ```bash
   dbt build
   ```

6. **Check final structure**:
   ```sql
   SELECT 
     table_schema,
     count(*) as table_count
   FROM SANDBOX_DBT_TRAINING.information_schema.tables
   WHERE table_schema LIKE 'JDOE_%'
   GROUP BY table_schema
   ORDER BY table_schema;
   ```

**Expected output**:
```
JDOE_INTERMEDIATE | 3
JDOE_MARTS        | 2
JDOE_STAGING      | 5
```

---

## Advanced: Understanding the Macro

For a detailed, step-by-step explanation of how the `generate_schema_name` macro works, see the extensive inline comments in:

```bash
cat macros/generate_schema_name.sql
```

The macro is heavily documented with:
- Purpose and benefits
- Naming pattern examples
- Step-by-step logic explanation
- Troubleshooting tips
- Verification queries

---

**Ready to start?** Follow the [Getting Started](README.md#getting-started) guide with your production-configured `profiles.yml`!
