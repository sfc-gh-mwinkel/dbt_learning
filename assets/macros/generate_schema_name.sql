{% macro generate_schema_name(custom_schema_name, node) -%}
    {%- set user_prefix = get_user_prefix() | trim -%}
    {%- if custom_schema_name is none -%}
        {{ user_prefix }}_{{ target.schema | upper }}
    {%- else -%}
        {{ user_prefix }}_{{ custom_schema_name | trim | upper }}
    {%- endif -%}
{%- endmacro %}
