with source as (
    select * from {{ source('raw', 'customers') }}
)

select
    customer_id,
    first_name,
    last_name,
    email,
    cast(created_at as date) as created_at,
    is_active
from source
