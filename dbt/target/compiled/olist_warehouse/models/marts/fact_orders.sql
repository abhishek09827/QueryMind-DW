

WITH orders AS (
    SELECT * FROM "warehouse"."public_silver"."stg_orders"
),
dim_customer AS (
    SELECT * FROM "warehouse"."public_gold"."dim_customers" WHERE is_current = TRUE
),
dim_seller AS (
    SELECT * FROM "warehouse"."public_gold"."dim_seller"
),
dim_date AS (
    SELECT * FROM "warehouse"."public_gold"."dim_date"
),
-- Logic to find the primary seller (first seller on the order)
primary_seller AS (
    SELECT 
        order_id,
        seller_id
    FROM (
        SELECT 
            order_id,
            seller_id,
            ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY order_item_id) AS rn
        FROM "warehouse"."public_silver"."stg_order_items"
        WHERE seller_id IS NOT NULL
    ) ranked
    WHERE rn = 1
)

SELECT 
    ROW_NUMBER() OVER (ORDER BY o.order_id) AS order_sk,
    o.order_id,
    dc.customer_sk,
    ds.seller_sk,
    dpurchase.date_sk AS purchase_date_sk,
    dapproved.date_sk AS approved_date_sk,
    o.order_status,
    o.order_purchase_timestamp,
    o.order_approved_at,
    o.order_delivered_carrier_date,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date,
    
    -- Calculated Metrics
    CASE 
        WHEN o.order_approved_at IS NOT NULL AND o.order_purchase_timestamp IS NOT NULL
        THEN EXTRACT(EPOCH FROM (o.order_approved_at - o.order_purchase_timestamp)) / 3600.0
        ELSE NULL
    END AS approval_time_hours,
    
    CASE 
        WHEN o.order_delivered_customer_date IS NOT NULL AND o.order_estimated_delivery_date IS NOT NULL
        THEN o.order_delivered_customer_date <= o.order_estimated_delivery_date
        ELSE NULL
    END AS is_delivered_on_time,
    
    CURRENT_TIMESTAMP AS created_at

FROM orders o
INNER JOIN dim_customer dc ON o.customer_id = dc.customer_id
LEFT JOIN primary_seller ps ON o.order_id = ps.order_id
LEFT JOIN dim_seller ds ON ps.seller_id = ds.seller_id
LEFT JOIN dim_date dpurchase ON DATE(o.order_purchase_timestamp) = dpurchase.date_actual
LEFT JOIN dim_date dapproved ON DATE(o.order_approved_at) = dapproved.date_actual