-- =====================================================
-- GOLD LAYER: Fact Orders
-- =====================================================
-- Purpose: Create orders fact table in star schema
--          Contains order metrics and foreign keys to dimensions
--          Includes: order_sk, customer_sk, seller_sk, date_sk,
--          order_status, delivery delay, processing time
-- =====================================================

-- Drop table if exists (for re-running)
DROP TABLE IF EXISTS gold.fact_orders CASCADE;

-- Create orders fact table
CREATE TABLE gold.fact_orders (
    order_sk SERIAL PRIMARY KEY,  -- Surrogate key
    order_id VARCHAR(50) NOT NULL UNIQUE,
    customer_sk INTEGER NOT NULL,
    seller_sk INTEGER,  -- Primary seller (first seller for the order)
    purchase_date_sk INTEGER,
    approved_date_sk INTEGER,
    delivered_carrier_date_sk INTEGER,
    delivered_customer_date_sk INTEGER,
    estimated_delivery_date_sk INTEGER,
    order_status VARCHAR(20),
    order_purchase_timestamp TIMESTAMP,
    order_approved_at TIMESTAMP,
    order_delivered_carrier_date TIMESTAMP,
    order_delivered_customer_date TIMESTAMP,
    order_estimated_delivery_date TIMESTAMP,
    -- Calculated metrics
    approval_time_hours DECIMAL(10, 2),  -- Time from purchase to approval
    carrier_handoff_time_hours DECIMAL(10, 2),  -- Time from approval to carrier
    delivery_time_hours DECIMAL(10, 2),  -- Time from carrier to customer
    total_processing_time_hours DECIMAL(10, 2),  -- Total time from purchase to delivery
    delivery_delay_days INTEGER,  -- Difference between estimated and actual delivery
    is_delivered_on_time BOOLEAN,  -- Whether delivered before estimated date
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_sk) REFERENCES gold.dim_customer(customer_sk),
    FOREIGN KEY (seller_sk) REFERENCES gold.dim_seller(seller_sk),
    FOREIGN KEY (purchase_date_sk) REFERENCES gold.dim_date(date_sk),
    FOREIGN KEY (approved_date_sk) REFERENCES gold.dim_date(date_sk),
    FOREIGN KEY (delivered_carrier_date_sk) REFERENCES gold.dim_date(date_sk),
    FOREIGN KEY (delivered_customer_date_sk) REFERENCES gold.dim_date(date_sk),
    FOREIGN KEY (estimated_delivery_date_sk) REFERENCES gold.dim_date(date_sk)
);

-- Insert orders fact data
INSERT INTO gold.fact_orders (
    order_id,
    customer_sk,
    seller_sk,
    purchase_date_sk,
    approved_date_sk,
    delivered_carrier_date_sk,
    delivered_customer_date_sk,
    estimated_delivery_date_sk,
    order_status,
    order_purchase_timestamp,
    order_approved_at,
    order_delivered_carrier_date,
    order_delivered_customer_date,
    order_estimated_delivery_date,
    approval_time_hours,
    carrier_handoff_time_hours,
    delivery_time_hours,
    total_processing_time_hours,
    delivery_delay_days,
    is_delivered_on_time
)
SELECT 
    o.order_id,
    dc.customer_sk,
    ds.seller_sk,  -- Primary seller (first seller for the order)
    dpurchase.date_sk AS purchase_date_sk,
    dapproved.date_sk AS approved_date_sk,
    dcarrier.date_sk AS delivered_carrier_date_sk,
    ddelivered.date_sk AS delivered_customer_date_sk,
    destimated.date_sk AS estimated_delivery_date_sk,
    o.order_status,
    o.order_purchase_timestamp,
    o.order_approved_at,
    o.order_delivered_carrier_date,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date,
    -- Calculate approval time (hours)
    CASE 
        WHEN o.order_approved_at IS NOT NULL AND o.order_purchase_timestamp IS NOT NULL
        THEN EXTRACT(EPOCH FROM (o.order_approved_at - o.order_purchase_timestamp)) / 3600.0
        ELSE NULL
    END AS approval_time_hours,
    -- Calculate carrier handoff time (hours)
    CASE 
        WHEN o.order_delivered_carrier_date IS NOT NULL AND o.order_approved_at IS NOT NULL
        THEN EXTRACT(EPOCH FROM (o.order_delivered_carrier_date - o.order_approved_at)) / 3600.0
        ELSE NULL
    END AS carrier_handoff_time_hours,
    -- Calculate delivery time (hours)
    CASE 
        WHEN o.order_delivered_customer_date IS NOT NULL AND o.order_delivered_carrier_date IS NOT NULL
        THEN EXTRACT(EPOCH FROM (o.order_delivered_customer_date - o.order_delivered_carrier_date)) / 3600.0
        ELSE NULL
    END AS delivery_time_hours,
    -- Calculate total processing time (hours)
    CASE 
        WHEN o.order_delivered_customer_date IS NOT NULL AND o.order_purchase_timestamp IS NOT NULL
        THEN EXTRACT(EPOCH FROM (o.order_delivered_customer_date - o.order_purchase_timestamp)) / 3600.0
        ELSE NULL
    END AS total_processing_time_hours,
    -- Calculate delivery delay (days)
    CASE 
        WHEN o.order_delivered_customer_date IS NOT NULL AND o.order_estimated_delivery_date IS NOT NULL
        THEN EXTRACT(DAY FROM (o.order_delivered_customer_date - o.order_estimated_delivery_date))
        ELSE NULL
    END AS delivery_delay_days,
    -- Is delivered on time?
    CASE 
        WHEN o.order_delivered_customer_date IS NOT NULL AND o.order_estimated_delivery_date IS NOT NULL
        THEN o.order_delivered_customer_date <= o.order_estimated_delivery_date
        ELSE NULL
    END AS is_delivered_on_time
