
  
    

  create  table "warehouse"."public_gold"."fact_order_items__dbt_tmp"
  
  
    as
  
  (
    

WITH order_items AS (
    SELECT * FROM "warehouse"."public_silver"."stg_order_items"
),
fact_orders AS (
    SELECT * FROM "warehouse"."public_gold"."fact_orders"
),
dim_product AS (
    SELECT * FROM "warehouse"."public_gold"."dim_product"
),
dim_seller AS (
    SELECT * FROM "warehouse"."public_gold"."dim_seller"
),
dim_date AS (
    SELECT * FROM "warehouse"."public_gold"."dim_date"
)

SELECT
    ROW_NUMBER() OVER (ORDER BY oi.order_id, oi.order_item_id) AS order_item_sk,
    oi.order_id,
    oi.order_item_id,
    fo.order_sk,
    dp.product_sk,
    ds.seller_sk,
    dship.date_sk AS shipping_limit_date_sk,
    oi.shipping_limit_date,
    oi.price,
    oi.freight_value,
    1 AS quantity,
    oi.price + oi.freight_value AS total_item_value,
    CURRENT_TIMESTAMP AS created_at

FROM order_items oi
INNER JOIN fact_orders fo ON oi.order_id = fo.order_id
INNER JOIN dim_product dp ON oi.product_id = dp.product_id
INNER JOIN dim_seller ds ON oi.seller_id = ds.seller_id
LEFT JOIN dim_date dship ON DATE(oi.shipping_limit_date) = dship.date_actual
  );
  