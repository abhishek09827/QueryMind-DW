
  create view "warehouse"."public_silver"."stg_sellers__dbt_tmp"
    
    
  as (
    

WITH source AS (
    SELECT * FROM "warehouse"."bronze"."sellers"
)

SELECT DISTINCT
    TRIM(seller_id) AS seller_id,
    
    CASE 
        WHEN TRIM(seller_zip_code_prefix) = '' THEN NULL 
        ELSE TRIM(seller_zip_code_prefix) 
    END AS seller_zip_code_prefix,
    
    CASE 
        WHEN TRIM(seller_city) = '' THEN NULL 
        ELSE LOWER(TRIM(seller_city)) 
    END AS seller_city,
    
    CASE 
        WHEN TRIM(seller_state) = '' THEN NULL 
        ELSE UPPER(TRIM(seller_state)) 
    END AS seller_state

FROM source
WHERE seller_id IS NOT NULL
  AND TRIM(seller_id) != ''
  );