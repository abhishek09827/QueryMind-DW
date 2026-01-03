-- =====================================================
-- BRONZE LAYER: Load Customers Data
-- =====================================================
-- Purpose: Load raw customers data from CSV into bronze layer
--          This is a direct copy with no transformations
-- =====================================================

-- Clear existing data (optional, for re-loading)
-- TRUNCATE TABLE bronze.customers;

-- Load data from CSV file
-- For PostgreSQL:
COPY bronze.customers 
FROM 'E:\Personal Projects\DataWarehouse\datasets\olist_customers_dataset.csv'
WITH (FORMAT CSV, HEADER TRUE, DELIMITER ',');

-- For DuckDB (alternative syntax):
-- COPY bronze.customers 
-- FROM 'E:\Personal Projects\DataWarehouse\datasets\olist_customers_dataset.csv'
-- (FORMAT CSV, HEADER TRUE, DELIMITER ',');

-- Verify load
SELECT 
    COUNT(*) as total_rows,
    COUNT(DISTINCT customer_id) as unique_customer_ids,
    COUNT(DISTINCT customer_unique_id) as unique_customers,
    COUNT(DISTINCT customer_state) as unique_states
FROM bronze.customers;

