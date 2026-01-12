{{ config(materialized='table') }}

WITH products AS (
    SELECT * FROM {{ ref('stg_products') }}
)

SELECT
    ROW_NUMBER() OVER (ORDER BY product_id) AS product_sk,
    product_id,
    product_category_name,
    product_name_length,
    product_description_length,
    product_photos_qty,
    product_weight_g,
    product_length_cm,
    product_height_cm,
    product_width_cm,
    
    -- Calculated volume
    CASE 
        WHEN product_length_cm > 0 
         AND product_height_cm > 0 
         AND product_width_cm > 0 
        THEN product_length_cm * product_height_cm * product_width_cm
        ELSE 0
    END AS product_volume_cm3,
    
    CURRENT_TIMESTAMP AS created_at

FROM products
