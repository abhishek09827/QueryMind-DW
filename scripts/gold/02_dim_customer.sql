-- =====================================================
-- GOLD LAYER: Dimension Customer (SCD Type 2)
-- =====================================================
-- Purpose: Create customer dimension with Slowly Changing Dimension Type 2
--          Tracks historical changes to customer location data
--          Includes: customer_sk (surrogate key), customer_id, unique_id,
--          city, state, start_date, end_date, is_current
-- =====================================================

-- Drop table if exists (for re-running)
DROP TABLE IF EXISTS gold.dim_customer CASCADE;

-- Create customer dimension table with SCD Type 2
CREATE TABLE gold.dim_customer (
    customer_sk SERIAL PRIMARY KEY,  -- Surrogate key (auto-increment)
    customer_id VARCHAR(50) NOT NULL,
    customer_unique_id VARCHAR(50) NOT NULL,
    customer_zip_code_prefix VARCHAR(10),
    customer_city VARCHAR(100),
    customer_state VARCHAR(2),
    start_date DATE NOT NULL,
    end_date DATE,
    is_current BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for performance
CREATE INDEX idx_dim_customer_customer_id ON gold.dim_customer(customer_id);
CREATE INDEX idx_dim_customer_unique_id ON gold.dim_customer(customer_unique_id);
CREATE INDEX idx_dim_customer_current ON gold.dim_customer(is_current);
CREATE INDEX idx_dim_customer_state ON gold.dim_customer(customer_state);

-- Insert initial customer records with SCD Type 2 logic
-- For simplicity, we'll treat all current records as active
-- In production, you would implement change detection logic
INSERT INTO gold.dim_customer (
    customer_id,
    customer_unique_id,
    customer_zip_code_prefix,
    customer_city,
    customer_state,
    start_date,
    end_date,
    is_current
)
SELECT DISTINCT
    c.customer_id,
    c.customer_unique_id,
    c.customer_zip_code_prefix,
    c.customer_city,
    c.customer_state,
    CURRENT_DATE::DATE               AS start_date,
    NULL::DATE                       AS end_date,
    TRUE::BOOLEAN                    AS is_current
FROM silver.customers c
WHERE c.customer_id IS NOT NULL
  AND c.customer_unique_id IS NOT NULL;

-- Verify dimension
SELECT 
    COUNT(*) as total_records,
    COUNT(*) FILTER (WHERE is_current = TRUE) as current_records,
    COUNT(*) FILTER (WHERE is_current = FALSE) as historical_records,
    COUNT(DISTINCT customer_id) as unique_customer_ids,
    COUNT(DISTINCT customer_unique_id) as unique_customers,
    COUNT(DISTINCT customer_state) as unique_states
FROM gold.dim_customer;

