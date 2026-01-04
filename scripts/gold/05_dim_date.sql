-- =====================================================
-- GOLD LAYER: Dimension Date
-- =====================================================
-- Purpose: Create date dimension table (full 5-year calendar)
--          Contains all dates from 2016 to 2020 (covers Olist dataset period)
--          Includes date attributes for time-based analysis
-- =====================================================

-- Drop table if exists (for re-running)
DROP TABLE IF EXISTS gold.dim_date CASCADE;

-- Create date dimension table
CREATE TABLE gold.dim_date (
    date_sk INTEGER PRIMARY KEY,  -- Surrogate key (YYYYMMDD format)
    date_actual DATE NOT NULL UNIQUE,
    day_of_week INTEGER,  -- 1=Monday, 7=Sunday
    day_name VARCHAR(10),
    day_of_month INTEGER,
    day_of_year INTEGER,
    week_of_year INTEGER,
    month_number INTEGER,
    month_name VARCHAR(10),
    quarter_number INTEGER,
    quarter_name VARCHAR(2),  -- Q1, Q2, Q3, Q4
    year_number INTEGER,
    is_weekend BOOLEAN,
    is_month_start BOOLEAN,
    is_month_end BOOLEAN,
    is_quarter_start BOOLEAN,
    is_quarter_end BOOLEAN,
    is_year_start BOOLEAN,
    is_year_end BOOLEAN
);

-- Generate date dimension for 5 years (2016-2020)
-- This covers the Olist dataset time period
INSERT INTO gold.dim_date
SELECT 
    -- Surrogate key: YYYYMMDD format
    CAST(TO_CHAR(date_series, 'YYYYMMDD') AS INTEGER) AS date_sk,
    
    date_series AS date_actual,
    
    -- Day attributes
    EXTRACT(DOW FROM date_series) + 1 AS day_of_week,  -- PostgreSQL: 0=Sunday, so +1 to make 1=Monday
    TO_CHAR(date_series, 'Day') AS day_name,
    EXTRACT(DAY FROM date_series) AS day_of_month,
    EXTRACT(DOY FROM date_series) AS day_of_year,
    EXTRACT(WEEK FROM date_series) AS week_of_year,
    
    -- Month attributes
    EXTRACT(MONTH FROM date_series) AS month_number,
    TO_CHAR(date_series, 'Month') AS month_name,
    
    -- Quarter attributes
    EXTRACT(QUARTER FROM date_series) AS quarter_number,
    'Q' || EXTRACT(QUARTER FROM date_series) AS quarter_name,
    
    -- Year
    EXTRACT(YEAR FROM date_series) AS year_number,
    
    -- Boolean flags
    EXTRACT(DOW FROM date_series) IN (0, 6) AS is_weekend,  -- Sunday or Saturday
    date_series = DATE_TRUNC('month', date_series) AS is_month_start,
    date_series = (DATE_TRUNC('month', date_series) + INTERVAL '1 month' - INTERVAL '1 day') AS is_month_end,
    date_series = DATE_TRUNC('quarter', date_series) AS is_quarter_start,
    date_series = (DATE_TRUNC('quarter', date_series) + INTERVAL '3 months' - INTERVAL '1 day') AS is_quarter_end,
    date_series = DATE_TRUNC('year', date_series) AS is_year_start,
    date_series = (DATE_TRUNC('year', date_series) + INTERVAL '1 year' - INTERVAL '1 day') AS is_year_end
    
FROM (
    -- Generate date series from 2016-01-01 to 2020-12-31
    SELECT generate_series(
        '2016-01-01'::DATE,
        '2020-12-31'::DATE,
        '1 day'::INTERVAL
    )::DATE AS date_series
) dates;

-- Create indexes
CREATE INDEX idx_dim_date_actual ON gold.dim_date(date_actual);
CREATE INDEX idx_dim_date_year ON gold.dim_date(year_number);
CREATE INDEX idx_dim_date_month ON gold.dim_date(year_number, month_number);
CREATE INDEX idx_dim_date_quarter ON gold.dim_date(year_number, quarter_number);

-- Verify dimension
SELECT 
    COUNT(*) as total_dates,
    MIN(date_actual) as min_date,
    MAX(date_actual) as max_date,
    COUNT(*) FILTER (WHERE is_weekend = TRUE) as weekend_days,
    COUNT(DISTINCT year_number) as unique_years,
    COUNT(DISTINCT quarter_number) as unique_quarters
FROM gold.dim_date;

