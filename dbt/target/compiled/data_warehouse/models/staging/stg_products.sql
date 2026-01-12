

WITH source AS (
    SELECT * FROM "warehouse"."bronze"."products"
)

SELECT DISTINCT
    TRIM(product_id) AS product_id,
    
    CASE 
        WHEN TRIM(product_category_name) = '' THEN NULL 
        ELSE LOWER(TRIM(product_category_name)) 
    END AS product_category_name,
    
    COALESCE(product_name_lenght, 0) AS product_name_length,
    COALESCE(product_description_lenght, 0) AS product_description_length,
    COALESCE(product_photos_qty, 0) AS product_photos_qty,
    
    CASE 
        WHEN product_weight_g IS NULL OR product_weight_g < 0 THEN 0 
        ELSE product_weight_g 
    END AS product_weight_g,
    
    CASE 
        WHEN product_length_cm IS NULL OR product_length_cm < 0 THEN 0 
        ELSE product_length_cm 
    END AS product_length_cm,
    
    CASE 
        WHEN product_height_cm IS NULL OR product_height_cm < 0 THEN 0 
        ELSE product_height_cm 
    END AS product_height_cm,
    
    CASE 
        WHEN product_width_cm IS NULL OR product_width_cm < 0 THEN 0 
        ELSE product_width_cm 
    END AS product_width_cm

FROM source
WHERE product_id IS NOT NULL
  AND TRIM(product_id) != ''