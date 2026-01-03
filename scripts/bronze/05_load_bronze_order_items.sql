-- =====================================================
-- BRONZE LAYER: Load Order Items Data
-- =====================================================
-- Purpose: Load raw order items data from CSV into bronze layer
--          This is a direct copy with no transformations
-- =====================================================

-- Clear existing data (optional, for re-loading)
-- TRUNCATE TABLE bronze.order_items;

-- Load data from CSV file
-- For PostgreSQL:
COPY bronze.order_items 
FROM 'E:\Personal Projects\DataWarehouse\datasets\olist_order_items_dataset.csv'
WITH (FORMAT CSV, HEADER TRUE, DELIMITER ',');

-- For DuckDB (alternative syntax):
-- COPY bronze.order_items 
-- FROM 'E:\Personal Projects\DataWarehouse\datasets\olist_order_items_dataset.csv'
-- (FORMAT CSV, HEADER TRUE, DELIMITER ',');

-- Verify load
SELECT 
    COUNT(*) as total_rows,
    COUNT(DISTINCT order_id) as unique_orders,
    COUNT(DISTINCT product_id) as unique_products,
    COUNT(DISTINCT seller_id) as unique_sellers,
    SUM(price) as total_price,
    SUM(freight_value) as total_freight
FROM bronze.order_items;

