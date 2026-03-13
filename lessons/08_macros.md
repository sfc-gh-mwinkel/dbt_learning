# Lesson 8: Writing Macros

## Learning Objectives

By the end of this lesson you will be able to:
- Understand Jinja2 basics (variables, control flow, expressions)
- Write simple macros to reduce code repetition
- Use macros with arguments
- Call macros inside your models
- Know when macros are and aren't appropriate

---

## Prerequisites

- **Completed:** Lessons 1-7
- **Recommended:** Read through earlier lessons to see Jinja syntax you've already used (`{{ ref() }}`, `{{ source() }}`, `{{ config() }}`)

**Catch up:** If you're missing prerequisites, run:
```bash
./scripts/catch_up.sh 8
```

---

## 8.1 What is Jinja?

dbt uses **Jinja2** as its templating language. Everything between `{{ }}`, `{% %}`, or `{# #}` is Jinja:

| Syntax | Purpose | Example |
|--------|---------|---------|
| `{{ }}` | Output an expression | `{{ ref('stg_orders') }}` |
| `{% %}` | Execute a statement | `{% if is_incremental() %}` |
| `{# #}` | Comment (not in compiled SQL) | `{# This is a comment #}` |

You've already been using Jinja: `{{ ref() }}`, `{{ source() }}`, `{{ config() }}`, and `{{ this }}` are all Jinja expressions.

---

## 8.2 Jinja Basics

### Variables

```sql
-- {% set %} creates a Jinja variable at compile time.
-- This value exists only during compilation — it never reaches Snowflake.
-- Use it to avoid repeating a column name or value across the query.
{% set my_column = 'customer_id' %}

select {{ my_column }} from {{ ref('stg_customers') }}

-- Compiles to: select customer_id from ...
```

### Lists and Loops

```sql
-- {% set %} can also create lists — useful for generating repetitive SQL.
{% set statuses = ['completed', 'shipped', 'pending'] %}

select
    order_id,
    -- {% for %} iterates over the list, generating one SQL expression per item.
    -- This avoids writing three nearly identical sum(case...) lines by hand.
    {% for status in statuses %}
    sum(case when status = '{{ status }}' then 1 else 0 end) as {{ status }}_count
    -- loop.last is a built-in Jinja variable: true on the final iteration.
    -- We use it to suppress the trailing comma after the last column,
    -- which would cause a SQL syntax error.
    {% if not loop.last %},{% endif %}
    {% endfor %}
from {{ ref('stg_orders') }}
group by order_id
```

Compiles to:

```sql
select
    order_id,
    sum(case when status = 'completed' then 1 else 0 end) as completed_count,
    sum(case when status = 'shipped' then 1 else 0 end) as shipped_count,
    sum(case when status = 'pending' then 1 else 0 end) as pending_count
from ...
group by order_id
```

> **Key concept:** `loop.last` is a built-in Jinja variable that is `true` on the final iteration. Use it to avoid trailing commas.

### Conditional Logic

```sql
-- target.name is a context variable from profiles.yml (your target name, e.g. 'dev').
-- Conditional Jinja lets you write environment-aware SQL: limit rows in dev to
-- speed up development, but process everything in production.
{% if target.name == 'dev' %}
    select * from {{ ref('stg_orders') }} limit 100
{% else %}
    select * from {{ ref('stg_orders') }}
{% endif %}
```

---

## 8.3 Your First Macro

Macros are reusable Jinja functions. They live in the `macros/` directory.

### Example: clean_string

Create `macros/clean_string.sql`:

```sql
-- {% macro %} defines a reusable Jinja function. It accepts arguments
-- and returns a SQL fragment that gets inlined wherever you call it.
-- Macros live in the macros/ directory and are available project-wide.
{% macro clean_string(column_name) %}
    trim(lower({{ column_name }}))
{% endmacro %}
```

Use it in a model:

```sql
-- Calling a macro: {{ macro_name(args) }} in a model.
-- At compile time, dbt replaces the macro call with its output.
-- The compiled SQL contains only standard SQL — no Jinja.
select
    customer_id,
    {{ clean_string('email') }} as email,
    {{ clean_string('first_name') }} as first_name
from {{ source('raw', 'customers') }}
```

Compiles to:

```sql
select
    customer_id,
    trim(lower(email)) as email,
    trim(lower(first_name)) as first_name
from ...
```

---

## 8.4 Macros with Multiple Arguments

### Example: classify_tier

Create `macros/classify_tier.sql`:

```sql
-- Multiple arguments make macros flexible and reusable across different models.
-- Here the threshold values are parameters, so the same macro works for
-- customer tiers, product tiers, or any other tiering logic.
{% macro classify_tier(value_column, high_threshold, mid_threshold) %}
    case
        when {{ value_column }} >= {{ high_threshold }} then 'gold'
        when {{ value_column }} >= {{ mid_threshold }} then 'silver'
        else 'bronze'
    end
{% endmacro %}
```

Use it in `dim_customers`:

```sql
select
    customer_id,
    first_name,
    last_name,
    lifetime_value,
    {{ classify_tier('lifetime_value', 300, 100) }} as customer_tier
from {{ ref('int_customers__order_summary') }}
```

