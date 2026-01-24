-- =====================================================
-- SILVER LAYER: Clean Products Data
-- =====================================================
-- Purpose: Clean and standardize products data from bronze layer
--          Apply: trim whitespace, lowercase text, convert numeric attributes,
--          handle missing values
-- =====================================================

-- Drop table if exists (for re-running)
DROP TABLE IF EXISTS silver.products CASCADE;

-- Create cleaned products table
CREATE TABLE silver.products AS
SELECT DISTINCT
    -- Primary key
    TRIM(product_id) AS product_id,
    
    -- Category (lowercase, trimmed)
    CASE 
        WHEN TRIM(product_category_name) = '' THEN NULL 
        ELSE LOWER(TRIM(product_category_name)) 
    END AS product_category_name,
    
    -- Numeric attributes (handle NULLs and invalid values)
    COALESCE(product_name_lenght, 0) AS product_name_length,
    COALESCE(product_description_lenght, 0) AS product_description_length,
    COALESCE(product_photos_qty, 0) AS product_photos_qty,
    
    -- Weight and dimensions (ensure non-negative)
    CASE 
        WHEN product_weight_g IS NULL OR product_weight_g < 0 THEN 0 
        ELSE product_weight_g 
    END AS product_weight_g,
    
    CASE 
        WHEN product_length_cm IS NULL OR product_length_cm < 0 THEN 0 
        ELSE product_length_cm 
    END AS product_length_cm,
    
    CASE 
        WHEN product_height_cm IS NULL OR product_height_cm < 0 THEN 0 
        ELSE product_height_cm 
    END AS product_height_cm,
    
    CASE 
        WHEN product_width_cm IS NULL OR product_width_cm < 0 THEN 0 
        ELSE product_width_cm 
    END AS product_width_cm,
    'olist'::TEXT              AS source_system,
    CURRENT_DATE               AS ingestion_date,
    CURRENT_TIMESTAMP          AS created_at,
    CURRENT_TIMESTAMP          AS updated_at,
    TRUE                        AS is_active
    
FROM bronze.products
WHERE product_id IS NOT NULL
  AND TRIM(product_id) != '';

-- Add primary key constraint
ALTER TABLE silver.products 
ADD PRIMARY KEY (product_id);

-- Create indexes
CREATE INDEX idx_silver_products_category ON silver.products(product_category_name);

-- Verify cleaning results
SELECT 
    COUNT(*) as total_rows,
    COUNT(DISTINCT product_id) as unique_products,
    COUNT(DISTINCT product_category_name) as unique_categories,
    COUNT(*) FILTER (WHERE product_category_name IS NULL) as null_categories,
    AVG(product_weight_g) as avg_weight,
    AVG(product_length_cm) as avg_length,
    AVG(product_height_cm) as avg_height,
    AVG(product_width_cm) as avg_width
FROM silver.products;

