-- =====================================================
-- GOLD LAYER: Fact Payments
-- =====================================================
-- Purpose: Create payments fact table in star schema
--          Contains payment metrics with foreign keys to dimensions
--          Includes: payment_type, installments, value, order_sk
-- =====================================================

-- Drop table if exists (for re-running)
DROP TABLE IF EXISTS gold.fact_payments CASCADE;

-- Create payments fact table
CREATE TABLE gold.fact_payments (
    payment_sk SERIAL PRIMARY KEY,  -- Surrogate key
    order_id VARCHAR(50) NOT NULL,
    order_sk INTEGER NOT NULL,
    payment_sequential INTEGER NOT NULL,
    payment_type VARCHAR(20),
    payment_installments INTEGER NOT NULL,
    payment_value DECIMAL(10, 2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (order_sk) REFERENCES gold.fact_orders(order_sk),
    UNIQUE (order_id, payment_sequential)
);

-- Insert payments fact data
INSERT INTO gold.fact_payments (
    order_id,
    order_sk,
    payment_sequential,
    payment_type,
    payment_installments,
    payment_value
)
SELECT 
    op.order_id,
    fo.order_sk,
    op.payment_sequential,
    op.payment_type,
    op.payment_installments,
    op.payment_value
FROM silver.order_payments op
INNER JOIN gold.fact_orders fo 
    ON op.order_id = fo.order_id
WHERE op.order_id IS NOT NULL;

-- Create indexes
CREATE INDEX idx_fact_payments_order_sk ON gold.fact_payments(order_sk);
CREATE INDEX idx_fact_payments_order_id ON gold.fact_payments(order_id);
CREATE INDEX idx_fact_payments_type ON gold.fact_payments(payment_type);

-- Verify fact table
SELECT 
    COUNT(*) as total_payments,
    COUNT(DISTINCT order_id) as unique_orders,
    COUNT(DISTINCT payment_type) as unique_payment_types,
    SUM(payment_value) as total_payment_value,
    AVG(payment_value) as avg_payment_value,
    AVG(payment_installments) as avg_installments,
    MAX(payment_installments) as max_installments
FROM gold.fact_payments;

