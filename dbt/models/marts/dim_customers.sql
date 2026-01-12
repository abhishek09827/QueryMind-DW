{{ config(materialized='table') }}

WITH customers AS (
    SELECT * FROM {{ ref('stg_customers') }}
)

SELECT
    -- Surrogate Key (Simple hash or row number for dbt)
    -- In production, might use sequence or dbt_utils.surrogate_key
    ROW_NUMBER() OVER (ORDER BY customer_id) AS customer_sk,
    customer_id,
    customer_unique_id,
    customer_zip_code_prefix,
    customer_city,
    customer_state,
    CURRENT_DATE AS start_date,
    CAST(NULL AS DATE) AS end_date,
    TRUE AS is_current,
    CURRENT_TIMESTAMP AS created_at
FROM customers
