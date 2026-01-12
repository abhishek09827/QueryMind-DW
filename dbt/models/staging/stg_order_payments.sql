{{ config(materialized='view') }}

WITH source AS (
    SELECT * FROM {{ source('bronze', 'order_payments') }}
)

SELECT DISTINCT
    TRIM(order_id) AS order_id,
    COALESCE(payment_sequential, 1) AS payment_sequential,
    
    CASE 
        WHEN TRIM(payment_type) = '' THEN NULL 
        ELSE LOWER(TRIM(payment_type)) 
    END AS payment_type,
    
    CASE 
        WHEN payment_installments IS NULL OR payment_installments < 1 THEN 1 
        ELSE payment_installments 
    END AS payment_installments,
    
    CASE 
        WHEN payment_value IS NULL OR payment_value < 0 THEN 0 
        ELSE ROUND(CAST(payment_value AS DECIMAL(10, 2)), 2) 
    END AS payment_value

FROM source
WHERE order_id IS NOT NULL
  AND TRIM(order_id) != ''
  AND payment_sequential IS NOT NULL
