-- =====================================================
-- BRONZE LAYER: Load Sellers Data
-- =====================================================
-- Purpose: Load raw sellers data from CSV into bronze layer
--          This is a direct copy with no transformations
-- =====================================================

-- Clear existing data (optional, for re-loading)
-- TRUNCATE TABLE bronze.sellers;

-- Load data from CSV file
-- For PostgreSQL:
COPY bronze.sellers 
FROM 'E:\Personal Projects\DataWarehouse\datasets\olist_sellers_dataset.csv'
WITH (FORMAT CSV, HEADER TRUE, DELIMITER ',');

-- For DuckDB (alternative syntax):
-- COPY bronze.sellers 
-- FROM 'E:\Personal Projects\DataWarehouse\datasets\olist_sellers_dataset.csv'
-- (FORMAT CSV, HEADER TRUE, DELIMITER ',');

-- Verify load
SELECT 
    COUNT(*) as total_rows,
    COUNT(DISTINCT seller_id) as unique_sellers,
    COUNT(DISTINCT seller_state) as unique_states,
    COUNT(DISTINCT seller_city) as unique_cities
FROM bronze.sellers;

