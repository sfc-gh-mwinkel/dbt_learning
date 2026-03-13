# Lesson 6: dbt_project.yml Deep Dive

## Learning Objectives

By the end of this lesson you will be able to:
- Understand every section of `dbt_project.yml`
- Configure materializations, schemas, and tags at the folder level
- Use variables (`vars`) for reusable configuration
- Understand hooks (pre and post)
- Know how folder-level configs reduce repetition

---

## Prerequisites

- **Completed:** Lessons 1-5
- **Models exist:** Full staging, intermediate, and marts layers
- **Tests passing:** `dbt test` completes with no failures

**Catch up:** If you're missing prerequisites, run:
```bash
./scripts/catch_up.sh 6
```

---

## 6.1 Anatomy of dbt_project.yml

Here is your project file with annotations:

```yaml
# Project identity
name: 'dbt_learning'           # Must match the profile name
version: '1.0.0'               # Semantic versioning for your project

# Connection profile
profile: 'dbt_learning'        # Maps to profiles.yml

# File paths
model-paths: ["models"]        # Where dbt looks for .sql model files
analysis-paths: ["analyses"]   # Ad-hoc analysis queries (not materialized)
test-paths: ["tests"]          # Singular test SQL files
seed-paths: ["seeds"]          # CSV files for dbt seed
macro-paths: ["macros"]        # Jinja macros
snapshot-paths: ["snapshots"]  # Snapshot definitions

# Cleanup targets
clean-targets:
  - "target"                   # Compiled SQL output
  - "dbt_packages"             # Installed packages

# Model configurations
models:
  dbt_learning:
    staging:
      +materialized: view
      +schema: staging
    intermediate:
      +materialized: view
      +schema: intermediate
    marts:
      +materialized: table
      +schema: marts

# Seed configurations
seeds:
  dbt_learning:
    +schema: raw
```

---

## 6.2 Folder-Level Configuration

The most powerful feature of `dbt_project.yml` is folder-level configuration. Instead of adding `{{ config() }}` to every model, set defaults by folder:

```yaml
models:
  dbt_learning:           # Must match your project name
    staging:              # Matches models/staging/ folder
      +materialized: view
      +schema: staging
      +tags: ["staging"]
    intermediate:         # Matches models/intermediate/ folder
      +materialized: view
      +schema: intermediate
      +tags: ["intermediate"]
    marts:                # Matches models/marts/ folder
      +materialized: table
      +schema: marts
      +tags: ["marts"]
```

**The `+` prefix** means "this config applies to all models in this folder and its subfolders."

> **Note:** You'll notice Jinja syntax like `{{ }}` and `{% %}` in some configurations. This templating language is covered in detail in Lesson 8. For now, just use the code as shown.

**Override at model level** when a specific model needs different settings:

```sql
-- This model overrides the folder default
{{ config(materialized='incremental', unique_key='order_id') }}

select ...
```

---

## 6.3 Schema Configuration

The `+schema` config controls which Snowflake schema a model lands in:

```yaml
staging:
  +schema: staging
```

**Important:** By default, dbt _concatenates_ the target schema with the custom schema. If your target schema is `public` and you set `+schema: staging`, the actual schema becomes `public_staging`.

To get exact schema names, you need a custom `generate_schema_name` macro. Copy the provided macro now:

**Linux/macOS:**
```bash
cp assets/macros/generate_schema_name.sql macros/
```

**Windows:**
```powershell
Copy-Item assets\macros\generate_schema_name.sql macros\
```

### Understanding the Multi-User Schema Macro

This macro is designed for **production environments** where multiple users work in the same Snowflake database. It creates user-specific schemas to prevent conflicts.

**Schema Naming Pattern**: `<first_initial><last_name>_<schema_name>`

**Examples**:
- John Doe → `JDOE_STAGING`, `JDOE_MARTS`
- Jane Smith → `JSMITH_STAGING`, `JSMITH_MARTS`
- Bob Johnson → `BJOHNSON_INTERMEDIATE`

**How it works**:

1. **Extracts your username** from `profiles.yml` (the `user:` field)
2. **Parses your name** (handles formats like `john.doe@company.com`, `john.doe`, or `JOHN.DOE`)
3. **Creates your prefix**: First initial + last name (e.g., John Doe → `JDOE`)
4. **Combines with schema name**: `JDOE` + `_` + `STAGING` → `JDOE_STAGING`

**Configuration in `profiles.yml`**:
```yaml
dbt_learning:
  outputs:
    dev:
      user: john.doe@company.com   # ← Your actual name here
      database: SANDBOX_DBT_TRAINING  # ← Shared database
```

**Result in Snowflake**:
- Database: `SANDBOX_DBT_TRAINING` (shared by all users)
- Schemas: `JDOE_STAGING`, `JDOE_INTERMEDIATE`, `JDOE_MARTS` (unique to you)
- Full path: `SANDBOX_DBT_TRAINING.JDOE_STAGING.STG_CUSTOMERS`

**Why this matters**:
- ✅ Multiple students can work simultaneously without conflicts
- ✅ Each user has isolated schemas
- ✅ Everyone shares the same database and seed data
- ✅ Clean, predictable naming pattern

**Verify your schema names**:
```bash
# After running dbt, check what schemas were created
dbt run --select stg_customers
```

