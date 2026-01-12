

-- Dependent on other models for FK checks
-- In full implementation, we would replicate products and sellers staging models first
-- For this snippet, assuming stg_orders is available. 
-- In pure dbt, we usually do FK checks via tests, but to preserve SQL "filtering" logic:

WITH source AS (
    SELECT * FROM "warehouse"."bronze"."order_items"
),

valid_orders AS (
    SELECT order_id FROM "warehouse"."public_silver"."stg_orders"
)

SELECT DISTINCT
    TRIM(order_id) AS order_id,
    COALESCE(order_item_id, 0) AS order_item_id,
    
    CASE 
        WHEN TRIM(product_id) = '' THEN NULL 
        ELSE TRIM(product_id) 
    END AS product_id,
    
    CASE 
        WHEN TRIM(seller_id) = '' THEN NULL 
        ELSE TRIM(seller_id) 
    END AS seller_id,
    
    CASE 
        WHEN TRIM(CAST(shipping_limit_date AS TEXT)) = '' THEN NULL 
        ELSE shipping_limit_date 
    END AS shipping_limit_date,
    
    CASE 
        WHEN price IS NULL OR price < 0 THEN 0 
        ELSE ROUND(CAST(price AS DECIMAL(10, 2)), 2) 
    END AS price,
    
    CASE 
        WHEN freight_value IS NULL OR freight_value < 0 THEN 0 
        ELSE ROUND(CAST(freight_value AS DECIMAL(10, 2)), 2) 
    END AS freight_value

FROM source
WHERE order_id IS NOT NULL
  AND TRIM(order_id) != ''
  AND order_item_id IS NOT NULL
  -- Data Integrity: Ensure FKs exist 
  -- Note: We only check orders here for brevity, full implementation checks products/sellers too
  AND order_id IN (SELECT order_id FROM valid_orders)