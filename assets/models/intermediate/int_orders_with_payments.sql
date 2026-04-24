with orders as (
    select * from {{ ref('stg_raw__orders') }}
),

payments as (
    select * from {{ ref('stg_raw__payments') }}
)

select
    o.order_id,
    o.customer_id,
    o.order_date,
    o.status,
    o.amount as order_amount,
    p.payment_id,
    p.payment_method,
    p.amount as paid_amount,
    p.payment_date,
    case
        when p.payment_id is not null then true
        else false
    end as is_paid
from orders o
left join payments p on o.order_id = p.order_id
