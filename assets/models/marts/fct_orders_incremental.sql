{{
    config(
        materialized='incremental',
        unique_key='order_id',
        incremental_strategy='merge'
    )
}}

with source_data as (
    select
        o.order_id,
        o.customer_id,
        o.order_date,
        o.status,
        p.payment_method,
        p.amount as total_amount,
        current_timestamp() as loaded_at
    
    from {{ ref('stg_orders') }} o
    left join {{ ref('stg_payments') }} p
        on o.order_id = p.order_id
)

select * from source_data

{% if is_incremental() %}
    where order_date > (select max(order_date) from {{ this }})
{% endif %}
