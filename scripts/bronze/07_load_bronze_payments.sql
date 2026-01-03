-- =====================================================
-- BRONZE LAYER: Load Order Payments Data
-- =====================================================
-- Purpose: Load raw order payments data from CSV into bronze layer
--          This is a direct copy with no transformations
-- =====================================================

-- Clear existing data (optional, for re-loading)
-- TRUNCATE TABLE bronze.order_payments;

-- Load data from CSV file
-- For PostgreSQL:
COPY bronze.order_payments 
FROM 'E:\Personal Projects\DataWarehouse\datasets\olist_order_payments_dataset.csv'
WITH (FORMAT CSV, HEADER TRUE, DELIMITER ',');

-- For DuckDB (alternative syntax):
-- COPY bronze.order_payments 
-- FROM 'E:\Personal Projects\DataWarehouse\datasets\olist_order_payments_dataset.csv'
-- (FORMAT CSV, HEADER TRUE, DELIMITER ',');

-- Verify load
SELECT 
    COUNT(*) as total_rows,
    COUNT(DISTINCT order_id) as unique_orders,
    COUNT(DISTINCT payment_type) as unique_payment_types,
    SUM(payment_value) as total_payment_value,
    AVG(payment_installments) as avg_installments
FROM bronze.order_payments;

