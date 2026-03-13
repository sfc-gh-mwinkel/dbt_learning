with source as (
    select * from {{ source('raw', 'orders') }}
)

select
    order_id,
    customer_id,
    cast(order_date as date) as order_date,
    status,
    cast(amount as decimal(10, 2)) as amount
from source
