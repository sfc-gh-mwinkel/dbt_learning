# dbt Glossary

Quick reference for common dbt and data engineering terms used throughout these lessons.

---

## Core dbt Concepts

| Term | Definition | First Introduced |
|------|------------|------------------|
| **Model** | A SQL `SELECT` statement saved as a `.sql` file that dbt transforms into a table or view | Lesson 1 |
| **Source** | A raw table that exists outside dbt (declared in `sources.yml`) | Lesson 1 |
| **Seed** | A CSV file that dbt loads directly into your warehouse | Lesson 1 |
| **ref()** | Jinja function that references another dbt model, creating a dependency | Lesson 3 |
| **source()** | Jinja function that references a declared source table | Lesson 1 |
| **Materialization** | How dbt builds a model (view, table, incremental, ephemeral) | Lesson 3 |
| **DAG** | Directed Acyclic Graph — the dependency tree of your models | Lesson 3 |
| **Snapshot** | A dbt feature that tracks row-level changes over time (SCD Type 2) | Lesson 7 |
| **Macro** | A reusable Jinja function defined in the `macros/` directory | Lesson 8 |
| **Test** | A SQL query that validates data quality (returns rows on failure) | Lesson 2 |
| **Package** | A collection of macros and models you can install (e.g., `dbt_utils`) | Lesson 5 |

---

## Jinja Templating

| Syntax | Purpose | Example |
|--------|---------|---------|
| `{{ }}` | Output an expression | `{{ ref('stg_raw__orders') }}` |
| `{% %}` | Execute a statement (control flow) | `{% if is_incremental() %}` |
| `{# #}` | Comment (not in compiled SQL) | `{# This is a comment #}` |

**Covered in depth:** Lesson 8

---

## Materialization Types

| Type | Creates | Use Case |
|------|---------|----------|
| **view** | SQL view | Development, small datasets |
| **table** | Physical table | Dimensions, frequently queried models |
| **incremental** | Table with append/merge logic | Large fact tables that grow over time |
| **ephemeral** | Nothing (inline CTE) | Internal models not queried directly |

**Covered in depth:** Lessons 3, 4, 12

---

## Layer Architecture

| Layer | Prefix | Purpose |
|-------|--------|---------|
| **Staging** | `stg_` | Clean, cast, rename raw data. No joins. |
| **Intermediate** | `int_` | Join and enrich staging models. Business logic. |
| **Marts** | `dim_`, `fct_` | Business-ready tables for end users |

**Covered in depth:** Lessons 3, 4

---

## Data Modeling Terms

| Term | Definition |
|------|------------|
| **Dimension** | A table describing business entities (customers, products). Changes slowly. |
| **Fact** | A table recording business events (orders, transactions). Grows over time. |
| **SCD Type 2** | Slowly Changing Dimension pattern that tracks full history with valid_from/valid_to dates |
| **CTE** | Common Table Expression — a named subquery using `WITH ... AS (...)` |
| **Primary Key** | Column(s) that uniquely identify each row |
| **Foreign Key** | Column that references another table's primary key |

---

## Common Commands

| Command | Purpose |
|---------|---------|
| `dbt debug` | Test your Snowflake connection |
| `dbt deps` | Install packages from `packages.yml` |
| `dbt seed` | Load CSV files into warehouse |
| `dbt run` | Build models |
| `dbt test` | Run data quality tests |
| `dbt build` | Run + test in dependency order |
| `dbt snapshot` | Run snapshots (SCD Type 2) |
| `dbt compile` | Generate SQL without executing |
| `dbt docs generate` | Build documentation catalog |
| `dbt docs serve` | Launch local docs website |

---

## Graph Operators

| Operator | Meaning | Example |
|----------|---------|---------|
| `+model` | Model and all upstream dependencies | `dbt run --select +dim_customers` |
| `model+` | Model and all downstream dependents | `dbt run --select stg_raw__orders+` |
| `+model+` | Model and all connected models | `dbt run --select +fct_orders+` |
| `@model` | Model, ancestors, and ancestor descendants | `dbt run --select @int_orders` |

**Covered in depth:** Lesson 10

---

## File Types

| Extension | Purpose | Location |
|-----------|---------|----------|
| `.sql` | Model definitions | `models/` |
| `.yml` | Configuration, tests, docs | `models/`, root |
| `.csv` | Seed data | `seeds/` |
| `.md` | Doc blocks | `models/` |

---

**Back to:** [README](../README.md)
