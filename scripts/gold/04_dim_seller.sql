-- =====================================================
-- GOLD LAYER: Dimension Seller
-- =====================================================
-- Purpose: Create seller dimension table
--          Contains seller location and attributes
-- =====================================================

-- Drop table if exists (for re-running)
DROP TABLE IF EXISTS gold.dim_seller CASCADE;

-- Create seller dimension table
CREATE TABLE gold.dim_seller (
    seller_sk SERIAL PRIMARY KEY,  -- Surrogate key
    seller_id VARCHAR(50) NOT NULL UNIQUE,
    seller_zip_code_prefix VARCHAR(10),
    seller_city VARCHAR(100),
    seller_state VARCHAR(2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert seller data from silver layer
INSERT INTO gold.dim_seller (
    seller_id,
    seller_zip_code_prefix,
    seller_city,
    seller_state
)
SELECT 
    s.seller_id,
    s.seller_zip_code_prefix,
    s.seller_city,
    s.seller_state
FROM silver.sellers s
WHERE s.seller_id IS NOT NULL;

-- Create indexes
CREATE INDEX idx_dim_seller_id ON gold.dim_seller(seller_id);
CREATE INDEX idx_dim_seller_state ON gold.dim_seller(seller_state);
CREATE INDEX idx_dim_seller_city ON gold.dim_seller(seller_city);

-- Verify dimension
SELECT 
    COUNT(*) as total_sellers,
    COUNT(DISTINCT seller_id) as unique_sellers,
    COUNT(DISTINCT seller_state) as unique_states,
    COUNT(DISTINCT seller_city) as unique_cities
FROM gold.dim_seller;

