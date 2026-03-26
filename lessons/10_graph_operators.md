# Lesson 10: Graph Operators & dbt build

## Learning Objectives

By the end of this lesson you will be able to:
- Use graph operators (`+`, `@`) to select models and their dependencies
- Understand the difference between `dbt run`, `dbt test`, and `dbt build`
- Use `--full-refresh` for incremental models
- Combine selectors for precise control
- Build a practical workflow for daily development

---

## Prerequisites

- **Completed:** Lessons 1-9
- **Models exist:** Full project with multiple layers
- **Verified:** `dbt build` completes successfully

**Catch up:** If you're missing prerequisites, run:
```bash
python run.py catchup 10
# Or: ./scripts/catch_up.sh 10
```

---

## 10.1 The Selection Problem

As your project grows, you don't always want to run everything. You need to:
- Rebuild one model **and** everything downstream of it
- Test only the models you just changed
- Run a specific layer or tag

dbt's **graph operators** solve this.

---

## 10.2 Graph Operators

### The `+` Operator (Ancestors and Descendants)

```bash
# Run dim_customers AND everything it depends on (upstream)
dbt run --select +dim_customers

# Run dim_customers AND everything that depends on it (downstream)
dbt run --select dim_customers+

# Run dim_customers AND all upstream AND all downstream
dbt run --select +dim_customers+
```

| Syntax | Meaning |
|--------|---------|
| `+model` | Model and all **ancestors** (upstream) |
| `model+` | Model and all **descendants** (downstream) |
| `+model+` | Model and **all connected** models |
| `model` | Just this one model |

### Limiting Depth

Add a number to limit how far the graph traverses:

```bash
# dim_customers and its direct parents only (1 level up)
dbt run --select 1+dim_customers

# dim_customers and 2 levels of descendants
dbt run --select dim_customers+2
```

---

## 10.3 The `@` Operator (At-Selector)

The `@` operator selects a model, its ancestors, AND the descendants of its ancestors. This is useful when you change an intermediate model and want to rebuild everything affected:

```bash
# If you changed int_orders_with_payments:
dbt run --select @int_orders_with_payments
```

This selects:
- `int_orders_with_payments` itself
- Its parents (`stg_orders`, `stg_payments`)
- Its children (`fct_orders`)
- AND any other children of its parents

---

## 10.4 Combining Selectors

### Multiple Models

```bash
# Run two specific models
dbt run --select dim_customers fct_orders

# Run two models and all their upstream dependencies
dbt run --select +dim_customers +fct_orders
```

### Set Operations

```bash
# Union: models in staging OR tagged "daily"
dbt run --select staging tag:daily

# Intersection: models in staging AND tagged "daily"
dbt run --select staging,tag:daily

# Exclusion: all marts EXCEPT dim_customers
dbt run --select marts --exclude dim_customers
```

### By Resource Type

```bash
dbt ls --select resource_type:model     # List all models
dbt ls --select resource_type:test      # List all tests
dbt ls --select resource_type:snapshot  # List all snapshots
dbt ls --select resource_type:source    # List all sources
```

---

## 10.5 dbt build vs. dbt run + dbt test

`dbt build` combines `dbt run` and `dbt test` into a single command with a key advantage: **it runs tests immediately after each model**, not after all models.

```bash
# Traditional approach:
dbt run                    # Build all models, then...
dbt test                   # Test all models

# Better approach:
dbt build                  # Build model A → test A → build model B → test B → ...
```

**Why this matters:** If `stg_orders` has a data quality issue, `dbt build` catches it _before_ building downstream models like `fct_orders`. With `dbt run && dbt test`, you'd build everything first, then discover the issue.

```bash
dbt build                              # Build and test everything
dbt build --select staging             # Build and test staging only
dbt build --select +dim_customers      # Build and test dim_customers + upstream
```

`dbt build` also runs seeds and snapshots in the correct order.

---

## 10.6 --full-refresh

For incremental models, `dbt run` normally only processes new rows. To force a complete rebuild:

```bash
# Rebuild one incremental model from scratch
dbt run --select fct_orders --full-refresh

# Rebuild everything from scratch
dbt run --full-refresh

# Build + test with full refresh
dbt build --full-refresh
```

**When to use `--full-refresh`:**
- You changed the SQL logic of an incremental model
- You added or removed columns
- You need to backfill historical data
- Something went wrong and you want a clean slate

---

## 10.7 Practical Development Workflow

Here's a typical workflow when developing dbt models:

```bash
# 1. Start work: load seeds and install packages
dbt deps
dbt seed

# 2. Build and test your specific changes
dbt build --select +my_new_model+

# 3. Before committing: build and test everything
dbt build

# 4. If you changed incremental logic:
dbt build --select my_incremental_model --full-refresh

# 5. Run snapshots if source data changed
dbt snapshot

# 6. Generate fresh docs
dbt docs generate
```

---

## 10.8 Quick Reference: Selection Syntax

| Command | What It Selects |
|---------|----------------|
| `--select model_name` | One model |
| `--select +model_name` | Model + all upstream |
| `--select model_name+` | Model + all downstream |
| `--select +model_name+` | Model + all connected |
| `--select 1+model_name` | Model + 1 level upstream |
| `--select @model_name` | Model + ancestors + ancestor descendants |
| `--select tag:name` | All models with a tag |
| `--select staging` | All models in staging folder |
| `--select source:raw` | All sources named "raw" |
| `--exclude model_name` | Remove from selection |
| `--select a,b` | Intersection (a AND b) |
| `--select a b` | Union (a OR b) |

---

## 10.9 Exercises

1. Run `dbt ls --select +fct_orders` and observe the full list of upstream models
2. Run `dbt ls --select fct_orders+` — what depends on `fct_orders`?
3. Run `dbt build --select staging` — observe how tests run after each model
4. Try `dbt run --select marts --exclude dim_customers` to skip one model
5. If you made `fct_orders` incremental in Lesson 4, run `dbt run --select fct_orders --full-refresh`
6. Run `dbt build` for the full project and verify all tests pass

---

## 10.10 Key Takeaways

| Concept | What You Learned |
|---------|-----------------|
| `+model` | Select model and all ancestors |
| `model+` | Select model and all descendants |
| `@model` | Select model, ancestors, and ancestor descendants |
| `dbt build` | Combines run + test; tests each model immediately |
| `--full-refresh` | Forces complete rebuild of incremental models |
| `--exclude` | Remove specific models from a selection |
| `,` (comma) | Intersection: both conditions must match |
| ` ` (space) | Union: either condition matches |

---

## Further Reading

- [Node selection syntax](https://docs.getdbt.com/reference/node-selection/syntax) - Complete selection syntax guide
- [Graph operators](https://docs.getdbt.com/reference/node-selection/graph-operators) - +, @, and other operators
- [dbt build](https://docs.getdbt.com/reference/commands/build) - Combined run and test command
- [YAML selectors](https://docs.getdbt.com/reference/node-selection/yaml-selectors) - Reusable selector definitions

---

## What's Next?

You've completed the core dbt curriculum! Continue to **Lesson 11** to learn about enterprise data quality with database-enforced constraints, and **Lesson 12** for production patterns like advanced incremental strategies and exposures.

You now have the skills to:
- Set up and configure a dbt project on Snowflake
- Build a layered data model (staging, intermediate, marts)
- Test, document, and snapshot your data
- Write macros for reusable logic
- Navigate your DAG with graph operators

---

**Previous:** [Lesson 9 - Documentation & dbt docs](09_documentation.md) | **Next:** [Lesson 11 - Enterprise Data Quality](11_dbt_constraints.md)
