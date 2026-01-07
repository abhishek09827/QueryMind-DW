-- =====================================================
-- SILVER LAYER: Clean Orders Data
-- =====================================================
-- Purpose: Clean and standardize orders data from bronze layer
--          Apply: trim whitespace, convert timestamps, normalize statuses,
--          validate date logic (delivered >= purchased)
-- =====================================================

-- Drop table if exists (for re-running)
DROP TABLE IF EXISTS silver.orders CASCADE;

-- Create cleaned orders table
CREATE TABLE silver.orders AS
SELECT DISTINCT
    -- Primary key
    TRIM(order_id) AS order_id,
    
    -- Foreign key
    CASE 
        WHEN TRIM(customer_id) = '' THEN NULL 
        ELSE TRIM(customer_id) 
    END AS customer_id,
    
    -- Normalized order status (lowercase, trimmed)
    CASE 
        WHEN TRIM(order_status) = '' THEN NULL 
        ELSE LOWER(TRIM(order_status)) 
    END AS order_status,
    
    -- Convert timestamps (handle empty strings and invalid dates)
    CASE 
        WHEN TRIM(order_purchase_timestamp::TEXT) = '' THEN NULL 
        ELSE order_purchase_timestamp 
    END AS order_purchase_timestamp,
    
    CASE 
        WHEN TRIM(order_approved_at::TEXT) = '' THEN NULL 
        ELSE order_approved_at 
    END AS order_approved_at,
    
    CASE 
        WHEN TRIM(order_delivered_carrier_date::TEXT) = '' THEN NULL 
        ELSE order_delivered_carrier_date 
    END AS order_delivered_carrier_date,
    
    CASE 
        WHEN TRIM(order_delivered_customer_date::TEXT) = '' THEN NULL 
        ELSE order_delivered_customer_date 
    END AS order_delivered_customer_date,
    
    CASE 
        WHEN TRIM(order_estimated_delivery_date::TEXT) = '' THEN NULL 
        ELSE order_estimated_delivery_date 
    END AS order_estimated_delivery_date
    
FROM bronze.orders
WHERE order_id IS NOT NULL
  AND TRIM(order_id) != '';

-- Filter out invalid date relationships
-- Remove orders where delivered date is before purchase date (data quality issue)
DELETE FROM silver.orders
WHERE order_delivered_customer_date IS NOT NULL
  AND order_purchase_timestamp IS NOT NULL
  AND order_delivered_customer_date < order_purchase_timestamp;

-- Add primary key constraint
ALTER TABLE silver.orders 
ADD PRIMARY KEY (order_id);

-- Create indexes
CREATE INDEX idx_silver_orders_customer_id ON silver.orders(customer_id);
CREATE INDEX idx_silver_orders_status ON silver.orders(order_status);
CREATE INDEX idx_silver_orders_purchase_date ON silver.orders(order_purchase_timestamp);

-- Verify cleaning results
SELECT 
    COUNT(*) as total_rows,
    COUNT(DISTINCT order_id) as unique_orders,
    COUNT(DISTINCT order_status) as unique_statuses,
    COUNT(*) FILTER (WHERE order_status IS NULL) as null_statuses,
    COUNT(*) FILTER (WHERE order_purchase_timestamp IS NULL) as null_purchase_dates,
    COUNT(*) FILTER (WHERE order_delivered_customer_date IS NOT NULL) as delivered_orders,
    MIN(order_purchase_timestamp) as earliest_order,
    MAX(order_purchase_timestamp) as latest_order
FROM silver.orders;

