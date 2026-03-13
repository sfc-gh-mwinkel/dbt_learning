{% snapshot snap_orders %}

{{
    config(
        target_database=target.database,
        target_schema=target.schema ~ '_snapshots',
        unique_key='order_id',
        strategy='check',
        check_cols=['status', 'amount']
    )
}}

select * from {{ source('raw', 'orders') }}

{% endsnapshot %}
