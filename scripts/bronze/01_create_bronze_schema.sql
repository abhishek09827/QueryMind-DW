-- =====================================================
-- BRONZE LAYER: Schema Creation
-- =====================================================
-- Purpose: Create the bronze schema to store raw, unprocessed data
--          This is the first layer of the Medallion architecture
-- =====================================================

-- Create bronze schema if it doesn't exist
CREATE SCHEMA IF NOT EXISTS bronze;

-- Grant necessary permissions (adjust as needed for your environment)
-- GRANT USAGE ON SCHEMA bronze TO <your_user>;
-- GRANT ALL ON SCHEMA bronze TO <your_user>;

