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
      user: jon.snow@company.com  # ← Your email or username
      
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
SHOW SCHEMAS LIKE 'JSNOW_%' IN DATABASE SANDBOX_DBT_TRAINING;
```

**Expected output**:
```
JSNOW_STAGING
JSNOW_INTERMEDIATE
JSNOW_MARTS
JSNOW_PUBLIC
```

---

## How the Schema Naming Works

### Step-by-Step Example

**Given** `profiles.yml`:
```yaml
user: jon.snow@company.com
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
1. Extract username: `jon.snow@company.com`
2. Remove email domain: `jon.snow`
3. Split on `.`: `["jon", "snow"]`
4. Get first initial + last name: `j` + `snow` = `jsnow`
5. Convert to uppercase: `JSNOW`
6. Combine with schema: `JSNOW_STAGING`

**Full model path**: `SANDBOX_DBT_TRAINING.JSNOW_STAGING.STG_CUSTOMERS`

---

## Supported Username Formats

The macro automatically handles multiple formats:

| Format | Example | Resulting Prefix |
|--------|---------|------------------|
| Email (Okta/SSO) | `jon.snow@company.com` | `JSNOW` |
| Snowflake username | `JON.SNOW` | `JSNOW` |
| Simple format | `jon.snow` | `JSNOW` |
| Underscore separator | `sara_glacier` | `SGLACIER` |
| No separator | `bobsmith` | `BOBSMITH` |

---

## Schema Layout by User

### Jon Snow (`jon.snow@company.com`)
```
SANDBOX_DBT_TRAINING/
├── JSNOW_STAGING/
│   ├── STG_CUSTOMERS
│   ├── STG_ORDERS
│   └── STG_PRODUCTS
├── JSNOW_INTERMEDIATE/
│   ├── INT_ORDERS_WITH_PAYMENTS
│   └── INT_CUSTOMERS__ORDER_SUMMARY
└── JSNOW_MARTS/
    ├── DIM_CUSTOMERS
    └── FCT_ORDERS
```

### Sara Glacier (`sara.glacier@company.com`)
```
SANDBOX_DBT_TRAINING/
├── SGLACIER_STAGING/
│   ├── STG_CUSTOMERS
│   ├── STG_ORDERS
│   └── STG_PRODUCTS
├── SGLACIER_INTERMEDIATE/
│   ├── INT_ORDERS_WITH_PAYMENTS
│   └── INT_CUSTOMERS__ORDER_SUMMARY
└── SGLACIER_MARTS/
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
✅ **Easy Cleanup**: Drop all schemas for a user with `DROP SCHEMA JSNOW_*`

---

## Verification Queries

### Check Your Schemas

```sql
-- Show all your schemas
SHOW SCHEMAS LIKE 'JSNOW_%' IN DATABASE SANDBOX_DBT_TRAINING;
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
WHERE table_schema LIKE 'JSNOW_%'
ORDER BY table_schema, table_name;
```

### Check Specific Model Location

```sql
-- Verify a staging model
SELECT * 
FROM SANDBOX_DBT_TRAINING.JSNOW_STAGING.STG_CUSTOMERS
LIMIT 5;

-- Verify a mart model
SELECT * 
FROM SANDBOX_DBT_TRAINING.JSNOW_MARTS.DIM_CUSTOMERS
LIMIT 5;
```

---

## Troubleshooting

### Issue: Schemas created with wrong prefix

**Example**: Schemas are `_STAGING` instead of `JSNOW_STAGING`

**Cause**: Username parsing failed

**Solution**: Check your `profiles.yml` user field:

```yaml
# ✅ GOOD - first.last format (recommended)
user: jon.snow@company.com
user: jon.snow
user: JON.SNOW

# ✅ OK - no separator (full username becomes prefix, e.g., JSNOW_STAGING)
user: JSNOW

# ⚠️ LESS IDEAL - may produce unexpected prefixes
user: j.d      # Too short — prefix will be "JD"
```

**Recommended**: Use format `first.last@domain.com` or `first.last` for the clearest prefix. No-separator usernames work but the full username becomes the prefix.

---

### Issue: Schemas have multiple underscores

**Example**: `J_MIDDLE_DOE_STAGING`

**Cause**: Username has middle name or multiple parts

**Solution**: Use only first and last name:

```yaml
# Instead of: jon.middle.snow@company.com
# Use: jon.snow@company.com
```

---

### Issue: Can't see other users' schemas

**Cause**: This is expected and correct! You should only see your own schemas.

**Verification**: Each user should only have access to their own schemas:

```sql
-- You should see only your schemas
SHOW SCHEMAS IN DATABASE SANDBOX_DBT_TRAINING;

-- Expected: JSNOW_STAGING, JSNOW_MARTS, etc.
-- NOT: SGLACIER_STAGING, BJOHNSON_MARTS, etc.
```

**Exception**: If you need to view another user's work (for teaching/review):

```sql
-- Requires appropriate grants
SELECT * FROM SANDBOX_DBT_TRAINING.SGLACIER_STAGING.STG_CUSTOMERS;
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
SHOW SCHEMAS LIKE 'JSNOW_%' IN DATABASE SANDBOX_DBT_TRAINING;

-- Drop schemas (run for each schema)
DROP SCHEMA IF EXISTS SANDBOX_DBT_TRAINING.JSNOW_STAGING CASCADE;
DROP SCHEMA IF EXISTS SANDBOX_DBT_TRAINING.JSNOW_INTERMEDIATE CASCADE;
DROP SCHEMA IF EXISTS SANDBOX_DBT_TRAINING.JSNOW_MARTS CASCADE;
DROP SCHEMA IF EXISTS SANDBOX_DBT_TRAINING.JSNOW_PUBLIC CASCADE;
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
CALL cleanup_user_schemas('JSNOW');
```

---

## FAQs

### Q: Can I change my schema prefix?

**A**: The prefix is automatically generated from your Snowflake username. To change it, you would need to:
1. Update your Snowflake username (not recommended)
2. Modify the `generate_schema_name` macro (advanced)

### Q: What if two users have the same first initial + last name?

**A**: Very rare, but if it happens (e.g., Sara Glacier and Sam Glacier both → `SGLACIER`):
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

**A**: No! dbt automatically creates schemas when you run `dbt run`. The first time you build models, dbt will create `JSNOW_STAGING`, `JSNOW_MARTS`, etc. for you.

---

## Testing the Setup

### End-to-End Test

1. **Configure profile**:
   ```bash
   vi ~/.dbt/profiles.yml
   # Set user: jon.snow@company.com
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
   SHOW SCHEMAS LIKE 'JSNOW_%';
   SELECT * FROM SANDBOX_DBT_TRAINING.JSNOW_STAGING.STG_CUSTOMERS LIMIT 5;
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
   WHERE table_schema LIKE 'JSNOW_%'
   GROUP BY table_schema
   ORDER BY table_schema;
   ```

**Expected output**:
```
JSNOW_INTERMEDIATE | 3
JSNOW_MARTS        | 2
JSNOW_STAGING      | 5
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
