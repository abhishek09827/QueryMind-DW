-- =====================================================
-- SILVER LAYER: Clean Geolocation Data
-- =====================================================
-- Purpose: Clean and standardize geolocation data from bronze layer
--          Apply: trim whitespace, lowercase cities, uppercase states,
--          validate coordinates, remove duplicates
-- =====================================================

-- Drop table if exists (for re-running)
DROP TABLE IF EXISTS silver.geolocation CASCADE;

-- Create cleaned geolocation table
CREATE TABLE silver.geolocation AS
SELECT DISTINCT
    -- Zip code prefix
    CASE 
        WHEN TRIM(geolocation_zip_code_prefix) = '' THEN NULL 
        ELSE TRIM(geolocation_zip_code_prefix) 
    END AS geolocation_zip_code_prefix,
    
    -- Coordinates (validate ranges: lat -90 to 90, lng -180 to 180)
    CASE 
        WHEN geolocation_lat IS NULL THEN NULL
        WHEN geolocation_lat < -90 THEN -90
        WHEN geolocation_lat > 90 THEN 90
        ELSE geolocation_lat
    END AS geolocation_lat,
    
    CASE 
        WHEN geolocation_lng IS NULL THEN NULL
        WHEN geolocation_lng < -180 THEN -180
        WHEN geolocation_lng > 180 THEN 180
        ELSE geolocation_lng
    END AS geolocation_lng,
    
    -- Location data (standardized)
    CASE 
        WHEN TRIM(geolocation_city) = '' THEN NULL 
        ELSE LOWER(TRIM(geolocation_city)) 
    END AS geolocation_city,
    
    CASE 
        WHEN TRIM(geolocation_state) = '' THEN NULL 
        ELSE UPPER(TRIM(geolocation_state)) 
    END AS geolocation_state
    
FROM bronze.geolocation
WHERE geolocation_zip_code_prefix IS NOT NULL
  AND TRIM(geolocation_zip_code_prefix) != '';

-- Create indexes
CREATE INDEX idx_silver_geolocation_zip ON silver.geolocation(geolocation_zip_code_prefix);
CREATE INDEX idx_silver_geolocation_state ON silver.geolocation(geolocation_state);
CREATE INDEX idx_silver_geolocation_city ON silver.geolocation(geolocation_city);

-- Verify cleaning results
SELECT 
    COUNT(*) as total_rows,
    COUNT(DISTINCT geolocation_zip_code_prefix) as unique_zip_codes,
    COUNT(DISTINCT geolocation_state) as unique_states,
    COUNT(DISTINCT geolocation_city) as unique_cities,
    AVG(geolocation_lat) as avg_latitude,
    AVG(geolocation_lng) as avg_longitude,
    MIN(geolocation_lat) as min_lat,
    MAX(geolocation_lat) as max_lat,
    MIN(geolocation_lng) as min_lng,
    MAX(geolocation_lng) as max_lng
FROM silver.geolocation;

