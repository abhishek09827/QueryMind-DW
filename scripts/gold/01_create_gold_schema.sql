-- =====================================================
-- GOLD LAYER: Schema Creation
-- =====================================================
-- Purpose: Create the gold schema to store dimensional model (Star Schema)
--          This is the third layer of the Medallion architecture
--          Contains fact and dimension tables for analytics
-- =====================================================

-- Create gold schema if it doesn't exist
CREATE SCHEMA IF NOT EXISTS gold;

-- Grant necessary permissions (adjust as needed for your environment)
-- GRANT USAGE ON SCHEMA gold TO <your_user>;
-- GRANT ALL ON SCHEMA gold TO <your_user>;

