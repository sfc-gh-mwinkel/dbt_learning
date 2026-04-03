{% macro get_user_prefix() %}
    {%- set username = target.user | lower -%}
    {%- if '@' in username -%}
        {%- set username = username.split('@')[0] -%}
    {%- endif -%}
    {%- if '.' in username -%}
        {%- set name_parts = username.split('.') -%}
    {%- elif '_' in username -%}
        {%- set name_parts = username.split('_') -%}
    {%- else -%}
        {%- set name_parts = ['', username] -%}
    {%- endif -%}
    {%- set first_name = name_parts[0] -%}
    {%- set last_name = name_parts[-1] -%}
    {%- set first_initial = first_name[0] if first_name else '' -%}
    {{ (first_initial ~ last_name) | upper }}
{%- endmacro %}
