

WITH payments AS (
    SELECT * FROM "warehouse"."public_silver"."stg_order_payments"
),
fact_orders AS (
    SELECT * FROM "warehouse"."public_gold"."fact_orders"
)

SELECT
    ROW_NUMBER() OVER (ORDER BY p.order_id, p.payment_sequential) AS payment_sk,
    p.order_id,
    fo.order_sk,
    p.payment_sequential,
    p.payment_type,
    p.payment_installments,
    p.payment_value,
    CURRENT_TIMESTAMP AS created_at

FROM payments p
INNER JOIN fact_orders fo ON p.order_id = fo.order_id