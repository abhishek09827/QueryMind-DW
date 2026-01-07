-- =====================================================
-- TESTS: Foreign Key Integrity Validation
-- =====================================================
-- Purpose: Verify referential integrity between fact and dimension tables
--          Check that all foreign keys reference valid dimension records
-- =====================================================

-- =====================================================
-- 1. FACT_ORDERS FOREIGN KEY CHECKS
-- =====================================================

-- Check customer_sk references
SELECT 
    'Fact Orders - customer_sk FK' AS test_name,
    COUNT(*) AS orphaned_records,
    CASE 
        WHEN COUNT(*) = 0 THEN 'PASS' 
        ELSE 'FAIL' 
    END AS status
FROM gold.fact_orders fo
LEFT JOIN gold.dim_customer dc ON fo.customer_sk = dc.customer_sk
WHERE dc.customer_sk IS NULL
UNION ALL

-- Check purchase_date_sk references (non-null values only)
SELECT 
    'Fact Orders - purchase_date_sk FK' AS test_name,
    COUNT(*) AS orphaned_records,
    CASE 
        WHEN COUNT(*) = 0 THEN 'PASS' 
        ELSE 'FAIL' 
    END AS status
FROM gold.fact_orders fo
WHERE fo.purchase_date_sk IS NOT NULL
  AND NOT EXISTS (
      SELECT 1 FROM gold.dim_date dd 
      WHERE dd.date_sk = fo.purchase_date_sk
  )
UNION ALL

-- Check approved_date_sk references (non-null values only)
SELECT 
    'Fact Orders - approved_date_sk FK' AS test_name,
    COUNT(*) AS orphaned_records,
    CASE 
        WHEN COUNT(*) = 0 THEN 'PASS' 
        ELSE 'FAIL' 
    END AS status
FROM gold.fact_orders fo
WHERE fo.approved_date_sk IS NOT NULL
  AND NOT EXISTS (
      SELECT 1 FROM gold.dim_date dd 
      WHERE dd.date_sk = fo.approved_date_sk
  )
UNION ALL

-- Check delivered_customer_date_sk references (non-null values only)
SELECT 
    'Fact Orders - delivered_customer_date_sk FK' AS test_name,
    COUNT(*) AS orphaned_records,
    CASE 
        WHEN COUNT(*) = 0 THEN 'PASS' 
        ELSE 'FAIL' 
    END AS status
FROM gold.fact_orders fo
WHERE fo.delivered_customer_date_sk IS NOT NULL
  AND NOT EXISTS (
      SELECT 1 FROM gold.dim_date dd 
      WHERE dd.date_sk = fo.delivered_customer_date_sk
  )
UNION ALL

-- Check seller_sk references (non-null values only)
SELECT 
    'Fact Orders - seller_sk FK' AS test_name,
    COUNT(*) AS orphaned_records,
    CASE 
        WHEN COUNT(*) = 0 THEN 'PASS' 
        ELSE 'FAIL' 
    END AS status
FROM gold.fact_orders fo
WHERE fo.seller_sk IS NOT NULL
  AND NOT EXISTS (
      SELECT 1 FROM gold.dim_seller ds 
      WHERE ds.seller_sk = fo.seller_sk
  );

-- =====================================================
-- 2. FACT_ORDER_ITEMS FOREIGN KEY CHECKS
-- =====================================================

-- Check order_sk references
SELECT 
    'Fact Order Items - order_sk FK' AS test_name,
    COUNT(*) AS orphaned_records,
    CASE 
        WHEN COUNT(*) = 0 THEN 'PASS' 
        ELSE 'FAIL' 
    END AS status
FROM gold.fact_order_items foi
LEFT JOIN gold.fact_orders fo ON foi.order_sk = fo.order_sk
WHERE fo.order_sk IS NULL
UNION ALL

-- Check product_sk references
SELECT 
    'Fact Order Items - product_sk FK' AS test_name,
    COUNT(*) AS orphaned_records,
    CASE 
        WHEN COUNT(*) = 0 THEN 'PASS' 
        ELSE 'FAIL' 
    END AS status
FROM gold.fact_order_items foi
LEFT JOIN gold.dim_product dp ON foi.product_sk = dp.product_sk
WHERE dp.product_sk IS NULL
UNION ALL

-- Check seller_sk references
SELECT 
    'Fact Order Items - seller_sk FK' AS test_name,
    COUNT(*) AS orphaned_records,
    CASE 
        WHEN COUNT(*) = 0 THEN 'PASS' 
        ELSE 'FAIL' 
    END AS status
FROM gold.fact_order_items foi
LEFT JOIN gold.dim_seller ds ON foi.seller_sk = ds.seller_sk
WHERE ds.seller_sk IS NULL
UNION ALL

