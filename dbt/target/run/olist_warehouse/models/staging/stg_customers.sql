
  create view "warehouse"."public_silver"."stg_customers__dbt_tmp"
    
    
  as (
    

WITH source AS (
    SELECT * FROM "warehouse"."bronze"."customers"
)

SELECT DISTINCT
    TRIM(customer_id) AS customer_id,
    TRIM(customer_unique_id) AS customer_unique_id,
    
    CASE 
        WHEN TRIM(customer_zip_code_prefix) = '' THEN NULL 
        ELSE TRIM(customer_zip_code_prefix) 
    END AS customer_zip_code_prefix,
    
    CASE 
        WHEN TRIM(customer_city) = '' THEN NULL 
        ELSE LOWER(TRIM(customer_city)) 
    END AS customer_city,
    
    CASE 
        WHEN TRIM(customer_state) = '' THEN NULL 
        ELSE UPPER(TRIM(customer_state)) 
    END AS customer_state

FROM source
WHERE customer_id IS NOT NULL
  AND customer_unique_id IS NOT NULL
  AND TRIM(customer_id) != ''
  AND TRIM(customer_unique_id) != ''
  );