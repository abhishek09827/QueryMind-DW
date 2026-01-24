-- =====================================================
-- SILVER LAYER: Clean Order Items Data
-- =====================================================
-- Purpose: Clean and standardize order items data from bronze layer
--          Apply: trim whitespace, ensure numeric columns are numeric,
--          validate relationships, remove duplicates
-- =====================================================

-- Drop table if exists (for re-running)
DROP TABLE IF EXISTS silver.order_items CASCADE;

-- Create cleaned order items table
CREATE TABLE silver.order_items AS
SELECT DISTINCT
    -- Foreign keys
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
    
    -- Timestamp
    CASE 
        WHEN TRIM(shipping_limit_date::TEXT) = '' THEN NULL 
        ELSE shipping_limit_date 
    END AS shipping_limit_date,
    
    -- Numeric values (ensure they are valid numbers)
    CASE 
        WHEN price IS NULL OR price < 0 THEN 0 
        ELSE ROUND(CAST(price AS DECIMAL(10, 2)), 2) 
    END AS price,
    
    CASE 
        WHEN freight_value IS NULL OR freight_value < 0 THEN 0 
        ELSE ROUND(CAST(freight_value AS DECIMAL(10, 2)), 2) 
    END AS freight_value,
    'olist'::TEXT              AS source_system,
    CURRENT_DATE               AS ingestion_date,
    CURRENT_TIMESTAMP          AS created_at,
    CURRENT_TIMESTAMP          AS updated_at,
    TRUE                        AS is_active
    
FROM bronze.order_items oi
WHERE order_id IS NOT NULL
  AND TRIM(order_id) != ''
  AND order_item_id IS NOT NULL
  -- Data Integrity: Ensure FKs exist in dimension tables
  AND EXISTS (SELECT 1 FROM silver.orders o WHERE o.order_id = TRIM(oi.order_id))
  AND EXISTS (SELECT 1 FROM silver.products p WHERE p.product_id = TRIM(oi.product_id))
  AND EXISTS (SELECT 1 FROM silver.sellers s WHERE s.seller_id = TRIM(oi.seller_id));

-- Add primary key constraint
ALTER TABLE silver.order_items 
ADD PRIMARY KEY (order_id, order_item_id);

-- Create indexes
CREATE INDEX idx_silver_order_items_order_id ON silver.order_items(order_id);
CREATE INDEX idx_silver_order_items_product_id ON silver.order_items(product_id);
CREATE INDEX idx_silver_order_items_seller_id ON silver.order_items(seller_id);

-- Verify cleaning results
SELECT 
    COUNT(*) as total_rows,
    COUNT(DISTINCT order_id) as unique_orders,
    COUNT(DISTINCT product_id) as unique_products,
    COUNT(DISTINCT seller_id) as unique_sellers,
    SUM(price) as total_price,
    SUM(freight_value) as total_freight,
    AVG(price) as avg_price,
    AVG(freight_value) as avg_freight
FROM silver.order_items;

