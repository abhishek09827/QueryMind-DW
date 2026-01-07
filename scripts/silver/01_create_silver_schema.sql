-- =====================================================
-- SILVER LAYER: Schema Creation
-- =====================================================
-- Purpose: Create the silver schema to store cleaned, standardized data
--          This is the second layer of the Medallion architecture
-- =====================================================

-- Create silver schema if it doesn't exist
CREATE SCHEMA IF NOT EXISTS silver;

-- Grant necessary permissions (adjust as needed for your environment)
-- GRANT USAGE ON SCHEMA silver TO <your_user>;
-- GRANT ALL ON SCHEMA silver TO <your_user>;

