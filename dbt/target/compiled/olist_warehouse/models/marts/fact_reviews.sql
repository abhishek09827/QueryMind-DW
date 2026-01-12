

WITH reviews AS (
    SELECT * FROM "warehouse"."public_silver"."stg_reviews"
),
fact_orders AS (
    SELECT * FROM "warehouse"."public_gold"."fact_orders"
),
dim_date AS (
    SELECT * FROM "warehouse"."public_gold"."dim_date"
)

SELECT
    ROW_NUMBER() OVER (ORDER BY r.review_id) AS review_sk,
    r.review_id,
    r.order_id,
    fo.order_sk,
    r.review_score,
    r.review_comment_title,
    r.review_comment_message,
    dcreate.date_sk AS review_creation_date_sk,
    danswer.date_sk AS review_answer_timestamp_sk,
    r.review_creation_date,
    r.review_answer_timestamp,
    CASE 
        WHEN r.review_comment_message IS NOT NULL THEN TRUE 
        ELSE FALSE 
    END AS has_comment,
    CURRENT_TIMESTAMP AS created_at

FROM reviews r
INNER JOIN fact_orders fo ON r.order_id = fo.order_id
LEFT JOIN dim_date dcreate ON DATE(r.review_creation_date) = dcreate.date_actual
LEFT JOIN dim_date danswer ON DATE(r.review_answer_timestamp) = danswer.date_actual