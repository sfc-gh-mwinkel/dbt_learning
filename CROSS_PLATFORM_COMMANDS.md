# Cross-Platform Command Reference

This guide provides equivalent commands for Linux/macOS (bash) and Windows (PowerShell) users.

---

## File Operations

### Copy Files

**Linux/macOS:**
```bash
cp source.txt destination.txt
cp assets/seeds/customers.csv seeds/
```

**Windows:**
```powershell
Copy-Item source.txt destination.txt
Copy-Item assets\seeds\customers.csv seeds\
```

### Copy Multiple Files

**Linux/macOS:**
```bash
cp assets/seeds/*.csv seeds/
```

**Windows:**
```powershell
Copy-Item assets\seeds\*.csv seeds\
```

### Create Directory

**Linux/macOS:**
```bash
mkdir models/staging
mkdir -p models/staging/subdirectory  # Create parent dirs
```

**Windows:**
```powershell
New-Item -ItemType Directory models\staging
New-Item -ItemType Directory models\staging\subdirectory -Force  # Create parent dirs
```

---

## Checkpoint & Catch-up Scripts

### Cross-Platform (Recommended)

```bash
python run.py check 1
python run.py check 4
python run.py catchup 1
python run.py catchup 4
python run.py          # Interactive menu
```

### Check Lesson Prerequisites

**Linux/macOS:**
```bash
./scripts/check_lesson_prerequisites.sh 1
./scripts/check_lesson_prerequisites.sh 4
```

**Windows:**
```powershell
.\scripts\check_lesson_prerequisites.ps1 1
.\scripts\check_lesson_prerequisites.ps1 4
```

### Auto-Copy Missing Files (Catch-up)

**Linux/macOS:**
```bash
./scripts/catch_up.sh 1
./scripts/catch_up.sh 4
```

**Windows:**
```powershell
.\scripts\catch_up.ps1 1
.\scripts\catch_up.ps1 4
```

---

## dbt Commands (Same on All Platforms)

These commands work identically on Linux, macOS, and Windows:

```bash
# Connection & Setup
dbt debug
dbt deps

# Seed Data
dbt seed

# Build Models
dbt run
dbt run --select staging
dbt run --select +dim_customers
dbt build

# Testing
dbt test
dbt test --select staging

# Documentation
dbt docs generate
dbt docs serve

# Other Commands
dbt compile --select model_name
dbt show --select model_name
dbt snapshot
dbt ls
dbt clean
```

---

## Path Conventions

### Linux/macOS
- Forward slashes: `/`
- Home directory: `~` or `$HOME`
- dbt profiles: `~/.dbt/profiles.yml`
- Example: `models/staging/stg_customers.sql`

### Windows
- Backslashes: `\` (or forward slashes work too)
- Home directory: `$HOME` or `$env:USERPROFILE`
- dbt profiles: `$HOME\.dbt\profiles.yml`
- Example: `models\staging\stg_customers.sql`

---

## Lesson-Specific Commands

### Lesson 1: Setup

**Linux/macOS:**
```bash
cp profiles.yml.example ~/.dbt/profiles.yml
cp assets/seeds/customers.csv seeds/
cp assets/seeds/orders.csv seeds/
```

**Windows:**
```powershell
Copy-Item profiles.yml.example $HOME\.dbt\profiles.yml
Copy-Item assets\seeds\customers.csv seeds\
Copy-Item assets\seeds\orders.csv seeds\
```

### Lesson 3: All Seeds

**Linux/macOS:**
```bash
cp assets/seeds/customers.csv seeds/
cp assets/seeds/orders.csv seeds/
cp assets/seeds/products.csv seeds/
cp assets/seeds/order_items.csv seeds/
cp assets/seeds/payments.csv seeds/
```

**Windows:**
```powershell
Copy-Item assets\seeds\customers.csv seeds\
Copy-Item assets\seeds\orders.csv seeds\
Copy-Item assets\seeds\products.csv seeds\
Copy-Item assets\seeds\order_items.csv seeds\
Copy-Item assets\seeds\order_items.csv seeds\
Copy-Item assets\seeds\payments.csv seeds\
```

**Or copy all at once:**

**Linux/macOS:**
```bash
cp assets/seeds/*.csv seeds/
```

**Windows:**
```powershell
Copy-Item assets\seeds\*.csv seeds\
```

### Lesson 6: Schema Naming Macro

**Linux/macOS:**
```bash
cp assets/macros/generate_schema_name.sql macros/
```

**Windows:**
```powershell
Copy-Item assets\macros\generate_schema_name.sql macros\
```

---

## Tips for Windows Users

### PowerShell Aliases

You can create bash-like aliases in PowerShell by adding to your `$PROFILE`:

```powershell
# Open PowerShell profile
notepad $PROFILE

# Add these aliases:
function cp { Copy-Item @args }
function mkdir { New-Item -ItemType Directory @args }
```

### Using Git Bash on Windows

If you have Git for Windows installed, you can use Git Bash which supports Linux/macOS commands natively:

```bash
# All Linux/macOS commands work in Git Bash
cp assets/seeds/customers.csv seeds/
./scripts/check_lesson_prerequisites.sh 1
# Or use run.py which works everywhere:
python run.py check 1
```

### WSL (Windows Subsystem for Linux)

For the most native Linux experience on Windows, consider using WSL:

```bash
# After installing WSL, all Linux commands work
cp assets/seeds/customers.csv seeds/
./scripts/check_lesson_prerequisites.sh 1
# Or use run.py which works everywhere:
python run.py check 1
```

---

## Quick Translation Table

| Task | Linux/macOS | Windows (PowerShell) |
|------|-------------|---------------------|
| Copy file | `cp src dst` | `Copy-Item src dst` |
| Copy all CSVs | `cp *.csv dst/` | `Copy-Item *.csv dst\` |
| Make directory | `mkdir dir` | `New-Item -ItemType Directory dir` |
| Run bash script | `./script.sh` | `.\script.ps1` |
| Home directory | `~/` or `$HOME` | `$HOME\` or `$env:USERPROFILE\` |
| Path separator | `/` | `\` (or `/` also works) |
| View file | `cat file.txt` | `Get-Content file.txt` or `cat file.txt` |
| List files | `ls` | `Get-ChildItem` or `ls` (alias) |

---

## Need Help?

- **Windows users**: All lesson instructions can be adapted using this guide
- **Linux/macOS users**: Follow lesson instructions as written
- **All users**: dbt commands are identical across all platforms

If you encounter platform-specific issues, check [TROUBLESHOOTING.md](TROUBLESHOOTING.md).
