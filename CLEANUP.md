# Cleanup Scripts

These scripts reset the repository and Snowflake environment to a clean state, allowing you to test the lessons from scratch or start fresh.

---

## cleanup_workspace.sh

Resets your **local workspace** by removing all completed dbt artifacts.

### What it removes:
- `target/` - Compiled SQL and run artifacts
- `dbt_packages/` - Installed packages
- All files in `models/` (except `.gitkeep`)
- All files in `tests/` (except `.gitkeep`)
- All files in `seeds/` (except `.gitkeep`)
- All files in `snapshots/` (except `.gitkeep`)
- All files in `macros/` except `generate_schema_name.sql` (except `.gitkeep`)
- `package-lock.yml`

### What it preserves:
- `assets/` - Reference materials and answer keys
- `lessons/` - Lesson documentation
- `dbt_project.yml` - Project configuration
- `packages.yml` - Package dependencies
- `macros/generate_schema_name.sql` - Required from start
- All `.gitkeep` files to preserve directory structure

### Usage:

**Linux/macOS:**
```bash
chmod +x cleanup_workspace.sh
./cleanup_workspace.sh
```

**Windows (Git Bash):**
```bash
bash cleanup_workspace.sh
```

After running, copy seed files from assets:
```bash
cp assets/seeds/orders_broken.csv seeds/orders.csv
cp assets/seeds/customers.csv seeds/
cp assets/seeds/products.csv seeds/
cp assets/seeds/order_items.csv seeds/
cp assets/seeds/payments.csv seeds/
```

---

## cleanup_snowflake.sh

Drops all **Snowflake schemas** created by dbt, giving you a fresh start.

### What it removes:
- `<USER_PREFIX>_RAW` schema
- `<USER_PREFIX>_STAGING` schema
- `<USER_PREFIX>_INTERMEDIATE` schema
- `<USER_PREFIX>_MARTS` schema
- `<USER_PREFIX>_DBT_TEST__AUDIT` schema
- `public_snapshots` schema

### What it preserves:
- `DBT_LEARNING` database (you'll need it for future runs)

### Usage:

**Linux/macOS:**
```bash
chmod +x cleanup_snowflake.sh
./cleanup_snowflake.sh [connection_name]
```

**Examples:**
```bash
# Use default connection (snowsecure_deploy)
./cleanup_snowflake.sh

# Use specific connection
./cleanup_snowflake.sh my_connection
```

**Windows (Git Bash):**
```bash
bash cleanup_snowflake.sh [connection_name]
```

---

## Complete Reset Workflow

To reset everything and start fresh:

```bash
# 1. Clean local workspace
./cleanup_workspace.sh

# 2. Clean Snowflake artifacts
./cleanup_snowflake.sh

# 3. Copy seed files for testing
cp assets/seeds/orders_broken.csv seeds/orders.csv
cp assets/seeds/customers.csv seeds/
cp assets/seeds/products.csv seeds/
cp assets/seeds/order_items.csv seeds/
cp assets/seeds/payments.csv seeds/

# 4. Install packages
dbt deps

# 5. Start with Lesson 1!
```

---

## When to Use

**Use `cleanup_workspace.sh` when:**
- You want to test the lessons from scratch
- You've made mistakes and want to start over
- You're switching between different lesson approaches

**Use `cleanup_snowflake.sh` when:**
- Your Snowflake schemas are cluttered with test data
- You want to verify schema creation works correctly
- You've changed the `generate_schema_name` macro and need to rebuild

**Use both when:**
- You're about to commit changes to git (ensure clean state)
- You're testing the full lesson workflow
- You're preparing the repo for students

---

## Safety Notes

⚠️ **These scripts are destructive!**
- `cleanup_workspace.sh` deletes local files - make sure you've saved any custom work
- `cleanup_snowflake.sh` drops schemas and all their tables - make sure you don't have production data

✅ **Safe operations:**
- Both scripts preserve reference materials in `assets/`
- `cleanup_snowflake.sh` preserves the `DBT_LEARNING` database
- You can always rebuild everything by following the lessons

---

## Troubleshooting

**"Permission denied" error:**
```bash
chmod +x cleanup_workspace.sh cleanup_snowflake.sh
```

**"snow command not found" error:**
- Install Snowflake CLI: `pip install snowflake-cli-labs`
- Or manually drop schemas in Snowsight

**Schemas not dropping:**
- Check your connection name: `snow connection list`
- Verify database access: `snow sql -c <connection> -q "USE DATABASE DBT_LEARNING"`