FROM silver.orders o
INNER JOIN gold.dim_customer dc 
    ON o.customer_id = dc.customer_id 
    AND dc.is_current = TRUE
-- Get primary seller (first seller for the order based on order_item_id)
LEFT JOIN (
    SELECT 
        order_id,
        seller_id
    FROM (
        SELECT 
            order_id,
            seller_id,
            ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY order_item_id) AS rn
        FROM silver.order_items
        WHERE seller_id IS NOT NULL
    ) ranked
    WHERE rn = 1
) primary_seller ON o.order_id = primary_seller.order_id
LEFT JOIN gold.dim_seller ds ON primary_seller.seller_id = ds.seller_id
LEFT JOIN gold.dim_date dpurchase 
    ON DATE(o.order_purchase_timestamp) = dpurchase.date_actual
LEFT JOIN gold.dim_date dapproved 
    ON DATE(o.order_approved_at) = dapproved.date_actual
LEFT JOIN gold.dim_date dcarrier 
    ON DATE(o.order_delivered_carrier_date) = dcarrier.date_actual
LEFT JOIN gold.dim_date ddelivered 
    ON DATE(o.order_delivered_customer_date) = ddelivered.date_actual
LEFT JOIN gold.dim_date destimated 
    ON DATE(o.order_estimated_delivery_date) = destimated.date_actual
WHERE o.order_id IS NOT NULL;

-- Create indexes
CREATE INDEX idx_fact_orders_customer_sk ON gold.fact_orders(customer_sk);
CREATE INDEX idx_fact_orders_seller_sk ON gold.fact_orders(seller_sk);
CREATE INDEX idx_fact_orders_purchase_date_sk ON gold.fact_orders(purchase_date_sk);
CREATE INDEX idx_fact_orders_status ON gold.fact_orders(order_status);
CREATE INDEX idx_fact_orders_order_id ON gold.fact_orders(order_id);

-- Verify fact table
SELECT 
    COUNT(*) as total_orders,
    COUNT(DISTINCT order_id) as unique_orders,
    COUNT(DISTINCT customer_sk) as unique_customers,
    COUNT(DISTINCT seller_sk) as unique_sellers,
    COUNT(DISTINCT order_status) as unique_statuses,
    AVG(approval_time_hours) as avg_approval_hours,
    AVG(total_processing_time_hours) as avg_processing_hours,
    AVG(delivery_delay_days) as avg_delay_days,
    COUNT(*) FILTER (WHERE is_delivered_on_time = TRUE) as on_time_deliveries,
    COUNT(*) FILTER (WHERE is_delivered_on_time = FALSE) as late_deliveries
FROM gold.fact_orders;

