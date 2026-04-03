# dbt Learning Platform - Setup Wizard

> **For AI Assistants**: This document is designed to help you guide users through setting up the dbt Learning Platform. Follow the sections in order, validating each step before proceeding.

---

## Quick Reference: What We're Setting Up

| Component | Purpose |
|-----------|---------|
| Python virtual environment | Isolated dbt-core installation |
| dbt-core + dbt-snowflake | The dbt framework and Snowflake adapter |
| profiles.yml | Snowflake connection configuration |
| Snowflake objects | Database, warehouse, and schemas |

---

## Phase 1: Python Environment Setup

### Step 1.1: Check Python Version

```bash
python3 --version
```

**Required**: Python 3.9 or higher.

If Python is not installed or the version is too old, install it using the instructions below for your platform, then re-run the version check.

#### Installing Python

**macOS** (Homebrew):
```bash
brew install python@3.12
```

**macOS** (official installer): Download from [python.org/downloads](https://www.python.org/downloads/)

**Windows** (winget):
```powershell
winget install Python.Python.3.12
```

**Windows** (official installer): Download from [python.org/downloads](https://www.python.org/downloads/) — check "Add Python to PATH" during install.

**Ubuntu/Debian**:
```bash
sudo apt update && sudo apt install python3 python3-venv python3-pip
```

**Fedora/RHEL**:
```bash
sudo dnf install python3 python3-pip
```

After installing, open a **new terminal** and verify:
```bash
python3 --version  # Should show 3.9+
```

### Step 1.2: Create Virtual Environment

```bash
cd /path/to/dbt_learning
python3 -m venv .venv
```

### Step 1.3: Activate Virtual Environment

**Linux/macOS:**
```bash
source .venv/bin/activate
```

**Windows PowerShell:**
```powershell
.\.venv\Scripts\Activate.ps1
```

**Windows CMD:**
```cmd
.\.venv\Scripts\activate.bat
```

**Validation**: The prompt should show `(.venv)` prefix.

### Step 1.4: Install Dependencies

```bash
pip install --upgrade pip
pip install dbt-core dbt-snowflake
```

**Validation**:
```bash
dbt --version
```

Expected output should show:
- dbt-core: 1.9.x or higher
- dbt-snowflake: 1.9.x or higher

---

## Phase 2: Snowflake Connection Setup

### Step 2.1: Gather Connection Information

Ask the user for the following information:

| Setting | Example | How to Find |
|---------|---------|-------------|
| Account | `abc12345.us-west-2` | Snowflake URL before `.snowflakecomputing.com` |
| Username | `JON.SNOW` | Their Snowflake login username |
| Role | `ACCOUNTADMIN` or custom | Role with CREATE DATABASE/SCHEMA permissions |
| Warehouse | `COMPUTE_WH` | Any warehouse they have access to |
| Database | `DBT_LEARNING` | Will be created if doesn't exist |
| Authentication | SSO/Key-pair/Password | Their preferred auth method |

### Step 2.2: Determine Authentication Method

Ask: **"How do you authenticate to Snowflake?"**

Options:
1. **SSO/Okta** (externalbrowser) - Opens browser for login
2. **Key-pair authentication** (SNOWFLAKE_JWT) - Uses private key file
3. **Username/Password** - Basic auth (least secure)
4. **Snowflake CLI connection** - Reuse existing `snow` CLI config

### Step 2.3: Create profiles.yml

Create the dbt profiles directory if it doesn't exist:

```bash
mkdir -p ~/.dbt
```

**Option A: SSO/Okta Authentication (Recommended for interactive use)**

```yaml
# ~/.dbt/profiles.yml
dbt_learning:
  target: dev
  outputs:
    dev:
      type: snowflake
      account: <ACCOUNT>           # e.g., abc12345.us-west-2
      user: <USERNAME>             # e.g., JON.SNOW or jon.snow@company.com
      role: <ROLE>                 # e.g., ACCOUNTADMIN
      warehouse: <WAREHOUSE>       # e.g., COMPUTE_WH
      database: DBT_LEARNING
      schema: public
      authenticator: externalbrowser
      threads: 4
```

**Option B: Key-Pair Authentication (Recommended for automation)**

```yaml
# ~/.dbt/profiles.yml
dbt_learning:
  target: dev
  outputs:
    dev:
      type: snowflake
      account: <ACCOUNT>
      user: <USERNAME>
      role: <ROLE>
      warehouse: <WAREHOUSE>
      database: DBT_LEARNING
      schema: public
      authenticator: SNOWFLAKE_JWT
      private_key_path: ~/.snowflake/rsa_key.p8   # Path to private key
      # private_key_passphrase: <passphrase>      # If key is encrypted
      threads: 4
```

**Option C: Username/Password (Simplest but least secure)**

```yaml
# ~/.dbt/profiles.yml
dbt_learning:
  target: dev
  outputs:
    dev:
      type: snowflake
      account: <ACCOUNT>
      user: <USERNAME>
      password: <PASSWORD>         # Consider using environment variable
      role: <ROLE>
      warehouse: <WAREHOUSE>
      database: DBT_LEARNING
      schema: public
      threads: 4
```

**Option D: Using Environment Variables (Most secure for passwords)**

```yaml
# ~/.dbt/profiles.yml
dbt_learning:
  target: dev
  outputs:
    dev:
      type: snowflake
      account: "{{ env_var('SNOWFLAKE_ACCOUNT') }}"
      user: "{{ env_var('SNOWFLAKE_USER') }}"
      password: "{{ env_var('SNOWFLAKE_PASSWORD') }}"
      role: "{{ env_var('SNOWFLAKE_ROLE') }}"
      warehouse: "{{ env_var('SNOWFLAKE_WAREHOUSE') }}"
      database: DBT_LEARNING
      schema: public
      threads: 4
```

Then set environment variables:
```bash
export SNOWFLAKE_ACCOUNT="abc12345.us-west-2"
export SNOWFLAKE_USER="JON.SNOW"
export SNOWFLAKE_PASSWORD="your-password"
export SNOWFLAKE_ROLE="ACCOUNTADMIN"
export SNOWFLAKE_WAREHOUSE="COMPUTE_WH"
```

### Step 2.4: Key-Pair Setup (If using Option B)

If user needs to set up key-pair authentication:

```bash
# Generate key pair
mkdir -p ~/.snowflake
openssl genrsa 2048 | openssl pkcs8 -topk8 -inform PEM -out ~/.snowflake/rsa_key.p8 -nocrypt

# Extract public key
openssl rsa -in ~/.snowflake/rsa_key.p8 -pubout -out ~/.snowflake/rsa_key.pub

# Display public key for Snowflake (remove header/footer and newlines)
grep -v "PUBLIC KEY" ~/.snowflake/rsa_key.pub | tr -d '\n'
```

Then in Snowflake:
```sql
ALTER USER <USERNAME> SET RSA_PUBLIC_KEY='<paste-public-key-here>';
```

### Step 2.5: Validate Connection

```bash
cd /path/to/dbt_learning
source .venv/bin/activate  # If not already activated
dbt debug
```

**Expected output**: All checks should pass, ending with:
```
Connection test: [OK connection ok]
All checks passed!
```

**Common errors and fixes**:

| Error | Cause | Fix |
|-------|-------|-----|
| `Account not found` | Wrong account identifier | Check account format (include region if needed) |
| `Incorrect username or password` | Auth failed | Verify credentials, check SSO if using externalbrowser |
| `Role does not exist` | Invalid role | List roles with `SHOW ROLES` in Snowflake |
| `Warehouse does not exist` | Invalid warehouse | List warehouses with `SHOW WAREHOUSES` |
| `Private key not found` | Wrong key path | Verify `private_key_path` in profiles.yml |

---

## Phase 3: Snowflake Database Setup

### Step 3.1: Create Database (if needed)

If the user doesn't have CREATE DATABASE permission, they need to ask their admin. Otherwise:

```sql
-- Run in Snowflake
CREATE DATABASE IF NOT EXISTS DBT_LEARNING;
USE DATABASE DBT_LEARNING;
```

### Step 3.2: Verify Permissions

The user needs these permissions:
- CREATE SCHEMA on DBT_LEARNING database
- USAGE on their warehouse
- CREATE TABLE/VIEW permissions

Test by running:
```bash
dbt debug
```

---

## Phase 4: Project Initialization

### Step 4.1: Install dbt Packages

```bash
cd /path/to/dbt_learning
source .venv/bin/activate
dbt deps
```

This installs `dbt_utils` from packages.yml.

### Step 4.2: Verify Project Configuration

```bash
dbt debug
```

All checks should pass.

### Step 4.3: Quick Start Test

Copy initial seed files and run:

```bash
# Copy seed data
cp assets/seeds/customers.csv seeds/
cp assets/seeds/orders.csv seeds/

# Load seeds into Snowflake
dbt seed

# Verify seeds loaded
dbt show --select customers --limit 3
```

**Expected**: Should show 3 rows of customer data.

---

## Phase 5: Understanding the Multi-User Schema Pattern

### How Schema Names Work

This project uses two macros that work together to create user-specific schemas: `get_user_prefix` (parses `target.user` into a personal prefix) and `generate_schema_name` (uses that prefix to assemble the final schema name):

| Username | Schema Prefix | Example Schemas |
|----------|--------------|-----------------|
| `JON.SNOW` | `JSNOW_` | `JSNOW_RAW`, `JSNOW_STAGING`, `JSNOW_MARTS` |
| `sara.glacier@company.com` | `SGLACIER_` | `SGLACIER_RAW`, `SGLACIER_STAGING` |
| `BFROST` | `BFROST_` | `BFROST_RAW`, `BFROST_STAGING` |

This allows multiple users to work in the same database without conflicts.

### Verify Your Schema Prefix

```bash
dbt compile --select stg_customers
```

Check the compiled SQL in `target/compiled/` - the FROM clause will show your schema name (e.g., `DBT_LEARNING.JSNOW_RAW.customers`).

---

## Troubleshooting Quick Reference

### Virtual Environment Issues

```bash
# Recreate venv if corrupted
rm -rf .venv
python3 -m venv .venv
source .venv/bin/activate
pip install dbt-core dbt-snowflake
```

### Connection Issues

```bash
# Test raw connection with snowsql (if installed)
snowsql -a <account> -u <user>

# Or test with Python
python3 -c "
import snowflake.connector
conn = snowflake.connector.connect(
    account='<account>',
    user='<user>',
    authenticator='externalbrowser'
)
print('Connected!')
conn.close()
"
```

### Profile Not Found

```bash
# Check profiles.yml location
cat ~/.dbt/profiles.yml

# Check dbt is finding it
dbt debug --config-dir
```

### Permission Errors

```sql
-- Run in Snowflake to check your grants
SHOW GRANTS TO USER <your-username>;
SHOW GRANTS TO ROLE <your-role>;
```

---

## Ready to Learn!

Once setup is complete, the user can start with Lesson 1:

```bash
# Verify everything works
dbt debug

# Start Lesson 1
cat lessons/01_project_setup.md
```

**Tip**: Run the checkpoint script before each lesson:
```bash
python run.py check 1
# Or: ./scripts/check_lesson_prerequisites.sh 1
```

---

## For AI Assistants: Decision Tree

```
START
  │
  ├─► Check Python version (need 3.9+)
  │     └─► If missing: guide Python installation
  │
  ├─► Create/activate virtual environment
  │     └─► Verify (.venv) in prompt
  │
  ├─► Install dbt-core dbt-snowflake
  │     └─► Verify with `dbt --version`
  │
  ├─► Ask about authentication method
  │     ├─► SSO → use externalbrowser
  │     ├─► Key-pair → guide key generation
  │     ├─► Password → warn about security, use env vars
  │     └─► Existing snow CLI → check connections.toml
  │
  ├─► Create ~/.dbt/profiles.yml
  │     └─► Use appropriate template
  │
  ├─► Run `dbt debug`
  │     ├─► Success → proceed to Phase 4
  │     └─► Failure → diagnose and fix
  │
  ├─► Run `dbt deps`
  │
  ├─► Quick test: copy seeds, run `dbt seed`
  │     ├─► Success → SETUP COMPLETE
  │     └─► Failure → check permissions
  │
  └─► Guide to Lesson 1
```

---

## Environment Checklist

Before starting lessons, verify:

- [ ] Python 3.9+ installed
- [ ] Virtual environment created and activated
- [ ] dbt-core and dbt-snowflake installed
- [ ] ~/.dbt/profiles.yml configured
- [ ] `dbt debug` passes all checks
- [ ] `dbt deps` completed successfully
- [ ] Snowflake database DBT_LEARNING exists
- [ ] User has CREATE SCHEMA permission

All set? Start with [Lesson 1: Project Setup](lessons/01_project_setup.md)!
