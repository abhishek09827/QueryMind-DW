-- =====================================================
-- TESTS: Null Value Validation
-- =====================================================
-- Purpose: Verify that key columns do not contain NULL values
--          where they should not be null
-- =====================================================

-- =====================================================
-- 1. BRONZE LAYER NULL CHECKS
-- =====================================================

-- Check for NULLs in primary keys and critical fields
SELECT 
    'Bronze Orders - order_id' AS test_name,
    COUNT(*) FILTER (WHERE order_id IS NULL) AS null_count,
    COUNT(*) AS total_count,
    CASE 
        WHEN COUNT(*) FILTER (WHERE order_id IS NULL) = 0 THEN 'PASS' 
        ELSE 'FAIL' 
    END AS status
FROM bronze.orders
UNION ALL

SELECT 
    'Bronze Customers - customer_id' AS test_name,
    COUNT(*) FILTER (WHERE customer_id IS NULL) AS null_count,
    COUNT(*) AS total_count,
    CASE 
        WHEN COUNT(*) FILTER (WHERE customer_id IS NULL) = 0 THEN 'PASS' 
        ELSE 'FAIL' 
    END AS status
FROM bronze.customers
UNION ALL

SELECT 
    'Bronze Order Items - order_id' AS test_name,
    COUNT(*) FILTER (WHERE order_id IS NULL) AS null_count,
    COUNT(*) AS total_count,
    CASE 
        WHEN COUNT(*) FILTER (WHERE order_id IS NULL) = 0 THEN 'PASS' 
        ELSE 'FAIL' 
    END AS status
FROM bronze.order_items
UNION ALL

SELECT 
    'Bronze Products - product_id' AS test_name,
    COUNT(*) FILTER (WHERE product_id IS NULL) AS null_count,
    COUNT(*) AS total_count,
    CASE 
        WHEN COUNT(*) FILTER (WHERE product_id IS NULL) = 0 THEN 'PASS' 
        ELSE 'FAIL' 
    END AS status
FROM bronze.products;

-- =====================================================
-- 2. SILVER LAYER NULL CHECKS
-- =====================================================

SELECT 
    'Silver Orders - order_id' AS test_name,
    COUNT(*) FILTER (WHERE order_id IS NULL) AS null_count,
    COUNT(*) AS total_count,
    CASE 
        WHEN COUNT(*) FILTER (WHERE order_id IS NULL) = 0 THEN 'PASS' 
        ELSE 'FAIL' 
    END AS status
FROM silver.orders
UNION ALL

SELECT 
    'Silver Customers - customer_id' AS test_name,
    COUNT(*) FILTER (WHERE customer_id IS NULL) AS null_count,
    COUNT(*) AS total_count,
    CASE 
        WHEN COUNT(*) FILTER (WHERE customer_id IS NULL) = 0 THEN 'PASS' 
        ELSE 'FAIL' 
    END AS status
FROM silver.customers
UNION ALL

SELECT 
    'Silver Customers - customer_unique_id' AS test_name,
    COUNT(*) FILTER (WHERE customer_unique_id IS NULL) AS null_count,
    COUNT(*) AS total_count,
    CASE 
        WHEN COUNT(*) FILTER (WHERE customer_unique_id IS NULL) = 0 THEN 'PASS' 
        ELSE 'FAIL' 
    END AS status
FROM silver.customers
UNION ALL

SELECT 
    'Silver Order Items - order_id' AS test_name,
    COUNT(*) FILTER (WHERE order_id IS NULL) AS null_count,
    COUNT(*) AS total_count,
    CASE 
        WHEN COUNT(*) FILTER (WHERE order_id IS NULL) = 0 THEN 'PASS' 
        ELSE 'FAIL' 
    END AS status
FROM silver.order_items
UNION ALL

SELECT 
    'Silver Order Items - product_id' AS test_name,
    COUNT(*) FILTER (WHERE product_id IS NULL) AS null_count,
    COUNT(*) AS total_count,
    CASE 
        WHEN COUNT(*) FILTER (WHERE product_id IS NULL) = 0 THEN 'PASS' 
        ELSE 'WARN'  -- Some order items might not have products
    END AS status
FROM silver.order_items
UNION ALL

SELECT 
    'Silver Products - product_id' AS test_name,
    COUNT(*) FILTER (WHERE product_id IS NULL) AS null_count,
    COUNT(*) AS total_count,
    CASE 
        WHEN COUNT(*) FILTER (WHERE product_id IS NULL) = 0 THEN 'PASS' 
        ELSE 'FAIL' 
    END AS status
FROM silver.products
UNION ALL

SELECT 
    'Silver Sellers - seller_id' AS test_name,
    COUNT(*) FILTER (WHERE seller_id IS NULL) AS null_count,
    COUNT(*) AS total_count,
    CASE 
        WHEN COUNT(*) FILTER (WHERE seller_id IS NULL) = 0 THEN 'PASS' 
        ELSE 'FAIL' 
    END AS status
