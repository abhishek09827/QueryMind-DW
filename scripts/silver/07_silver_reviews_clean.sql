-- =====================================================
-- SILVER LAYER: Clean Order Reviews Data
-- =====================================================
-- Purpose: Clean and standardize order reviews data from bronze layer
--          Apply: trim whitespace, convert dates, fix review text,
--          validate review scores
-- =====================================================

-- Drop table if exists (for re-running)
DROP TABLE IF EXISTS silver.order_reviews CASCADE;

CREATE TABLE silver.order_reviews AS
SELECT
    review_id,
    order_id,
    review_score,
    review_comment_title,
    review_comment_message,
    review_creation_date,
    review_answer_timestamp
FROM (
    SELECT
        TRIM(review_id) AS review_id,

        NULLIF(TRIM(order_id), '') AS order_id,

        CASE 
            WHEN review_score < 1 THEN 1
            WHEN review_score > 5 THEN 5
            ELSE review_score
        END AS review_score,

        NULLIF(TRIM(review_comment_title), '') AS review_comment_title,
        NULLIF(TRIM(review_comment_message), '') AS review_comment_message,

        review_creation_date,
        review_answer_timestamp,

        ROW_NUMBER() OVER (
            PARTITION BY TRIM(review_id)
            ORDER BY 
                review_answer_timestamp DESC NULLS LAST,
                review_creation_date DESC NULLS LAST
        ) AS rn
    FROM bronze.order_reviews
    WHERE review_id IS NOT NULL
      AND TRIM(review_id) <> ''
) t
WHERE rn = 1;

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

