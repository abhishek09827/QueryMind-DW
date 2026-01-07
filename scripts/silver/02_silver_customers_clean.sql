-- =====================================================
-- SILVER LAYER: Clean Customers Data
-- =====================================================
-- Purpose: Clean and standardize customers data from bronze layer
--          Apply: trim whitespace, lowercase, remove duplicates,
--          replace empty strings with NULL, standardize cities/states
-- =====================================================

-- Drop table if exists (for re-running)
DROP TABLE IF EXISTS silver.customers CASCADE;

-- Create cleaned customers table
CREATE TABLE silver.customers AS
SELECT DISTINCT
    -- Primary keys
    TRIM(customer_id) AS customer_id,
    TRIM(customer_unique_id) AS customer_unique_id,
    
    -- Location data (standardized)
    CASE 
        WHEN TRIM(customer_zip_code_prefix) = '' THEN NULL 
        ELSE TRIM(customer_zip_code_prefix) 
    END AS customer_zip_code_prefix,
    
    CASE 
        WHEN TRIM(customer_city) = '' THEN NULL 
        ELSE LOWER(TRIM(customer_city)) 
    END AS customer_city,
    
    CASE 
        WHEN TRIM(customer_state) = '' THEN NULL 
        ELSE UPPER(TRIM(customer_state)) 
    END AS customer_state
    
FROM bronze.customers
WHERE customer_id IS NOT NULL
  AND customer_unique_id IS NOT NULL
  AND TRIM(customer_id) != ''
  AND TRIM(customer_unique_id) != '';

-- Add primary key constraint
ALTER TABLE silver.customers 
ADD PRIMARY KEY (customer_id);

-- Create indexes
CREATE INDEX idx_silver_customers_unique_id ON silver.customers(customer_unique_id);
CREATE INDEX idx_silver_customers_state ON silver.customers(customer_state);
CREATE INDEX idx_silver_customers_city ON silver.customers(customer_city);

-- Verify cleaning results
SELECT 
    COUNT(*) as total_rows,
    COUNT(DISTINCT customer_id) as unique_customer_ids,
    COUNT(DISTINCT customer_unique_id) as unique_customers,
    COUNT(*) FILTER (WHERE customer_city IS NULL) as null_cities,
    COUNT(*) FILTER (WHERE customer_state IS NULL) as null_states,
    COUNT(DISTINCT customer_state) as unique_states
FROM silver.customers;

