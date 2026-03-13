# Lesson 9: Documentation & dbt docs

## Learning Objectives

By the end of this lesson you will be able to:
- Write model and column descriptions in YAML
- Use doc blocks for rich, reusable documentation
- Generate and serve the dbt documentation site
- Explore lineage in the DAG viewer
- Understand source freshness reporting

---

## Prerequisites

- **Completed:** Lessons 1-8
- **Models exist:** Full project with staging, intermediate, and marts
- **YML files:** Model documentation files (`.yml`) for key models

**Catch up:** If you're missing prerequisites, run:
```bash
./scripts/catch_up.sh 9
```

---

## 9.1 Why Document?

Documentation answers "what does this table mean?" for anyone who encounters your models — analysts, new team members, or future you. In dbt, documentation is:

- **Written alongside code** (not in a separate wiki that goes stale)
- **Auto-generated** into a searchable website
- **Includes lineage** so you can trace data flow visually

---

## 9.2 Descriptions in YAML

You've already been adding descriptions in your model `.yml` files:

```yaml
# models/marts/dim_customers.yml
version: 2

models:
  - name: dim_customers
    description: "Customer dimension with lifetime value and tier classification"
    columns:
      - name: customer_id
        description: "Primary key for customers"
      - name: customer_tier
        description: "Customer value tier based on lifetime spend: gold (>=$300), silver (>=$100), bronze (<$100)"
```

**Best practices for descriptions:**
- Describe what the model represents, not how it's built
- For columns, include business meaning, units, and valid values
- For foreign keys, say which model/column they reference

---

## 9.3 Doc Blocks

For longer descriptions or reusable text, use **doc blocks**. Create a file `models/docs.md`:

```markdown
{% docs customer_tier %}

A classification of customers based on their lifetime purchase value:

| Tier | Threshold | Description |
|------|-----------|-------------|
| Gold | >= $300 | High-value, priority customers |
| Silver | >= $100 | Regular, engaged customers |
| Bronze | < $100 | New or low-activity customers |

Tier is recalculated on every full refresh.

{% enddocs %}

{% docs order_status %}

The current fulfillment state of an order:

- **completed**: Order delivered to customer
- **shipped**: Order dispatched, in transit
- **pending**: Order placed, awaiting processing
- **returned**: Customer returned the order
- **cancelled**: Order cancelled before shipment

{% enddocs %}
```

Reference doc blocks in YAML:

```yaml
columns:
  - name: customer_tier
    description: '{{ doc("customer_tier") }}'
  - name: status
    description: '{{ doc("order_status") }}'
```

> **Key concept:** Doc blocks support full Markdown (tables, lists, bold). They keep your YAML clean while allowing rich documentation.

---

## 9.4 Generating the Docs Site

Run two commands:

```bash
dbt docs generate
dbt docs serve
```

- `dbt docs generate` creates a `target/catalog.json` with all metadata
- `dbt docs serve` launches a local web server (usually http://localhost:8080)

The site includes:
- **Model list** with descriptions and column details
- **Source list** with freshness status
- **DAG viewer** showing full lineage (click the graph icon in the bottom-right)

---

## 9.5 The DAG Viewer

The lineage graph is one of dbt's most powerful features. In the docs site, click the blue graph icon to see:

- All models and their dependencies
- Color-coded by resource type (sources, models, tests, snapshots)
- Clickable nodes that show model details

You can filter the graph:
- `+dim_customers` — show dim_customers and all its upstream dependencies
- `dim_customers+` — show dim_customers and everything downstream
- `+dim_customers+` — show everything connected to dim_customers

---

## 9.6 Source Freshness

Source freshness monitoring helps detect when upstream data pipelines are delayed or broken. If your sources have `loaded_at_field` and `freshness` configured, you can check freshness:

```bash
dbt source freshness
```

This queries each source table to check when data was last loaded. Results appear in the docs site under the Sources tab.

```yaml
sources:
  - name: raw
    freshness:
      warn_after:
        count: 24
        period: hour
      error_after:
        count: 48
        period: hour
    loaded_at_field: _etl_loaded_at
```

> **Note:** Source freshness requires a timestamp column (`loaded_at_field`) that indicates when rows were loaded. Our seed tables don't have this column, so freshness checks won't work on them. This feature is designed for production data pipelines where ETL processes add load timestamps. In Lesson 12, we cover how to set this up properly.

---

## 9.7 Exercises

1. Add descriptions to all columns in your mart model `.yml` files (`dim_customers.yml`, `fct_orders.yml`)
2. Create `models/docs.md` with doc blocks for `customer_tier` and `order_status`
3. Reference the doc blocks in your schema YAML using `'{{ doc("customer_tier") }}'`
4. Run `dbt docs generate && dbt docs serve`
5. Explore the DAG viewer — find `dim_customers` and trace its full lineage back to sources
6. Try the graph filter: type `+fct_orders` in the search bar

---

## 9.8 Key Takeaways

| Concept | What You Learned |
|---------|-----------------|
| `description` | Plain-text docs in YAML for models and columns |
| Doc blocks | Markdown-rich, reusable documentation in `.md` files |
| `{{ doc() }}` | References a doc block by name |
| `dbt docs generate` | Builds the documentation catalog |
| `dbt docs serve` | Launches a local docs website |
| DAG viewer | Visual lineage graph of your project |
| Source freshness | Monitors when source data was last loaded |

---

## Further Reading

- [Documentation](https://docs.getdbt.com/docs/build/documentation) - Complete documentation guide
- [Doc blocks](https://docs.getdbt.com/docs/build/documentation#using-docs-blocks) - Creating reusable doc blocks
- [dbt docs commands](https://docs.getdbt.com/reference/commands/cmd-docs) - Generate and serve commands
- [Source freshness](https://docs.getdbt.com/docs/build/sources#snapshotting-source-data-freshness) - Monitoring data freshness

---

**Previous:** [Lesson 8 - Writing Macros](08_macros.md) | **Next:** [Lesson 10 - Graph Operators & dbt build](10_graph_operators.md)
