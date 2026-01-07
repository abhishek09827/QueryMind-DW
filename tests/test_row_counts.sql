-- =====================================================
-- TESTS: Row Count Validation
-- =====================================================
-- Purpose: Verify row counts between layers
--          Bronze vs Silver: Should be equal or Silver <= Bronze (after deduplication)
--          Silver vs Gold: Should match for dimensions and facts
-- =====================================================

-- =====================================================
-- 1. BRONZE vs SILVER ROW COUNTS
-- =====================================================

-- Orders: Bronze vs Silver
SELECT 
    'Orders' AS table_name,
    (SELECT COUNT(*) FROM bronze.orders) AS bronze_count,
    (SELECT COUNT(*) FROM silver.orders) AS silver_count,
    (SELECT COUNT(*) FROM bronze.orders) - (SELECT COUNT(*) FROM silver.orders) AS difference,
    CASE 
        WHEN (SELECT COUNT(*) FROM bronze.orders) >= (SELECT COUNT(*) FROM silver.orders) 
        THEN 'PASS' 
        ELSE 'FAIL' 
    END AS status
UNION ALL

-- Customers: Bronze vs Silver
SELECT 
    'Customers' AS table_name,
    (SELECT COUNT(*) FROM bronze.customers) AS bronze_count,
    (SELECT COUNT(*) FROM silver.customers) AS silver_count,
    (SELECT COUNT(*) FROM bronze.customers) - (SELECT COUNT(*) FROM silver.customers) AS difference,
    CASE 
        WHEN (SELECT COUNT(*) FROM bronze.customers) >= (SELECT COUNT(*) FROM silver.customers) 
        THEN 'PASS' 
        ELSE 'FAIL' 
    END AS status
UNION ALL

-- Order Items: Bronze vs Silver
SELECT 
    'Order Items' AS table_name,
    (SELECT COUNT(*) FROM bronze.order_items) AS bronze_count,
    (SELECT COUNT(*) FROM silver.order_items) AS silver_count,
    (SELECT COUNT(*) FROM bronze.order_items) - (SELECT COUNT(*) FROM silver.order_items) AS difference,
    CASE 
        WHEN (SELECT COUNT(*) FROM bronze.order_items) >= (SELECT COUNT(*) FROM silver.order_items) 
        THEN 'PASS' 
        ELSE 'FAIL' 
    END AS status
UNION ALL

-- Products: Bronze vs Silver
SELECT 
    'Products' AS table_name,
    (SELECT COUNT(*) FROM bronze.products) AS bronze_count,
    (SELECT COUNT(*) FROM silver.products) AS silver_count,
    (SELECT COUNT(*) FROM bronze.products) - (SELECT COUNT(*) FROM silver.products) AS difference,
    CASE 
        WHEN (SELECT COUNT(*) FROM bronze.products) >= (SELECT COUNT(*) FROM silver.products) 
        THEN 'PASS' 
        ELSE 'FAIL' 
    END AS status
UNION ALL

-- Payments: Bronze vs Silver
SELECT 
    'Payments' AS table_name,
    (SELECT COUNT(*) FROM bronze.order_payments) AS bronze_count,
    (SELECT COUNT(*) FROM silver.order_payments) AS silver_count,
    (SELECT COUNT(*) FROM bronze.order_payments) - (SELECT COUNT(*) FROM silver.order_payments) AS difference,
    CASE 
        WHEN (SELECT COUNT(*) FROM bronze.order_payments) >= (SELECT COUNT(*) FROM silver.order_payments) 
        THEN 'PASS' 
        ELSE 'FAIL' 
    END AS status
UNION ALL

-- Reviews: Bronze vs Silver
SELECT 
    'Reviews' AS table_name,
    (SELECT COUNT(*) FROM bronze.order_reviews) AS bronze_count,
    (SELECT COUNT(*) FROM silver.order_reviews) AS silver_count,
    (SELECT COUNT(*) FROM bronze.order_reviews) - (SELECT COUNT(*) FROM silver.order_reviews) AS difference,
    CASE 
        WHEN (SELECT COUNT(*) FROM bronze.order_reviews) >= (SELECT COUNT(*) FROM silver.order_reviews) 
        THEN 'PASS' 
        ELSE 'FAIL' 
    END AS status
UNION ALL

-- Sellers: Bronze vs Silver
SELECT 
    'Sellers' AS table_name,
    (SELECT COUNT(*) FROM bronze.sellers) AS bronze_count,
    (SELECT COUNT(*) FROM silver.sellers) AS silver_count,
    (SELECT COUNT(*) FROM bronze.sellers) - (SELECT COUNT(*) FROM silver.sellers) AS difference,
    CASE 
        WHEN (SELECT COUNT(*) FROM bronze.sellers) >= (SELECT COUNT(*) FROM silver.sellers) 
        THEN 'PASS' 
        ELSE 'FAIL' 
    END AS status;

-- =====================================================
-- 2. SILVER vs GOLD ROW COUNTS
-- =====================================================

