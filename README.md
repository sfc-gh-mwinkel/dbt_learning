# dbt Learning Platform

A hands-on, lesson-driven introduction to **dbt-core** with **Snowflake**. Start from zero and build a complete dbt project through structured lessons covering fundamentals to advanced data quality patterns.

> **New!** Added checkpoint validation, catch-up scripts, and Lesson 12 on enterprise data quality with `dbt_constraints`.

> **Windows Users**: PowerShell versions of all scripts are included. See [Cross-Platform Commands Guide](CROSS_PLATFORM_COMMANDS.md) for command translations.

---

## Prerequisites

- Python 3.9+
- A Snowflake account (with a database, warehouse, and role)
- `pip install dbt-core dbt-snowflake`

> **Production Setup**: This project is configured for multi-user environments where multiple students work in `SANDBOX_DBT_TRAINING` database with user-specific schemas (e.g., `JDOE_STAGING`). See [Multi-User Setup Guide](MULTI_USER_SETUP.md) for details.

---

## Getting Started

### Linux/macOS

```bash
# 1. Clone this repo
git clone <repo-url> && cd dbt_learning

# 2. Set up your Snowflake connection
cp profiles.yml.example ~/.dbt/profiles.yml
# Edit ~/.dbt/profiles.yml with your credentials

# 3. Verify connection
dbt debug

# 4. Install packages
dbt deps

# 5. Start with Lesson 1
# Tip: Run checkpoint before each lesson to verify prerequisites
./scripts/check_lesson_prerequisites.sh 1
```

### Windows (PowerShell)

```powershell
# 1. Clone this repo
git clone <repo-url>
cd dbt_learning

# 2. Set up your Snowflake connection
Copy-Item profiles.yml.example $HOME\.dbt\profiles.yml
# Edit $HOME\.dbt\profiles.yml with your credentials

# 3. Verify connection
dbt debug

# 4. Install packages
dbt deps

# 5. Start with Lesson 1
# Tip: Run checkpoint before each lesson to verify prerequisites
.\scripts\check_lesson_prerequisites.ps1 1
```

---

## Lesson Plan

| # | Lesson | Topics | Key Commands |
|---|--------|--------|-------------|
| 1 | [Project Setup & First Model](lessons/01_project_setup.md) | profiles.yml, dbt seed, sources, first staging model | `dbt debug`, `dbt seed`, `dbt run` |
| 2 | [Understanding YML Files](lessons/02_yml_files.md) | sources.yml, schema.yml, descriptions, basic tests | `dbt test` |
| 3 | [The Staging Layer](lessons/03_staging_layer.md) | ref(), materialization, naming conventions | `dbt run --select`, `dbt show` |
| 4 | [Intermediate & Mart Models](lessons/04_intermediate_and_marts.md) | Joins, CTEs, dim/fct models, incremental | `dbt run`, `dbt ls` |
| 5 | [Testing & Data Quality](lessons/05_testing.md) | Generic tests, singular tests, dbt_utils, severity | `dbt test`, `dbt deps` |
| 6 | [dbt_project.yml Deep Dive](lessons/06_dbt_project_yml.md) | Folder config, tags, vars, hooks, schemas | `dbt run --select tag:` |
| 7 | [Snapshots & SCD Type 2](lessons/07_snapshots.md) | check/timestamp strategy, dbt_valid_from/to | `dbt snapshot` |
| 8 | [Writing Macros](lessons/08_macros.md) | Jinja basics, custom macros, generate_schema_name | `dbt compile` |
| 9 | [Documentation & dbt docs](lessons/09_documentation.md) | Descriptions, doc blocks, DAG viewer, source freshness | `dbt docs generate`, `dbt docs serve` |
| 10 | [Graph Operators & dbt build](lessons/10_graph_operators.md) | +model+, @, dbt build, --full-refresh, selectors | `dbt build`, `dbt ls --select` |
| 12 | [**NEW!** Enterprise Data Quality](lessons/12_dbt_constraints.md) | dbt_constraints, primary keys, foreign keys, database enforcement | `dbt test` |

