{% macro classify_tier(value_column, high_threshold, mid_threshold) %}
    case
        when {{ value_column }} >= {{ high_threshold }} then 'gold'
        when {{ value_column }} >= {{ mid_threshold }} then 'silver'
        else 'bronze'
    end
{% endmacro %}