Now if tier logic changes, you update it in one place.

---

## 8.5 Overriding dbt Behavior: generate_schema_name

One of the most common uses of macros is overriding dbt's built-in behavior. Remember from Lesson 6 that dbt concatenates schemas by default (`public_staging` instead of `staging`)?

The fix is a macro with a special name that dbt calls automatically:

Create `macros/generate_schema_name.sql`:

```sql
-- This macro has a special name that dbt recognizes. When defined in your
-- project, it overrides dbt's built-in version. dbt calls it automatically
-- for every model to determine which schema to use.
-- The {%- -%} (with dashes) strips whitespace so the output is clean.
{% macro generate_schema_name(custom_schema_name, node) -%}
    {%- if custom_schema_name is none -%}
        {{ target.schema }}
    {%- else -%}
        -- The | trim filter removes any accidental whitespace from the
        -- YAML config value. Without it, '+schema: staging ' (trailing space)
        -- would create a schema named 'staging '.
        {{ custom_schema_name | trim }}
    {%- endif -%}
{%- endmacro %}
```

**How it works:** dbt calls `generate_schema_name()` for every model. When you define this macro in your project, your version overrides the built-in one. Now `+schema: staging` produces exactly `staging`, not `public_staging`.

> **Key concept:** dbt has several "dispatch" macros you can override: `generate_schema_name`, `generate_alias_name`, `generate_database_name`. These control where models are materialized.

---

## 8.6 Macros with Default Arguments

```sql
-- Default argument: precision=2 means callers can omit it.
-- This reduces boilerplate while still allowing customization when needed.
{% macro cents_to_dollars(column_name, precision=2) %}
    round(cast({{ column_name }} as decimal(10, {{ precision }})) / 100, {{ precision }})
{% endmacro %}
```

Call with or without the optional argument:

```sql
select
    {{ cents_to_dollars('amount_cents') }} as amount,           -- Uses default precision=2
    {{ cents_to_dollars('amount_cents', 4) }} as precise_amount  -- Override to 4
from {{ ref('stg_payments') }}
```

---

## 8.7 Seeing Compiled SQL

To verify what your macros produce, compile without running:

```bash
dbt compile --select dim_customers
```

Then check the output:

```bash
cat target/compiled/dbt_learning/models/marts/dim_customers.sql
```

This shows the final SQL after all Jinja is resolved. Essential for debugging.

---

## 8.8 Built-in Macros and Variables

dbt provides several built-in macros and context variables:

| Expression | Returns |
|-----------|---------|
| `{{ ref('model') }}` | Fully qualified table name |
| `{{ source('src', 'tbl') }}` | Fully qualified source table name |
| `{{ this }}` | Current model's table reference |
| `{{ target.name }}` | Target name from profiles.yml (e.g., `dev`) |
| `{{ target.schema }}` | Target schema |
| `{{ target.database }}` | Target database |
| `{{ var('name') }}` | Project variable from dbt_project.yml |
| `{{ is_incremental() }}` | True if model is incremental and table exists |
| `{{ dbt_utils.star() }}` | Select all columns from a relation |

---

## 8.9 When to Use Macros

**Good use cases:**
- Repeated SQL patterns (cleaning, casting, tier logic)
- Environment-specific logic (`dev` vs `prod`)
- Dynamic SQL generation (looping over columns)
- Custom schema/alias generation

**Avoid macros when:**
- The logic is only used once (just write SQL)
- The macro makes the code harder to read
- Simple SQL would be clearer

> **Rule of thumb:** If you copy-paste the same SQL snippet 3+ times, make it a macro.

---

## 8.10 Exercises

1. Copy the macro assets: `cp assets/macros/*.sql macros/`
2. Run `dbt compile --select dim_customers` and inspect the compiled SQL
3. Modify `stg_customers` to use `{{ clean_string('email') }}` for the email column
4. Modify `dim_customers` to use `{{ classify_tier('lifetime_value', 300, 100) }}` for the tier column
5. Verify that `generate_schema_name` is working: run `dbt run --select stg_customers` and check which schema the view was created in
6. Write a new macro `macros/safe_divide.sql` that divides two columns and returns 0 when the denominator is 0:
   ```sql
   {% macro safe_divide(numerator, denominator) %}
       case when {{ denominator }} = 0 then 0
            else {{ numerator }} / {{ denominator }}
       end
   {% endmacro %}
   ```
7. Run `dbt run` and verify everything still works

---

## 8.11 Key Takeaways

| Concept | What You Learned |
|---------|-----------------|
| Jinja `{{ }}` | Output expressions (ref, source, macros) |
| Jinja `{% %}` | Control flow (set, for, if) |
| Macros | Reusable Jinja functions in `macros/` directory |
| Arguments | Macros accept parameters; can have defaults |
| `dbt compile` | Preview compiled SQL without running |
| `loop.last` | Avoids trailing commas in for loops |
| When to use | 3+ repetitions of the same pattern |
| `generate_schema_name` | Override dbt's default schema concatenation |

---

**Previous:** [Lesson 7 - Snapshots & SCD Type 2](07_snapshots.md) | **Next:** [Lesson 9 - Documentation & dbt docs](09_documentation.md)
