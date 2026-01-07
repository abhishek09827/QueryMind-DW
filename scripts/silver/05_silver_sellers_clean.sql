-- =====================================================
-- SILVER LAYER: Clean Sellers Data
-- =====================================================
-- Purpose: Clean and standardize sellers data from bronze layer
--          Apply: trim whitespace, lowercase cities, uppercase states,
--          remove duplicates
-- =====================================================

-- Drop table if exists (for re-running)
DROP TABLE IF EXISTS silver.sellers CASCADE;

-- Create cleaned sellers table
CREATE TABLE silver.sellers AS
SELECT DISTINCT
    -- Primary key
    TRIM(seller_id) AS seller_id,
    
    -- Location data (standardized)
    CASE 
        WHEN TRIM(seller_zip_code_prefix) = '' THEN NULL 
        ELSE TRIM(seller_zip_code_prefix) 
    END AS seller_zip_code_prefix,
    
    CASE 
        WHEN TRIM(seller_city) = '' THEN NULL 
        ELSE LOWER(TRIM(seller_city)) 
    END AS seller_city,
    
    CASE 
        WHEN TRIM(seller_state) = '' THEN NULL 
        ELSE UPPER(TRIM(seller_state)) 
    END AS seller_state
    
FROM bronze.sellers
WHERE seller_id IS NOT NULL
  AND TRIM(seller_id) != '';

-- Add primary key constraint
ALTER TABLE silver.sellers 
ADD PRIMARY KEY (seller_id);

-- Create indexes
CREATE INDEX idx_silver_sellers_state ON silver.sellers(seller_state);
CREATE INDEX idx_silver_sellers_city ON silver.sellers(seller_city);

-- Verify cleaning results
SELECT 
    COUNT(*) as total_rows,
    COUNT(DISTINCT seller_id) as unique_sellers,
    COUNT(DISTINCT seller_state) as unique_states,
    COUNT(DISTINCT seller_city) as unique_cities,
    COUNT(*) FILTER (WHERE seller_city IS NULL) as null_cities,
    COUNT(*) FILTER (WHERE seller_state IS NULL) as null_states
FROM silver.sellers;

