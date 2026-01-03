-- =====================================================
-- BRONZE LAYER: Load Order Reviews Data
-- =====================================================
-- Purpose: Load raw order reviews data from CSV into bronze layer
--          This is a direct copy with no transformations
-- =====================================================

-- Clear existing data (optional, for re-loading)
-- TRUNCATE TABLE bronze.order_reviews;

-- Load data from CSV file
-- For PostgreSQL:
COPY bronze.order_reviews 
FROM 'E:\Personal Projects\DataWarehouse\datasets\olist_order_reviews_dataset.csv'
WITH (FORMAT CSV, HEADER TRUE, DELIMITER ',');

-- For DuckDB (alternative syntax):
-- COPY bronze.order_reviews 
-- FROM 'E:\Personal Projects\DataWarehouse\datasets\olist_order_reviews_dataset.csv'
-- (FORMAT CSV, HEADER TRUE, DELIMITER ',');

-- Verify load
SELECT 
    COUNT(*) as total_rows,
    COUNT(DISTINCT order_id) as unique_orders,
    COUNT(DISTINCT review_id) as unique_reviews,
    AVG(review_score) as avg_review_score,
    COUNT(*) FILTER (WHERE review_comment_message IS NOT NULL) as reviews_with_comments
FROM bronze.order_reviews;

