# Cleanup & Setup Scripts

These scripts reset the repository and Snowflake environment to a clean state, allowing you to test the lessons from scratch or start fresh.

---

## run.py (Recommended)

A cross-platform Python wrapper with an interactive menu. Works on **any OS** where Python 3 is installed (macOS, Linux, Windows). No shell-specific scripts needed.

### Interactive mode:
```
python run.py
```

This launches a menu where you can:
1. **Catch up to a lesson** - copy answer-key files to your workspace
2. **Check prerequisites** - verify files before starting a lesson
3. **Clean workspace** - remove all working files
4. **Show workspace status** - file counts and system info
5. **Quick start** - clean + catch up in one step

### CLI mode (scriptable):
```
python run.py cleanup           # Clean workspace
python run.py catchup 8         # Catch up to lesson 8
python run.py check 8           # Check prerequisites for lesson 8
python run.py status            # Show workspace status
python run.py quickstart 4      # Clean + catch up to lesson 4
```

### Ignore list (for client forks)

Edit the `IGNORE_FILES` and `IGNORE_DIRS` sets at the top of `run.py`:

```python
IGNORE_FILES = {
    ".gitkeep",
    "generate_schema_name.sql",
    "client_masking_policy.sql",   # add filenames here
}

IGNORE_DIRS = {
    "models/client_reports",       # add folder paths here
    "macros/client_utils",
}
```

---

## Shell Scripts (Alternative)

Platform-specific scripts are also available if you prefer to run them directly.
The bash (`.sh`) and PowerShell (`.ps1`) versions have identical behaviour.

### cleanup_workspace.sh

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
- Empty subdirectories left behind after file removal

### What it preserves:
- `assets/` - Reference materials and answer keys
- `lessons/` - Lesson documentation
- `dbt_project.yml` - Project configuration
- `packages.yml` - Package dependencies
- `macros/generate_schema_name.sql` - Required from start
- All `.gitkeep` files to preserve directory structure
- Any files or directories listed in the **ignore list** (see below)

### Ignore list (for client forks)

When deploying a fork of this repo into a client environment, you can add
client-specific files and directories to the ignore list at the top of
`cleanup_workspace.sh`. Ignored items will survive cleanup runs.

```bash
# In cleanup_workspace.sh — edit these arrays:
IGNORE_FILES=(
    ".gitkeep"
    "generate_schema_name.sql"
    "client_masking_policy.sql"   # ← add filenames here
)

IGNORE_DIRS=(
    "models/client_reports"       # ← add folder paths here
    "macros/client_utils"
)
```

- **`IGNORE_FILES`** — filename matches applied across all directories
- **`IGNORE_DIRS`** — folder paths relative to the project root

### Usage:

The script is location-independent — it can be run from any working directory.

**Linux/macOS:**
```bash
chmod +x cleanup_workspace.sh
./cleanup_workspace.sh

# Or from another directory:
/path/to/dbt_learning/cleanup_workspace.sh
```

**Windows (Git Bash):**
```bash
bash cleanup_workspace.sh
```

**Windows (PowerShell):**
```powershell
.\cleanup_workspace.ps1
```

The PowerShell version has its own `$IgnoreFiles` and `$IgnoreDirs` arrays at the
top of `cleanup_workspace.ps1` — edit those in a client fork the same way:

```powershell
$IgnoreFiles = @(
    ".gitkeep"
    "generate_schema_name.sql"
    "client_masking_policy.sql"   # add filenames here
)

$IgnoreDirs = @(
    "models\client_reports"       # add folder paths here
    "macros\client_utils"
)
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
- `<USER_PREFIX>_SNAPSHOTS` schema

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
# Use default connection
./cleanup_snowflake.sh

# Use specific connection
./cleanup_snowflake.sh my_connection_name
```

**Windows (Git Bash):**
```bash
bash cleanup_snowflake.sh [connection_name]
```

**Windows (PowerShell):**
```powershell
.\cleanup_snowflake.ps1 [connection_name]
```

---

## Complete Reset Workflow

To reset everything and start fresh:

**Bash (Linux/macOS/Git Bash):**
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

**PowerShell:**
```powershell
# 1. Clean local workspace
.\cleanup_workspace.ps1

# 2. Clean Snowflake artifacts
.\cleanup_snowflake.ps1

# 3. Copy seed files for testing
Copy-Item assets\seeds\orders_broken.csv seeds\orders.csv
Copy-Item assets\seeds\customers.csv seeds\
Copy-Item assets\seeds\products.csv seeds\
Copy-Item assets\seeds\order_items.csv seeds\
Copy-Item assets\seeds\payments.csv seeds\

# 4. Install packages
dbt deps

# 5. Start with Lesson 1!
```

---

## When to Use

**Use `cleanup_workspace.sh` / `cleanup_workspace.ps1` when:**
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

**"Permission denied" error (bash):**
```bash
chmod +x cleanup_workspace.sh cleanup_snowflake.sh
```

**"cannot be loaded because running scripts is disabled" error (PowerShell):**
```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```

**"snow command not found" error:**
- Install Snowflake CLI: `pip install snowflake-cli-labs`
- Or manually drop schemas in Snowsight

**Schemas not dropping:**
- Check your connection name: `snow connection list`
- Verify database access: `snow sql -c <connection> -q "USE DATABASE DBT_LEARNING"`
