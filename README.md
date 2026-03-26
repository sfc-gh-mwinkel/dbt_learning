# dbt Learning Platform

A hands-on, lesson-driven introduction to **dbt-core** with **Snowflake**. Start from zero and build a complete dbt project through structured lessons covering fundamentals to advanced data quality patterns.

> Includes checkpoint validation, catch-up scripts, and lessons through enterprise data quality with `dbt_constraints`.

> **Cross-platform**: Use `python run.py` for an interactive menu that works on any OS. Shell scripts (bash/PowerShell) also included. See [Cross-Platform Commands Guide](CROSS_PLATFORM_COMMANDS.md).

---

## Prerequisites

- Python 3.9+
- A Snowflake account (with a database, warehouse, and role)

---

## Getting Started

### Quick Start (Recommended)

Run the interactive setup wizard:

```bash
# Clone and run wizard
git clone <repo-url> && cd dbt_learning
./scripts/setup_wizard.sh
```

The wizard guides you through Python environment setup, dbt installation, and Snowflake connection configuration.

> **Using an AI assistant?** Point it to [SETUP_WIZARD.md](SETUP_WIZARD.md) for detailed setup guidance.

### Manual Setup: Linux/macOS

```bash
# 1. Clone this repo
git clone <repo-url> && cd dbt_learning

# 2. Create virtual environment and install dbt
python3 -m venv .venv
source .venv/bin/activate
pip install dbt-core dbt-snowflake

# 3. Set up your Snowflake connection
cp profiles.yml.example ~/.dbt/profiles.yml
# Edit ~/.dbt/profiles.yml with your credentials

# 4. Verify connection
dbt debug

# 5. Install packages
dbt deps

# Note: The project includes a generate_schema_name macro that creates
# user-specific schemas (e.g., JSNOW_STAGING). This behavior is explained
# in Lesson 8, but it's active from the start for consistent naming.

# 6. Start with Lesson 1
# Tip: Run checkpoint before each lesson to verify prerequisites
python run.py check 1
# Or: ./scripts/check_lesson_prerequisites.sh 1
```

### Windows (PowerShell)

```powershell
# 1. Clone this repo
git clone <repo-url>
cd dbt_learning

# 2. Create virtual environment and install dbt
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install dbt-core dbt-snowflake

# 3. Set up your Snowflake connection
Copy-Item profiles.yml.example $HOME\.dbt\profiles.yml
# Edit $HOME\.dbt\profiles.yml with your credentials

# 4. Verify connection
dbt debug

# 5. Install packages
dbt deps

# Note: The project includes a generate_schema_name macro that creates
# user-specific schemas (e.g., JSNOW_STAGING). This behavior is explained
# in Lesson 8, but it's active from the start for consistent naming.

# 6. Start with Lesson 1
# Tip: Run checkpoint before each lesson to verify prerequisites
python run.py check 1
# Or: .\scripts\check_lesson_prerequisites.ps1 1
```

---

## Lesson Plan

| # | Lesson | Topics | Key Commands |
|---|--------|--------|-------------|
| 📖 | [Glossary](lessons/00_glossary.md) | Quick reference for dbt terms | — |
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
| 11 | [Enterprise Data Quality](lessons/11_dbt_constraints.md) | dbt_constraints, primary keys, foreign keys, database metadata | `dbt test` |
| 12 | [Production Patterns](lessons/12_production_patterns.md) | Incremental deep-dive, environment configs, source freshness, exposures | `dbt source freshness` |

---

## Concept Index

Find where specific topics are covered:

| Topic | Primary Lesson | Also Mentioned |
|-------|----------------|----------------|
| `ref()` function | 3 | 4, 5, 8 |
| `source()` function | 1 | 2, 3 |
| Jinja templating | 8 | 6, 7, 12 |
| Testing | 5 | 2, 11 |
| Materializations | 3, 4 | 6, 12 |
| Incremental models | 4 | 12 |
| `generate_schema_name` macro | 8 | 1, 6 |
| Snapshots (SCD Type 2) | 7 | — |
| Documentation | 9 | 2 |
| Graph operators (`+`, `@`) | 10 | — |
| Database constraints | 11 | — |
| Source freshness | 12 | 9 |
| Exposures | 12 | — |
| Tags | 6 | 10 |
| Variables (`vars`) | 6 | — |
| Hooks | 6 | — |

---

## Repository Structure

```
dbt_learning/
├── lessons/                    # Scripted lesson files (start here)
│   ├── 00_glossary.md
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
│   ├── 11_dbt_constraints.md
│   └── 12_production_patterns.md
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
├── macros/                     # Custom macros (includes generate_schema_name)
├── tests/                      # Singular test files
├── dbt_project.yml             # Project configuration
├── packages.yml                # Package dependencies
├── profiles.yml.example        # Connection template
├── scripts/                    # Helper scripts
│   ├── setup_wizard.sh               # Interactive setup (Linux/macOS)
│   ├── check_lesson_prerequisites.sh # Verify prerequisites (Linux/macOS)
│   ├── check_lesson_prerequisites.ps1# Verify prerequisites (Windows)
│   ├── catch_up.sh                   # Auto-copy missing files (Linux/macOS)
│   └── catch_up.ps1                  # Auto-copy missing files (Windows)
├── run.py                      # Cross-platform interactive runner (any OS)
├── cleanup_workspace.sh        # Reset local workspace (Linux/macOS)
├── cleanup_workspace.ps1       # Reset local workspace (Windows)
├── SETUP_WIZARD.md             # Detailed setup guide (for AI assistants)
└── TROUBLESHOOTING.md          # Common errors & solutions
```

---

## How to Use This Repo

1. **Follow lessons in order.** Each lesson builds on the previous one.
2. **Use checkpoint validation.** Before starting a lesson, run:
   
   **Any platform (recommended):**
   ```bash
   python run.py check <lesson_number>
   ```
   
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
   
   **Any platform (recommended):**
   ```bash
   python run.py catchup <lesson_number>
   ```
   
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