---

## Repository Structure

```
dbt_learning/
├── lessons/                    # Scripted lesson files (start here)
│   ├── 01_project_setup.md
│   ├── 02_yml_files.md
│   ├── 03_staging_layer.md
│   ├── 04_intermediate_and_marts.md
│   ├── 05_testing.md
│   ├── 06_dbt_project_yml.md
│   ├── 07_snapshots.md
│   ├── 08_macros.md
│   ├── 09_documentation.md
│   ├── 10_graph_operators.md
│   └── 12_dbt_constraints.md   # Enterprise data quality
├── assets/                     # Pre-built files for lessons
│   ├── seeds/                  # CSV data files to copy into seeds/
│   ├── models/                 # Reference model implementations
│   │   ├── staging/
│   │   ├── intermediate/
│   │   └── marts/
│   ├── yml_templates/          # Source and schema YML templates
│   ├── macros/                 # Macro reference implementations
│   ├── snapshots/              # Snapshot reference implementations
│   └── tests/                  # Custom test reference implementations
├── models/                     # Your dbt models (build these in lessons)
│   ├── staging/
│   ├── intermediate/
│   └── marts/
├── seeds/                      # CSV seed files (copied from assets)
├── snapshots/                  # Snapshot definitions
├── macros/                     # Custom macros
├── tests/                      # Singular test files
├── dbt_project.yml             # Project configuration
├── packages.yml                # Package dependencies
├── profiles.yml.example        # Connection template
├── scripts/                    # Helper scripts (NEW!)
│   ├── check_lesson_prerequisites.sh   # Verify prerequisites (Linux/macOS)
│   ├── check_lesson_prerequisites.ps1  # Verify prerequisites (Windows)
│   ├── catch_up.sh                     # Auto-copy missing files (Linux/macOS)
│   └── catch_up.ps1                    # Auto-copy missing files (Windows)
└── TROUBLESHOOTING.md          # Common errors & solutions (NEW!)
```

---

## How to Use This Repo

1. **Follow lessons in order.** Each lesson builds on the previous one.
2. **Use checkpoint validation.** Before starting a lesson, run:
   
   **Linux/macOS:**
   ```bash
   ./scripts/check_lesson_prerequisites.sh <lesson_number>
   ```
   
   **Windows:**
   ```powershell
   .\scripts\check_lesson_prerequisites.ps1 <lesson_number>
   ```

3. **Type the code yourself.** Don't just copy-paste. Muscle memory matters.

4. **Stuck? Use the catch-up script:**
   
   **Linux/macOS:**
   ```bash
   ./scripts/catch_up.sh <lesson_number>
   ```
   
   **Windows:**
   ```powershell
   .\scripts\catch_up.ps1 <lesson_number>
   ```

5. **Use the assets folder as a reference.** If you get stuck, the complete implementations are there.
6. **Do the exercises.** They reinforce what you learned and extend it.
7. **Break things intentionally.** Change a test to fail. Drop a ref(). See what happens.
8. **Check the troubleshooting guide** if you encounter errors: [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

---

## Quick Reference: dbt Commands

| Command | What It Does |
|---------|-------------|
| `dbt debug` | Test your connection |
| `dbt deps` | Install packages |
| `dbt seed` | Load CSV files into warehouse |
| `dbt run` | Build all models |
| `dbt build` | Build + test in dependency order |
| `dbt run --select model_name` | Build one model |
| `dbt run --select +model_name` | Build model and all upstream |
| `dbt run --select tag:tagname` | Build models by tag |
| `dbt test` | Run all tests |
| `dbt test --select model_name` | Test one model |
| `dbt show --select model_name` | Preview model output |
| `dbt snapshot` | Run snapshots |
| `dbt compile --select model_name` | See compiled SQL |
| `dbt docs generate` | Build documentation catalog |
| `dbt docs serve` | Launch docs website |
| `dbt ls` | List all resources |
| `dbt clean` | Remove target/ and dbt_packages/ |
| `dbt run --full-refresh` | Force rebuild incremental models |