-- Check shipping_limit_date_sk references (non-null values only)
SELECT 
    'Fact Order Items - shipping_limit_date_sk FK' AS test_name,
    COUNT(*) AS orphaned_records,
    CASE 
        WHEN COUNT(*) = 0 THEN 'PASS' 
        ELSE 'FAIL' 
    END AS status
FROM gold.fact_order_items foi
WHERE foi.shipping_limit_date_sk IS NOT NULL
  AND NOT EXISTS (
      SELECT 1 FROM gold.dim_date dd 
      WHERE dd.date_sk = foi.shipping_limit_date_sk
  );

-- =====================================================
-- 3. FACT_PAYMENTS FOREIGN KEY CHECKS
-- =====================================================

-- Check order_sk references
SELECT 
    'Fact Payments - order_sk FK' AS test_name,
    COUNT(*) AS orphaned_records,
    CASE 
        WHEN COUNT(*) = 0 THEN 'PASS' 
        ELSE 'FAIL' 
    END AS status
FROM gold.fact_payments fp
LEFT JOIN gold.fact_orders fo ON fp.order_sk = fo.order_sk
WHERE fo.order_sk IS NULL;

-- =====================================================
-- 4. FACT_REVIEWS FOREIGN KEY CHECKS
-- =====================================================

-- Check order_sk references
SELECT 
    'Fact Reviews - order_sk FK' AS test_name,
    COUNT(*) AS orphaned_records,
    CASE 
        WHEN COUNT(*) = 0 THEN 'PASS' 
        ELSE 'FAIL' 
    END AS status
FROM gold.fact_reviews fr
LEFT JOIN gold.fact_orders fo ON fr.order_sk = fo.order_sk
WHERE fo.order_sk IS NULL
UNION ALL

-- Check review_creation_date_sk references (non-null values only)
SELECT 
    'Fact Reviews - review_creation_date_sk FK' AS test_name,
    COUNT(*) AS orphaned_records,
    CASE 
        WHEN COUNT(*) = 0 THEN 'PASS' 
        ELSE 'FAIL' 
    END AS status
FROM gold.fact_reviews fr
WHERE fr.review_creation_date_sk IS NOT NULL
  AND NOT EXISTS (
      SELECT 1 FROM gold.dim_date dd 
      WHERE dd.date_sk = fr.review_creation_date_sk
  )
UNION ALL

-- Check review_answer_timestamp_sk references (non-null values only)
SELECT 
    'Fact Reviews - review_answer_timestamp_sk FK' AS test_name,
    COUNT(*) AS orphaned_records,
    CASE 
        WHEN COUNT(*) = 0 THEN 'PASS' 
        ELSE 'FAIL' 
    END AS status
FROM gold.fact_reviews fr
WHERE fr.review_answer_timestamp_sk IS NOT NULL
  AND NOT EXISTS (
      SELECT 1 FROM gold.dim_date dd 
      WHERE dd.date_sk = fr.review_answer_timestamp_sk
  );

-- =====================================================
-- 5. CROSS-LAYER INTEGRITY CHECKS
-- =====================================================

-- Check that all orders in fact_orders exist in silver.orders
SELECT 
    'Fact Orders - All orders exist in Silver' AS test_name,
    COUNT(*) AS missing_records,
    CASE 
        WHEN COUNT(*) = 0 THEN 'PASS' 
        ELSE 'FAIL' 
    END AS status
FROM gold.fact_orders fo
LEFT JOIN silver.orders so ON fo.order_id = so.order_id
WHERE so.order_id IS NULL
UNION ALL

-- Check that all customers in dim_customer exist in silver.customers
SELECT 
    'Dim Customer - All customers exist in Silver' AS test_name,
    COUNT(*) AS missing_records,
    CASE 
        WHEN COUNT(*) = 0 THEN 'PASS' 
        ELSE 'FAIL' 
    END AS status
FROM gold.dim_customer dc
WHERE dc.is_current = TRUE
  AND NOT EXISTS (
      SELECT 1 FROM silver.customers sc 
      WHERE sc.customer_id = dc.customer_id
  )
UNION ALL

-- Check that all products in dim_product exist in silver.products
SELECT 
    'Dim Product - All products exist in Silver' AS test_name,
    COUNT(*) AS missing_records,
    CASE 
        WHEN COUNT(*) = 0 THEN 'PASS' 
        ELSE 'FAIL' 
    END AS status
FROM gold.dim_product dp
LEFT JOIN silver.products sp ON dp.product_id = sp.product_id
WHERE sp.product_id IS NULL
UNION ALL

-- Check that all sellers in dim_seller exist in silver.sellers
SELECT 
    'Dim Seller - All sellers exist in Silver' AS test_name,
    COUNT(*) AS missing_records,
    CASE 
        WHEN COUNT(*) = 0 THEN 'PASS' 
        ELSE 'FAIL' 
    END AS status
FROM gold.dim_seller ds
LEFT JOIN silver.sellers ss ON ds.seller_id = ss.seller_id
WHERE ss.seller_id IS NULL;