Then in Snowflake:
```sql
-- Show your schemas
SHOW SCHEMAS LIKE 'JDOE_%' IN DATABASE SANDBOX_DBT_TRAINING;

-- Verify model location
SELECT 
  table_catalog as database,
  table_schema as schema,
  table_name
FROM information_schema.tables
WHERE table_schema LIKE 'JDOE_%'
  AND table_name = 'STG_CUSTOMERS';
```

> **Note**: The macro is extensively documented with inline comments. Open `macros/generate_schema_name.sql` to see the detailed step-by-step explanation of how username parsing works.

---

## 6.4 Tags

Tags let you organize and selectively run models:

```yaml
models:
  dbt_learning:
    staging:
      +tags: ["staging", "daily"]
    marts:
      +tags: ["marts", "daily"]
```

**Tag inheritance:** Tags are additive. A model in a subfolder inherits all parent tags.

```yaml
marts:
  +tags: ["marts"]
  finance:
    +tags: ["finance"]    # Gets both "marts" AND "finance"
```

Run models by tag:

```bash
dbt run --select tag:daily       # All models tagged "daily"
dbt run --select tag:marts       # All mart models
dbt test --select tag:staging    # Test only staging models
```

---

## 6.5 Variables (vars)

Variables let you define reusable values:

```yaml
vars:
  default_start_date: '2024-01-01'
  high_value_threshold: 300
  mid_value_threshold: 100
```

Use them in models with `{{ var() }}`:

```sql
select
    *,
    -- var() reads from the 'vars' section of dbt_project.yml.
    -- This keeps magic numbers out of SQL and in one central config file.
    -- Values can be overridden at runtime via --vars without editing code.
    case
        when lifetime_value >= {{ var('high_value_threshold') }} then 'gold'
        when lifetime_value >= {{ var('mid_value_threshold') }} then 'silver'
        else 'bronze'
    end as customer_tier
from {{ ref('stg_customers') }}
```

Override at runtime:

```bash
dbt run --vars '{"high_value_threshold": 500}'
```

---

## 6.6 Hooks

Hooks run SQL statements before or after dbt operations:

```yaml
# on-run-end hooks execute after all models finish. Common uses:
# granting permissions, refreshing caches, or logging completion.
on-run-end:
  - "GRANT SELECT ON ALL TABLES IN SCHEMA {{ target.schema }}_marts TO ROLE analyst_role"

models:
  dbt_learning:
    marts:
      # post-hook runs after each individual model in this folder.
      # {{ this }} resolves to the specific model's fully qualified table name.
      +post-hook:
        - "GRANT SELECT ON {{ this }} TO ROLE analyst_role"
```

Hook types:
| Hook | When It Runs |
|------|-------------|
| `pre-hook` | Before a model is built |
| `post-hook` | After a model is built |
| `on-run-start` | Before any model runs |
| `on-run-end` | After all models have run |

> **Note:** Hooks use Jinja expressions like `{{ target.schema }}` and `{{ this }}`. These are explained in Lesson 8. For now, know that `{{ this }}` refers to the current model's table name.

> **Caution:** Be cautious with hooks. They run SQL directly and can have side effects. Use them for grants, logging, or cache clearing.

---

## 6.7 Seed Configuration

Configure how seeds are loaded:

```yaml
seeds:
  dbt_learning:
    +schema: raw               # Load seeds into a "raw" schema
    +quote_columns: false       # Don't quote column names

    # Override for a specific seed
    customers:
      +column_types:
        customer_id: integer
        created_at: timestamp
```

---

## 6.8 The Full Picture

Here's a comprehensive `dbt_project.yml` with all features:

```yaml
name: 'dbt_learning'
version: '1.0.0'
profile: 'dbt_learning'

model-paths: ["models"]
test-paths: ["tests"]
seed-paths: ["seeds"]
macro-paths: ["macros"]
snapshot-paths: ["snapshots"]

clean-targets:
  - "target"
  - "dbt_packages"

vars:
  high_value_threshold: 300
  mid_value_threshold: 100

models:
  dbt_learning:
    staging:
      +materialized: view
      +schema: staging
      +tags: ["staging"]
    intermediate:
      +materialized: view
      +schema: intermediate
      +tags: ["intermediate"]
    marts:
      +materialized: table
      +schema: marts
      +tags: ["marts"]

seeds:
  dbt_learning:
    +schema: raw

snapshots:
  dbt_learning:
    +tags: ["snapshot"]
```

---

## 6.9 Exercises

1. Add `+tags` to each layer in your `dbt_project.yml`
2. Add a `vars` section with `high_value_threshold: 300` and use it in `dim_customers`
3. Run `dbt run --select tag:staging` to verify tag-based selection
4. Try overriding a variable: `dbt run --vars '{"high_value_threshold": 500}' --select dim_customers`
5. Run `dbt show --select dim_customers` and check if the tier thresholds changed

---

## 6.10 Key Takeaways

| Concept | What You Learned |
|---------|-----------------|
| Folder-level config | `+` prefix applies settings to all models in a folder |
| `+schema` | Controls which Snowflake schema models land in |
| `+tags` | Additive labels for selective runs |
| `vars` | Project-level variables; overridable at runtime |
| Hooks | SQL that runs before/after models or runs |
| Seeds config | Control schema, column types, quoting for CSVs |
| Precedence | Model-level config > folder-level config > project defaults |

---

**Previous:** [Lesson 5 - Testing & Data Quality](05_testing.md) | **Next:** [Lesson 7 - Snapshots & SCD Type 2](07_snapshots.md)
