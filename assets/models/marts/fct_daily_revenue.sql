{{
    config(
        materialized='incremental',
        unique_key='revenue_date',
        incremental_strategy='merge',
        snowflake_warehouse='COMPUTE_WH'
    )
}}

with daily_orders as (
    select
        date_trunc('day', order_date) as revenue_date,
        count(distinct order_id) as order_count,
        count(distinct customer_id) as unique_customers,
        sum(order_amount) as total_revenue
    
    from {{ ref('int_orders_with_payments') }}
    
    {% if is_incremental() %}
        where order_date > (select dateadd(day, -3, max(revenue_date)) from {{ this }})
    {% elif target.name == 'dev' %}
        where order_date >= dateadd(month, -6, current_date())
    {% endif %}
    
    group by 1
)

select
    revenue_date,
    order_count,
    unique_customers,
    total_revenue,
    total_revenue / nullif(order_count, 0) as avg_order_value,
    '{{ target.name }}' as built_in_environment,
    current_timestamp() as last_updated_at

from daily_orders
