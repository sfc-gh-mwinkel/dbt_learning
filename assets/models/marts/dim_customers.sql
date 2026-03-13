with customer_summary as (
    select * from {{ ref('int_customers__order_summary') }}
)

select
    customer_id,
    first_name,
    last_name,
    email,
    created_at,
    is_active,
    total_orders,
    lifetime_value,
    first_order_date,
    last_order_date,
    customer_tier
from customer_summary
