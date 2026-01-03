-- =====================================================
-- BRONZE LAYER: Load Geolocation Data
-- =====================================================
-- Purpose: Load raw geolocation data from CSV into bronze layer
--          This is a direct copy with no transformations
-- =====================================================

-- Clear existing data (optional, for re-loading)
-- TRUNCATE TABLE bronze.geolocation;

-- Load data from CSV file
-- For PostgreSQL:
COPY bronze.geolocation 
FROM 'E:\Personal Projects\DataWarehouse\datasets\olist_geolocation_dataset.csv'
WITH (FORMAT CSV, HEADER TRUE, DELIMITER ',');

-- For DuckDB (alternative syntax):
-- COPY bronze.geolocation 
-- FROM 'E:\Personal Projects\DataWarehouse\datasets\olist_geolocation_dataset.csv'
-- (FORMAT CSV, HEADER TRUE, DELIMITER ',');

-- Verify load
SELECT 
    COUNT(*) as total_rows,
    COUNT(DISTINCT geolocation_zip_code_prefix) as unique_zip_codes,
    COUNT(DISTINCT geolocation_state) as unique_states,
    COUNT(DISTINCT geolocation_city) as unique_cities,
    AVG(geolocation_lat) as avg_latitude,
    AVG(geolocation_lng) as avg_longitude
FROM bronze.geolocation;

