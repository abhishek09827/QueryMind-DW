

WITH source AS (
    SELECT * FROM "warehouse"."bronze"."orders"
)

SELECT DISTINCT
    TRIM(order_id) AS order_id,
    
    CASE 
        WHEN TRIM(customer_id) = '' THEN NULL 
        ELSE TRIM(customer_id) 
    END AS customer_id,
    
    CASE 
        WHEN TRIM(order_status) = '' THEN NULL 
        ELSE LOWER(TRIM(order_status)) 
    END AS order_status,
    
    CASE 
        WHEN TRIM(CAST(order_purchase_timestamp AS TEXT)) = '' THEN NULL 
        ELSE order_purchase_timestamp 
    END AS order_purchase_timestamp,
    
    CASE 
        WHEN TRIM(CAST(order_approved_at AS TEXT)) = '' THEN NULL 
        ELSE order_approved_at 
    END AS order_approved_at,
    
    CASE 
        WHEN TRIM(CAST(order_delivered_carrier_date AS TEXT)) = '' THEN NULL 
        ELSE order_delivered_carrier_date 
    END AS order_delivered_carrier_date,
    
    CASE 
        WHEN TRIM(CAST(order_delivered_customer_date AS TEXT)) = '' THEN NULL 
        ELSE order_delivered_customer_date 
    END AS order_delivered_customer_date,
    
    CASE 
        WHEN TRIM(CAST(order_estimated_delivery_date AS TEXT)) = '' THEN NULL 
        ELSE order_estimated_delivery_date 
    END AS order_estimated_delivery_date

FROM source
WHERE order_id IS NOT NULL
  AND TRIM(order_id) != ''
  -- Filter out invalid date relationships
  AND NOT (
      order_delivered_customer_date IS NOT NULL
      AND order_purchase_timestamp IS NOT NULL
      AND order_delivered_customer_date < order_purchase_timestamp
  )