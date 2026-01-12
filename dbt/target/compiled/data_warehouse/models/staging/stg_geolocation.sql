

WITH source AS (
    SELECT * FROM "warehouse"."bronze"."geolocation"
)

SELECT DISTINCT
    CASE 
        WHEN TRIM(geolocation_zip_code_prefix) = '' THEN NULL 
        ELSE TRIM(geolocation_zip_code_prefix) 
    END AS geolocation_zip_code_prefix,
    
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
    
    CASE 
        WHEN TRIM(geolocation_city) = '' THEN NULL 
        ELSE LOWER(TRIM(geolocation_city)) 
    END AS geolocation_city,
    
    CASE 
        WHEN TRIM(geolocation_state) = '' THEN NULL 
        ELSE UPPER(TRIM(geolocation_state)) 
    END AS geolocation_state

FROM source
WHERE geolocation_zip_code_prefix IS NOT NULL
  AND TRIM(geolocation_zip_code_prefix) != ''