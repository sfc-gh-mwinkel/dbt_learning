{% macro cents_to_dollars(column_name) %}
    round(cast({{ column_name }} as decimal(10, 2)) / 100, 2)
{% endmacro %}
