

WITH source AS (
    SELECT * FROM "warehouse"."bronze"."order_reviews"
)

SELECT DISTINCT
    TRIM(review_id) AS review_id,
    
    CASE 
        WHEN TRIM(order_id) = '' THEN NULL 
        ELSE TRIM(order_id) 
    END AS order_id,
    
    CASE 
        WHEN review_score IS NULL THEN NULL
        WHEN review_score < 1 THEN 1
        WHEN review_score > 5 THEN 5
        ELSE review_score
    END AS review_score,
    
    CASE 
        WHEN TRIM(review_comment_title) = '' THEN NULL 
        ELSE TRIM(review_comment_title) 
    END AS review_comment_title,
    
    CASE 
        WHEN TRIM(review_comment_message) = '' THEN NULL 
        ELSE TRIM(review_comment_message) 
    END AS review_comment_message,
    
    CASE 
        WHEN TRIM(CAST(review_creation_date AS TEXT)) = '' THEN NULL 
        ELSE review_creation_date 
    END AS review_creation_date,
    
    CASE 
        WHEN TRIM(CAST(review_answer_timestamp AS TEXT)) = '' THEN NULL 
        ELSE review_answer_timestamp 
    END AS review_answer_timestamp

FROM source
WHERE review_id IS NOT NULL
  AND TRIM(review_id) != ''