with source as (
    select * from {{ source('raw', 'payments') }}
)

select
    payment_id,
    order_id,
    payment_method,
    cast(amount as decimal(10, 2)) as amount,
    cast(payment_date as date) as payment_date
from source
