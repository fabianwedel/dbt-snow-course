-- =============================================================================
-- macros/financial.sql
-- Financial helper macros
-- =============================================================================


-- cents_to_dollars
-- Converts an integer cents column to a decimal dollar amount.
-- Usage:  {{ cents_to_dollars('price_cents') }}
{% macro cents_to_dollars(column_name, precision=2) %}
    ({{ column_name }} / 100.0)::decimal(18, {{ precision }})
{% endmacro %}


-- dollars_to_cents
-- Converts a decimal dollar amount to integer cents (avoids float errors).
-- Usage:  {{ dollars_to_cents('price_dollars') }}
{% macro dollars_to_cents(column_name) %}
    round({{ column_name }} * 100)::integer
{% endmacro %}


-- apply_discount
-- Returns the discounted price given a price column and a discount fraction.
-- Usage:  {{ apply_discount('extended_price', 'discount_fraction') }}
{% macro apply_discount(price_col, discount_col, precision=2) %}
    round({{ price_col }} * (1 - {{ discount_col }}), {{ precision }})
{% endmacro %}
