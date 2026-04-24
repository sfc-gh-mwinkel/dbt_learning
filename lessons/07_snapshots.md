# Lesson 7: Snapshots & SCD Type 2

## Learning Objectives

By the end of this lesson you will be able to:
- Understand why snapshots exist (tracking changes over time)
- Write a snapshot using the `check` strategy
- Write a snapshot using the `timestamp` strategy
- Run snapshots and understand the output columns
- Know when to use snapshots vs. incremental models

---

## Prerequisites

- **Completed:** Lessons 1-6
- **Models exist:** All staging models, particularly `stg_raw__orders`
- **Seeds loaded:** `orders.csv` in `seeds/`

**Catch up:** If you're missing prerequisites, run:
```bash
python run.py catchup 7
# Or: ./scripts/catch_up.sh 7
```

---

## 7.1 The Problem: Data Changes

Consider an order with status `pending`. Tomorrow it becomes `shipped`. Next week, `completed`. If you only have a staging model, you see the _current_ status. The history is lost.

**Snapshots** solve this by recording every change as a new row, creating a full history (SCD Type 2).

```
Before snapshot:
| order_id | status    |
|----------|-----------|
| 1001     | completed |   <-- Was it always completed? We don't know.

After snapshot:
| order_id | status    | dbt_valid_from | dbt_valid_to   |
|----------|-----------|----------------|----------------|
| 1001     | pending   | 2024-02-01     | 2024-02-05     |
| 1001     | shipped   | 2024-02-05     | 2024-02-08     |
| 1001     | completed | 2024-02-08     | NULL           |  <-- Current
```

---

## 7.2 Snapshot Strategies

dbt supports two strategies for detecting changes:

### Check Strategy

Monitors specific columns for changes. If any watched column changes, a new snapshot row is created.

> **Note:** Snapshots use a special Jinja block syntax (`{% snapshot %}...{% endsnapshot %}`). This is different from the `{{ }}` expressions you've seen before. The `{% %}` syntax executes statements rather than outputting values. Jinja is covered in depth in Lesson 8 — for now, follow the pattern shown below.

```sql
-- {% snapshot %} block: snapshots use a special Jinja block (not a standard model).
-- They live in the snapshots/ directory and run via 'dbt snapshot', not 'dbt run'.
{% snapshot snap_orders %}

{{
    config(
        -- target_database/schema: where the snapshot table is created.
        -- generate_schema_name('snapshots') produces a user-prefixed schema
        -- (e.g. MWINKEL_SNAPSHOTS) consistent with the rest of the project.
        target_database=target.database,
        target_schema=generate_schema_name('snapshots'),

        -- unique_key: the primary key of the source table. dbt uses this
        -- to match rows between runs and detect changes.
        unique_key='order_id',

        -- strategy='check': compares the current values of check_cols against
        -- the previously snapshotted values. If any column changed, dbt closes
        -- the old row (sets dbt_valid_to) and inserts a new one.
        strategy='check',

        -- check_cols: only monitor these columns for changes. Watching fewer
        -- columns is more efficient and avoids capturing irrelevant updates.
        check_cols=['status', 'amount']
    )
}}

-- Snapshot the raw source directly — not a staging model.
-- This captures changes at the earliest point in the pipeline.
select * from {{ source('raw', 'orders') }}

{% endsnapshot %}
```

### Timestamp Strategy

Uses an `updated_at` column to detect changes. More efficient than `check` because it only compares timestamps.

```sql
{% snapshot snap_customers %}

{{
    config(
        target_database=target.database,
        target_schema=generate_schema_name('snapshots'),
        unique_key='customer_id',

        -- strategy='timestamp': instead of comparing column values, dbt checks
        -- if updated_at has changed since the last snapshot run. This is more
        -- efficient than 'check' because it only compares one column.
        strategy='timestamp',
        updated_at='updated_at'
    )
}}

select * from {{ source('raw', 'customers') }}

{% endsnapshot %}
```

**When to use:** When your source data has a reliable `updated_at` column that changes whenever a row is modified.

---

## 7.3 Snapshot Configuration

| Config | Purpose | Example |
|--------|---------|---------|
| `unique_key` | Primary key of the source table | `'order_id'` |
| `strategy` | How to detect changes | `'check'` or `'timestamp'` |
| `check_cols` | Columns to monitor (check strategy) | `['status', 'amount']` |
| `updated_at` | Timestamp column (timestamp strategy) | `'updated_at'` |
| `target_schema` | Where to store snapshot table | `generate_schema_name('snapshots')` |
| `target_database` | Database for snapshot table | `target.database` |

