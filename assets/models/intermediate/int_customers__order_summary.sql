with customers as (
    select * from {{ ref('stg_customers') }}
),

orders as (
    select * from {{ ref('stg_orders') }}
),

customer_orders as (
    select
        customer_id,
        count(*) as total_orders,
        sum(amount) as lifetime_value,
        min(order_date) as first_order_date,
        max(order_date) as last_order_date
    from orders
    group by customer_id
)

select
    c.customer_id,
    c.first_name,
    c.last_name,
    c.email,
    c.created_at,
    c.is_active,
    coalesce(co.total_orders, 0) as total_orders,
    coalesce(co.lifetime_value, 0) as lifetime_value,
    co.first_order_date,
    co.last_order_date,
    case
        when co.lifetime_value >= 300 then 'gold'
        when co.lifetime_value >= 100 then 'silver'
        else 'bronze'
    end as customer_tier
from customers c
left join customer_orders co on c.customer_id = co.customer_id
