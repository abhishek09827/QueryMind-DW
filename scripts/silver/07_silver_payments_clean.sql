-- =====================================================
-- SILVER LAYER: Clean Order Payments Data
-- =====================================================
-- Purpose: Clean and standardize order payments data from bronze layer
--          Apply: trim whitespace, lowercase payment types, ensure valid values,
--          validate payment amounts
-- =====================================================

-- Drop table if exists (for re-running)
DROP TABLE IF EXISTS silver.order_payments CASCADE;

-- Create cleaned order payments table
CREATE TABLE silver.order_payments AS
SELECT DISTINCT
    -- Foreign key
    TRIM(order_id) AS order_id,
    
    -- Payment sequence
    COALESCE(payment_sequential, 1) AS payment_sequential,
    
    -- Payment type (lowercase, trimmed)
    CASE 
        WHEN TRIM(payment_type) = '' THEN NULL 
        ELSE LOWER(TRIM(payment_type)) 
    END AS payment_type,
    
    -- Installments (ensure valid positive integer)
    CASE 
        WHEN payment_installments IS NULL OR payment_installments < 1 THEN 1 
        ELSE payment_installments 
    END AS payment_installments,
    
    -- Payment value (ensure non-negative)
    CASE 
        WHEN payment_value IS NULL OR payment_value < 0 THEN 0 
        ELSE ROUND(CAST(payment_value AS DECIMAL(10, 2)), 2) 
    END AS payment_value
    
FROM bronze.order_payments
WHERE order_id IS NOT NULL
  AND TRIM(order_id) != ''
  AND payment_sequential IS NOT NULL;

-- Add primary key constraint
ALTER TABLE silver.order_payments 
ADD PRIMARY KEY (order_id, payment_sequential);

-- Create indexes
CREATE INDEX idx_silver_order_payments_order_id ON silver.order_payments(order_id);
CREATE INDEX idx_silver_order_payments_type ON silver.order_payments(payment_type);

-- Verify cleaning results
SELECT 
    COUNT(*) as total_rows,
    COUNT(DISTINCT order_id) as unique_orders,
    COUNT(DISTINCT payment_type) as unique_payment_types,
    SUM(payment_value) as total_payment_value,
    AVG(payment_value) as avg_payment_value,
    AVG(payment_installments) as avg_installments,
    MAX(payment_installments) as max_installments
FROM silver.order_payments;

