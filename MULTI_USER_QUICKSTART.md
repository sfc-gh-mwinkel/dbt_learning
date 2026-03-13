# Multi-User Quick Start

**Production Database**: `SANDBOX_DBT_TRAINING` (shared by all users)

**Schema Naming**: `<FirstInitial><LastName>_<SchemaName>`

---

## 1. Configure Your Profile

Edit your dbt profiles file:
- **Linux/macOS**: `~/.dbt/profiles.yml`
- **Windows**: `$HOME\.dbt\profiles.yml`

```yaml
dbt_learning:
  target: dev
  outputs:
    dev:
      type: snowflake
      account: YOUR_ACCOUNT
      user: john.doe@company.com  # ← Your actual email
      authenticator: externalbrowser
      role: YOUR_ROLE
      database: SANDBOX_DBT_TRAINING  # ← Shared database
      warehouse: YOUR_WAREHOUSE
      schema: public
      threads: 4
```

---

## 2. Test Your Setup

```bash
# Test connection
dbt debug

# Expected: Connection successful
```

---

## 3. Verify Schema Names

**Linux/macOS:**
```bash
# Copy the schema naming macro
cp assets/macros/generate_schema_name.sql macros/

# Run a test model
dbt run --select stg_customers
```

**Windows:**
```powershell
# Copy the schema naming macro
Copy-Item assets\macros\generate_schema_name.sql macros\

# Run a test model
dbt run --select stg_customers
```

**In Snowflake**:
```sql
-- Check your schemas (replace JDOE with your prefix)
SHOW SCHEMAS LIKE 'JDOE_%' IN DATABASE SANDBOX_DBT_TRAINING;

-- Expected: JDOE_STAGING, JDOE_MARTS, etc.
```

---

## How Your Name Becomes Your Prefix

| Your User | Parsing | Prefix | Example Schema |
|-----------|---------|--------|----------------|
| `john.doe@company.com` | j + doe | `JDOE` | `JDOE_STAGING` |
| `jane.smith@company.com` | j + smith | `JSMITH` | `JSMITH_MARTS` |
| `bob_johnson` | b + johnson | `BJOHNSON` | `BJOHNSON_INTERMEDIATE` |

---

## Full Example

**Your config**: `user: john.doe@company.com`

**Your schemas**:
```
SANDBOX_DBT_TRAINING/
├── JDOE_STAGING/
│   ├── STG_CUSTOMERS
│   ├── STG_ORDERS
│   └── STG_PRODUCTS
├── JDOE_INTERMEDIATE/
│   └── INT_ORDERS_WITH_PAYMENTS
└── JDOE_MARTS/
    ├── DIM_CUSTOMERS
    └── FCT_ORDERS
```

**Query your models**:
```sql
SELECT * FROM SANDBOX_DBT_TRAINING.JDOE_STAGING.STG_CUSTOMERS;
SELECT * FROM SANDBOX_DBT_TRAINING.JDOE_MARTS.DIM_CUSTOMERS;
```

---

## Need More Details?

📖 See [MULTI_USER_SETUP.md](MULTI_USER_SETUP.md) for:
- Complete troubleshooting guide
- Administrator setup instructions
- Schema verification queries
- Cleanup procedures

---

**Ready to start learning?** Continue with [Lesson 1](lessons/01_introduction.md)!