---

## 7.4 Create Your First Snapshot

Create `snapshots/snap_orders.sql`:

```sql
{% snapshot snap_orders %}

{{
    config(
        target_database=target.database,
        target_schema=generate_schema_name('snapshots'),
        unique_key='order_id',
        strategy='check',
        check_cols=['status', 'amount']
    )
}}

select * from {{ source('raw', 'orders') }}

{% endsnapshot %}
```

Run it:

```bash
dbt snapshot
```

---

## 7.5 Understanding Snapshot Output

After running, query the snapshot table. It has extra columns added by dbt:

| Column | Purpose |
|--------|---------|
| `dbt_scd_id` | Unique hash for each snapshot row |
| `dbt_updated_at` | When dbt captured this version |
| `dbt_valid_from` | When this version became active |
| `dbt_valid_to` | When this version was superseded (NULL = current) |

**To find current records:**

```sql
select * from snap_orders where dbt_valid_to is null
```

**To find the history of a specific order:**

```sql
select * from snap_orders where order_id = 1001 order by dbt_valid_from
```

---

## 7.6 Simulating Changes

To see snapshots in action, you need to change source data and re-run.

Step 1: Run the initial snapshot:
```bash
dbt snapshot
```

Step 2: Modify a seed value. Open `seeds/orders.csv` and change order 1009's status from `pending` to `shipped`.

Step 3: Reload seeds and re-snapshot:
```bash
dbt seed
dbt snapshot
```

Step 4: Query the snapshot table. Order 1009 should now have two rows:
- One with `status = 'pending'` and a `dbt_valid_to` timestamp
- One with `status = 'shipped'` and `dbt_valid_to = NULL`

---

## 7.7 Snapshots vs. Incremental Models

| Feature | Snapshot | Incremental Model |
|---------|----------|-------------------|
| Purpose | Track changes over time (SCD) | Efficiently process new data |
| Output | Multiple rows per entity | One row per entity (latest) |
| Runs with | `dbt snapshot` | `dbt run` |
| Lives in | `snapshots/` folder | `models/` folder |
| Use case | Audit trail, historical analysis | Large growing datasets |

---

## 7.8 Snapshot Best Practices

1. **Snapshot raw sources**, not transformed models. Changes are most meaningful at the source level.
2. **Choose check_cols carefully.** Only watch columns that represent meaningful business changes.
3. **Use `check_cols='all'`** if you want to capture any change, but be aware this is slower.
4. **Run snapshots on a schedule.** Snapshots only capture changes when `dbt snapshot` runs. If data changes twice between runs, you only see the final state.
5. **Don't drop and recreate snapshot tables.** They accumulate history. Dropping them loses all historical data.

---

## 7.9 Exercises

1. Copy the snapshot asset: `cp assets/snapshots/snap_orders.sql snapshots/`
2. Run `dbt snapshot` and verify the table was created
3. Modify `seeds/orders.csv` — change order 1009 status from `pending` to `shipped`
4. Run `dbt seed && dbt snapshot`
5. Query the snapshot table and find the two rows for order 1009
6. (Bonus) Create a second snapshot for `customers` using the `check` strategy on `is_active`

---

## 7.10 Key Takeaways

| Concept | What You Learned |
|---------|-----------------|
| Snapshots | Track row-level changes over time (SCD Type 2) |
| `check` strategy | Monitors specific columns for value changes |
| `timestamp` strategy | Uses an `updated_at` column to detect changes |
| `dbt_valid_from/to` | Time range when a snapshot row was current |
| `dbt snapshot` | Command to run all snapshots |
| Best practice | Snapshot raw sources; run on a schedule |

---

## Further Reading

- [Snapshots](https://docs.getdbt.com/docs/build/snapshots) - Complete snapshot documentation
- [Snapshot configurations](https://docs.getdbt.com/reference/snapshot-configs) - All snapshot config options
- [Snapshot meta-fields](https://docs.getdbt.com/reference/resource-configs/snapshot_meta_fields) - Understanding dbt_valid_from, dbt_valid_to
- [SCD Type 2](https://docs.getdbt.com/terms/scd) - Slowly changing dimensions explained

---

**Previous:** [Lesson 6 - dbt_project.yml Deep Dive](06_dbt_project_yml.md) | **Next:** [Lesson 8 - Writing Macros](08_macros.md)
