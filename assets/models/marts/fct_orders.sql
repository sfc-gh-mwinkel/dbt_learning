with orders_with_payments as (
    select * from {{ ref('int_orders_with_payments') }}
),

order_items as (
    select * from {{ ref('int_order_items_with_products') }}
),

order_line_summary as (
    select
        order_id,
        count(*) as total_line_items,
        sum(line_total) as line_items_total
    from order_items
    group by order_id
)

select
    owp.order_id,
    owp.customer_id,
    owp.order_date,
    owp.status,
    owp.order_amount,
    owp.payment_method,
    owp.is_paid,
    coalesce(ols.total_line_items, 0) as total_line_items,
    coalesce(ols.line_items_total, 0) as line_items_total
from orders_with_payments owp
left join order_line_summary ols on owp.order_id = ols.order_id