-- Orders: Silver vs Gold (Fact Orders)
SELECT 
    'Orders (Silver vs Gold Fact)' AS table_name,
    (SELECT COUNT(*) FROM silver.orders) AS silver_count,
    (SELECT COUNT(*) FROM gold.fact_orders) AS gold_count,
    (SELECT COUNT(*) FROM silver.orders) - (SELECT COUNT(*) FROM gold.fact_orders) AS difference,
    CASE 
        WHEN (SELECT COUNT(*) FROM silver.orders) >= (SELECT COUNT(*) FROM gold.fact_orders) 
        THEN 'PASS' 
        ELSE 'FAIL' 
    END AS status
UNION ALL

-- Customers: Silver vs Gold (Dim Customer - current records only)
SELECT 
    'Customers (Silver vs Gold Dim - Current)' AS table_name,
    (SELECT COUNT(*) FROM silver.customers) AS silver_count,
    (SELECT COUNT(*) FROM gold.dim_customer WHERE is_current = TRUE) AS gold_count,
    (SELECT COUNT(*) FROM silver.customers) - (SELECT COUNT(*) FROM gold.dim_customer WHERE is_current = TRUE) AS difference,
    CASE 
        WHEN (SELECT COUNT(*) FROM silver.customers) = (SELECT COUNT(*) FROM gold.dim_customer WHERE is_current = TRUE) 
        THEN 'PASS' 
        ELSE 'FAIL' 
    END AS status
UNION ALL

-- Products: Silver vs Gold (Dim Product)
SELECT 
    'Products (Silver vs Gold Dim)' AS table_name,
    (SELECT COUNT(*) FROM silver.products) AS silver_count,
    (SELECT COUNT(*) FROM gold.dim_product) AS gold_count,
    (SELECT COUNT(*) FROM silver.products) - (SELECT COUNT(*) FROM gold.dim_product) AS difference,
    CASE 
        WHEN (SELECT COUNT(*) FROM silver.products) = (SELECT COUNT(*) FROM gold.dim_product) 
        THEN 'PASS' 
        ELSE 'FAIL' 
    END AS status
UNION ALL

-- Sellers: Silver vs Gold (Dim Seller)
SELECT 
    'Sellers (Silver vs Gold Dim)' AS table_name,
    (SELECT COUNT(*) FROM silver.sellers) AS silver_count,
    (SELECT COUNT(*) FROM gold.dim_seller) AS gold_count,
    (SELECT COUNT(*) FROM silver.sellers) - (SELECT COUNT(*) FROM gold.dim_seller) AS difference,
    CASE 
        WHEN (SELECT COUNT(*) FROM silver.sellers) = (SELECT COUNT(*) FROM gold.dim_seller) 
        THEN 'PASS' 
        ELSE 'FAIL' 
    END AS status
UNION ALL

-- Order Items: Silver vs Gold (Fact Order Items)
SELECT 
    'Order Items (Silver vs Gold Fact)' AS table_name,
    (SELECT COUNT(*) FROM silver.order_items) AS silver_count,
    (SELECT COUNT(*) FROM gold.fact_order_items) AS gold_count,
    (SELECT COUNT(*) FROM silver.order_items) - (SELECT COUNT(*) FROM gold.fact_order_items) AS difference,
    CASE 
        WHEN (SELECT COUNT(*) FROM silver.order_items) >= (SELECT COUNT(*) FROM gold.fact_order_items) 
        THEN 'PASS' 
        ELSE 'FAIL' 
    END AS status
UNION ALL

-- Payments: Silver vs Gold (Fact Payments)
SELECT 
    'Payments (Silver vs Gold Fact)' AS table_name,
    (SELECT COUNT(*) FROM silver.order_payments) AS silver_count,
    (SELECT COUNT(*) FROM gold.fact_payments) AS gold_count,
    (SELECT COUNT(*) FROM silver.order_payments) - (SELECT COUNT(*) FROM gold.fact_payments) AS difference,
    CASE 
        WHEN (SELECT COUNT(*) FROM silver.order_payments) >= (SELECT COUNT(*) FROM gold.fact_payments) 
        THEN 'PASS' 
        ELSE 'FAIL' 
    END AS status
UNION ALL

-- Reviews: Silver vs Gold (Fact Reviews)
SELECT 
    'Reviews (Silver vs Gold Fact)' AS table_name,
    (SELECT COUNT(*) FROM silver.order_reviews) AS silver_count,
    (SELECT COUNT(*) FROM gold.fact_reviews) AS gold_count,
    (SELECT COUNT(*) FROM silver.order_reviews) - (SELECT COUNT(*) FROM gold.fact_reviews) AS difference,
    CASE 
        WHEN (SELECT COUNT(*) FROM silver.order_reviews) >= (SELECT COUNT(*) FROM gold.fact_reviews) 
        THEN 'PASS' 
        ELSE 'FAIL' 
    END AS status;

