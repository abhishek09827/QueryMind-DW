
  
    

  create  table "warehouse"."public_gold"."dim_seller__dbt_tmp"
  
  
    as
  
  (
    

WITH sellers AS (
    SELECT * FROM "warehouse"."public_silver"."stg_sellers"
)

SELECT
    ROW_NUMBER() OVER (ORDER BY seller_id) AS seller_sk,
    seller_id,
    seller_zip_code_prefix,
    seller_city,
    seller_state,
    CURRENT_TIMESTAMP AS created_at

FROM sellers
  );
  