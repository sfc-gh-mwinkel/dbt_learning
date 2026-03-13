select
    o.order_id,
    o.order_amount,
    oi.line_items_total,
    abs(o.order_amount - oi.line_items_total) as difference
from {{ ref('fct_orders') }} o
inner join (
    select
        order_id,
        sum(line_total) as line_items_total
    from {{ ref('int_order_items_with_products') }}
    group by order_id
) oi on o.order_id = oi.order_id
where abs(o.order_amount - oi.line_items_total) > 0.01
