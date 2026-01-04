-- =====================================================
-- GOLD LAYER: Dimension Product
-- =====================================================
-- Purpose: Create product dimension table
--          Contains product attributes for dimensional analysis
-- =====================================================

-- Drop table if exists (for re-running)
DROP TABLE IF EXISTS gold.dim_product CASCADE;

-- Create product dimension table
CREATE TABLE gold.dim_product (
    product_sk SERIAL PRIMARY KEY,  -- Surrogate key
    product_id VARCHAR(50) NOT NULL UNIQUE,
    product_category_name VARCHAR(100),
    product_name_length INTEGER DEFAULT 0,
    product_description_length INTEGER DEFAULT 0,
    product_photos_qty INTEGER DEFAULT 0,
    product_weight_g INTEGER DEFAULT 0,
    product_length_cm INTEGER DEFAULT 0,
    product_height_cm INTEGER DEFAULT 0,
    product_width_cm INTEGER DEFAULT 0,
    product_volume_cm3 INTEGER,  -- Calculated: length * height * width
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert product data from silver layer
INSERT INTO gold.dim_product (
    product_id,
    product_category_name,
    product_name_length,
    product_description_length,
    product_photos_qty,
    product_weight_g,
    product_length_cm,
    product_height_cm,
    product_width_cm,
    product_volume_cm3
)
SELECT 
    p.product_id,
    p.product_category_name,
    p.product_name_length,
    p.product_description_length,
    p.product_photos_qty,
    p.product_weight_g,
    p.product_length_cm,
    p.product_height_cm,
    p.product_width_cm,
    -- Calculate volume (handle NULLs)
    CASE 
        WHEN p.product_length_cm > 0 
         AND p.product_height_cm > 0 
         AND p.product_width_cm > 0 
        THEN p.product_length_cm * p.product_height_cm * p.product_width_cm
        ELSE 0
    END AS product_volume_cm3
FROM silver.products p
WHERE p.product_id IS NOT NULL;

-- Create indexes
CREATE INDEX idx_dim_product_category ON gold.dim_product(product_category_name);
CREATE INDEX idx_dim_product_id ON gold.dim_product(product_id);

-- Verify dimension
SELECT 
    COUNT(*) as total_products,
    COUNT(DISTINCT product_id) as unique_products,
    COUNT(DISTINCT product_category_name) as unique_categories,
    COUNT(*) FILTER (WHERE product_category_name IS NULL) as null_categories,
    AVG(product_weight_g) as avg_weight,
    AVG(product_volume_cm3) as avg_volume
FROM gold.dim_product;

