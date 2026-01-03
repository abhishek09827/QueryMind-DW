-- =====================================================
-- BRONZE LAYER: Load Orders Data
-- =====================================================
-- Purpose: Load raw orders data from CSV into bronze layer
--          This is a direct copy with no transformations
-- =====================================================

-- Clear existing data (optional, for re-loading)
-- TRUNCATE TABLE bronze.orders;

-- Load data from CSV file
-- For PostgreSQL:
COPY bronze.orders 
FROM 'E:\Personal Projects\DataWarehouse\datasets\olist_orders_dataset.csv'
WITH (FORMAT CSV, HEADER TRUE, DELIMITER ',');

-- For DuckDB (alternative syntax):
-- COPY bronze.orders 
-- FROM 'E:\Personal Projects\DataWarehouse\datasets\olist_orders_dataset.csv'
-- (FORMAT CSV, HEADER TRUE, DELIMITER ',');

-- Verify load
SELECT 
    COUNT(*) as total_rows,
    COUNT(DISTINCT order_id) as unique_orders,
    MIN(order_purchase_timestamp) as earliest_order,
    MAX(order_purchase_timestamp) as latest_order
FROM bronze.orders;

