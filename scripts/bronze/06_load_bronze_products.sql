-- =====================================================
-- BRONZE LAYER: Load Products Data
-- =====================================================
-- Purpose: Load raw products data from CSV into bronze layer
--          This is a direct copy with no transformations
-- =====================================================

-- Clear existing data (optional, for re-loading)
-- TRUNCATE TABLE bronze.products;

-- Load data from CSV file
-- For PostgreSQL:
COPY bronze.products 
FROM 'E:\Personal Projects\DataWarehouse\datasets\olist_products_dataset.csv'
WITH (FORMAT CSV, HEADER TRUE, DELIMITER ',');

-- For DuckDB (alternative syntax):
-- COPY bronze.products 
-- FROM 'E:\Personal Projects\DataWarehouse\datasets\olist_products_dataset.csv'
-- (FORMAT CSV, HEADER TRUE, DELIMITER ',');

-- Verify load
SELECT 
    COUNT(*) as total_rows,
    COUNT(DISTINCT product_id) as unique_products,
    COUNT(DISTINCT product_category_name) as unique_categories,
    COUNT(*) FILTER (WHERE product_category_name IS NULL) as null_categories
FROM bronze.products;

