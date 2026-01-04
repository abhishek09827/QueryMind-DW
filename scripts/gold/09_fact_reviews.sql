-- =====================================================
-- GOLD LAYER: Fact Reviews
-- =====================================================
-- Purpose: Create reviews fact table in star schema
--          Contains review metrics with foreign keys to dimensions
--          Includes: review_score, timestamps, order_sk
-- =====================================================

-- Drop table if exists (for re-running)
DROP TABLE IF EXISTS gold.fact_reviews CASCADE;

-- Create reviews fact table
CREATE TABLE gold.fact_reviews (
    review_sk SERIAL PRIMARY KEY,  -- Surrogate key
    review_id VARCHAR(50) NOT NULL UNIQUE,
    order_id VARCHAR(50) NOT NULL,
    order_sk INTEGER NOT NULL,
    review_score INTEGER,  -- 1-5 scale
    review_comment_title VARCHAR(255),
    review_comment_message TEXT,
    review_creation_date_sk INTEGER,
    review_answer_timestamp_sk INTEGER,
    review_creation_date TIMESTAMP,
    review_answer_timestamp TIMESTAMP,
    has_comment BOOLEAN,  -- Whether review has a comment message
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (order_sk) REFERENCES gold.fact_orders(order_sk),
    FOREIGN KEY (review_creation_date_sk) REFERENCES gold.dim_date(date_sk),
    FOREIGN KEY (review_answer_timestamp_sk) REFERENCES gold.dim_date(date_sk)
);

-- Insert reviews fact data
INSERT INTO gold.fact_reviews (
    review_id,
    order_id,
    order_sk,
    review_score,
    review_comment_title,
    review_comment_message,
    review_creation_date_sk,
    review_answer_timestamp_sk,
    review_creation_date,
    review_answer_timestamp,
    has_comment
)
SELECT 
    orv.review_id,
    orv.order_id,
    fo.order_sk,
    orv.review_score,
    orv.review_comment_title,
    orv.review_comment_message,
    dcreate.date_sk AS review_creation_date_sk,
    danswer.date_sk AS review_answer_timestamp_sk,
    orv.review_creation_date,
    orv.review_answer_timestamp,
    CASE 
        WHEN orv.review_comment_message IS NOT NULL THEN TRUE 
        ELSE FALSE 
    END AS has_comment
FROM silver.order_reviews orv
INNER JOIN gold.fact_orders fo 
    ON orv.order_id = fo.order_id
LEFT JOIN gold.dim_date dcreate 
    ON DATE(orv.review_creation_date) = dcreate.date_actual
LEFT JOIN gold.dim_date danswer 
    ON DATE(orv.review_answer_timestamp) = danswer.date_actual
WHERE orv.review_id IS NOT NULL
  AND orv.order_id IS NOT NULL;

-- Create indexes
CREATE INDEX idx_fact_reviews_order_sk ON gold.fact_reviews(order_sk);
CREATE INDEX idx_fact_reviews_order_id ON gold.fact_reviews(order_id);
CREATE INDEX idx_fact_reviews_score ON gold.fact_reviews(review_score);
CREATE INDEX idx_fact_reviews_review_id ON gold.fact_reviews(review_id);

-- Verify fact table
SELECT 
    COUNT(*) as total_reviews,
    COUNT(DISTINCT order_id) as unique_orders,
    COUNT(DISTINCT review_id) as unique_reviews,
    AVG(review_score) as avg_review_score,
    COUNT(*) FILTER (WHERE review_score = 5) as five_star_reviews,
    COUNT(*) FILTER (WHERE review_score = 1) as one_star_reviews,
    COUNT(*) FILTER (WHERE has_comment = TRUE) as reviews_with_comments
FROM gold.fact_reviews;