FROM silver.sellers;

-- =====================================================
-- 3. GOLD LAYER NULL CHECKS
-- =====================================================

SELECT 
    'Gold Dim Customer - customer_id' AS test_name,
    COUNT(*) FILTER (WHERE customer_id IS NULL) AS null_count,
    COUNT(*) AS total_count,
    CASE 
        WHEN COUNT(*) FILTER (WHERE customer_id IS NULL) = 0 THEN 'PASS' 
        ELSE 'FAIL' 
    END AS status
FROM gold.dim_customer
UNION ALL

SELECT 
    'Gold Dim Customer - customer_unique_id' AS test_name,
    COUNT(*) FILTER (WHERE customer_unique_id IS NULL) AS null_count,
    COUNT(*) AS total_count,
    CASE 
        WHEN COUNT(*) FILTER (WHERE customer_unique_id IS NULL) = 0 THEN 'PASS' 
        ELSE 'FAIL' 
    END AS status
FROM gold.dim_customer
UNION ALL

SELECT 
    'Gold Dim Product - product_id' AS test_name,
    COUNT(*) FILTER (WHERE product_id IS NULL) AS null_count,
    COUNT(*) AS total_count,
    CASE 
        WHEN COUNT(*) FILTER (WHERE product_id IS NULL) = 0 THEN 'PASS' 
        ELSE 'FAIL' 
    END AS status
FROM gold.dim_product
UNION ALL

SELECT 
    'Gold Dim Seller - seller_id' AS test_name,
    COUNT(*) FILTER (WHERE seller_id IS NULL) AS null_count,
    COUNT(*) AS total_count,
    CASE 
        WHEN COUNT(*) FILTER (WHERE seller_id IS NULL) = 0 THEN 'PASS' 
        ELSE 'FAIL' 
    END AS status
FROM gold.dim_seller
UNION ALL

SELECT 
    'Gold Fact Orders - order_id' AS test_name,
    COUNT(*) FILTER (WHERE order_id IS NULL) AS null_count,
    COUNT(*) AS total_count,
    CASE 
        WHEN COUNT(*) FILTER (WHERE order_id IS NULL) = 0 THEN 'PASS' 
        ELSE 'FAIL' 
    END AS status
FROM gold.fact_orders
UNION ALL

SELECT 
    'Gold Fact Orders - customer_sk' AS test_name,
    COUNT(*) FILTER (WHERE customer_sk IS NULL) AS null_count,
    COUNT(*) AS total_count,
    CASE 
        WHEN COUNT(*) FILTER (WHERE customer_sk IS NULL) = 0 THEN 'PASS' 
        ELSE 'FAIL' 
    END AS status
FROM gold.fact_orders
UNION ALL

SELECT 
    'Gold Fact Order Items - order_sk' AS test_name,
    COUNT(*) FILTER (WHERE order_sk IS NULL) AS null_count,
    COUNT(*) AS total_count,
    CASE 
        WHEN COUNT(*) FILTER (WHERE order_sk IS NULL) = 0 THEN 'PASS' 
        ELSE 'FAIL' 
    END AS status
FROM gold.fact_order_items
UNION ALL

SELECT 
    'Gold Fact Order Items - product_sk' AS test_name,
    COUNT(*) FILTER (WHERE product_sk IS NULL) AS null_count,
    COUNT(*) AS total_count,
    CASE 
        WHEN COUNT(*) FILTER (WHERE product_sk IS NULL) = 0 THEN 'PASS' 
        ELSE 'FAIL' 
    END AS status
FROM gold.fact_order_items
UNION ALL

SELECT 
    'Gold Fact Order Items - seller_sk' AS test_name,
    COUNT(*) FILTER (WHERE seller_sk IS NULL) AS null_count,
    COUNT(*) AS total_count,
    CASE 
        WHEN COUNT(*) FILTER (WHERE seller_sk IS NULL) = 0 THEN 'PASS' 
        ELSE 'FAIL' 
    END AS status
FROM gold.fact_order_items
UNION ALL

SELECT 
    'Gold Fact Payments - order_sk' AS test_name,
    COUNT(*) FILTER (WHERE order_sk IS NULL) AS null_count,
    COUNT(*) AS total_count,
    CASE 
        WHEN COUNT(*) FILTER (WHERE order_sk IS NULL) = 0 THEN 'PASS' 
        ELSE 'FAIL' 
    END AS status
FROM gold.fact_payments
UNION ALL

SELECT 
    'Gold Fact Reviews - order_sk' AS test_name,
    COUNT(*) FILTER (WHERE order_sk IS NULL) AS null_count,
    COUNT(*) AS total_count,
    CASE 
        WHEN COUNT(*) FILTER (WHERE order_sk IS NULL) = 0 THEN 'PASS' 
        ELSE 'FAIL' 
    END AS status
FROM gold.fact_reviews;

