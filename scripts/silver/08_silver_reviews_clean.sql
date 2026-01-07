-- =====================================================
-- SILVER LAYER: Clean Order Reviews Data
-- =====================================================
-- Purpose: Clean and standardize order reviews data from bronze layer
--          Apply: trim whitespace, convert dates, fix review text,
--          validate review scores
-- =====================================================

-- Drop table if exists (for re-running)
DROP TABLE IF EXISTS silver.order_reviews CASCADE;

-- Create cleaned order reviews table
CREATE TABLE silver.order_reviews AS
SELECT DISTINCT
    -- Primary key
    TRIM(review_id) AS review_id,
    
    -- Foreign key
    CASE 
        WHEN TRIM(order_id) = '' THEN NULL 
        ELSE TRIM(order_id) 
    END AS order_id,
    
    -- Review score (validate range 1-5)
    CASE 
        WHEN review_score IS NULL THEN NULL
        WHEN review_score < 1 THEN 1
        WHEN review_score > 5 THEN 5
        ELSE review_score
    END AS review_score,
    
    -- Review text (trimmed, empty strings become NULL)
    CASE 
        WHEN TRIM(review_comment_title) = '' THEN NULL 
        ELSE TRIM(review_comment_title) 
    END AS review_comment_title,
    
    CASE 
        WHEN TRIM(review_comment_message) = '' THEN NULL 
        ELSE TRIM(review_comment_message) 
    END AS review_comment_message,
    
    -- Timestamps
    CASE 
        WHEN TRIM(review_creation_date::TEXT) = '' THEN NULL 
        ELSE review_creation_date 
    END AS review_creation_date,
    
    CASE 
        WHEN TRIM(review_answer_timestamp::TEXT) = '' THEN NULL 
        ELSE review_answer_timestamp 
    END AS review_answer_timestamp
    
FROM bronze.order_reviews
WHERE review_id IS NOT NULL
  AND TRIM(review_id) != '';

-- Add primary key constraint
ALTER TABLE silver.order_reviews 
ADD PRIMARY KEY (review_id);

-- Create indexes
CREATE INDEX idx_silver_order_reviews_order_id ON silver.order_reviews(order_id);
CREATE INDEX idx_silver_order_reviews_score ON silver.order_reviews(review_score);

-- Verify cleaning results
SELECT 
    COUNT(*) as total_rows,
    COUNT(DISTINCT review_id) as unique_reviews,
    COUNT(DISTINCT order_id) as unique_orders,
    AVG(review_score) as avg_review_score,
    COUNT(*) FILTER (WHERE review_score IS NULL) as null_scores,
    COUNT(*) FILTER (WHERE review_comment_message IS NOT NULL) as reviews_with_comments,
    MIN(review_creation_date) as earliest_review,
    MAX(review_creation_date) as latest_review
FROM silver.order_reviews;

