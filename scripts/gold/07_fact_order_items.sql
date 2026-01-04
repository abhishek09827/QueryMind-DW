-- =====================================================
-- GOLD LAYER: Fact Order Items
-- =====================================================
-- Purpose: Create order items fact table in star schema
--          Contains order item metrics with foreign keys to dimensions
--          Includes: product_sk, seller_sk, order_sk, price, freight, quantity
-- =====================================================

-- Drop table if exists (for re-running)
DROP TABLE IF EXISTS gold.fact_order_items CASCADE;

-- Create order items fact table
CREATE TABLE gold.fact_order_items (
    order_item_sk SERIAL PRIMARY KEY,  -- Surrogate key
    order_id VARCHAR(50) NOT NULL,
    order_item_id INTEGER NOT NULL,
    order_sk INTEGER NOT NULL,
    product_sk INTEGER NOT NULL,
    seller_sk INTEGER NOT NULL,
    shipping_limit_date_sk INTEGER,
    shipping_limit_date TIMESTAMP,
    price DECIMAL(10, 2) NOT NULL,
    freight_value DECIMAL(10, 2) NOT NULL,
    quantity INTEGER DEFAULT 1,  -- Usually 1 per row, but kept for consistency
    total_item_value DECIMAL(10, 2),  -- price + freight_value
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (order_sk) REFERENCES gold.fact_orders(order_sk),
    FOREIGN KEY (product_sk) REFERENCES gold.dim_product(product_sk),
    FOREIGN KEY (seller_sk) REFERENCES gold.dim_seller(seller_sk),
    FOREIGN KEY (shipping_limit_date_sk) REFERENCES gold.dim_date(date_sk),
    UNIQUE (order_id, order_item_id)
);

-- Insert order items fact data
INSERT INTO gold.fact_order_items (
    order_id,
    order_item_id,
    order_sk,
    product_sk,
    seller_sk,
    shipping_limit_date_sk,
    shipping_limit_date,
    price,
    freight_value,
    quantity,
    total_item_value
)
SELECT 
    oi.order_id,
    oi.order_item_id,
    fo.order_sk,
    dp.product_sk,
    ds.seller_sk,
    dship.date_sk AS shipping_limit_date_sk,
    oi.shipping_limit_date,
    oi.price,
    oi.freight_value,
    1 AS quantity,  -- Each row represents one item
    oi.price + oi.freight_value AS total_item_value
FROM silver.order_items oi
INNER JOIN gold.fact_orders fo 
    ON oi.order_id = fo.order_id
INNER JOIN gold.dim_product dp 
    ON oi.product_id = dp.product_id
INNER JOIN gold.dim_seller ds 
    ON oi.seller_id = ds.seller_id
LEFT JOIN gold.dim_date dship 
    ON DATE(oi.shipping_limit_date) = dship.date_actual
WHERE oi.order_id IS NOT NULL
  AND oi.product_id IS NOT NULL
  AND oi.seller_id IS NOT NULL;

-- Create indexes
CREATE INDEX idx_fact_order_items_order_sk ON gold.fact_order_items(order_sk);
CREATE INDEX idx_fact_order_items_product_sk ON gold.fact_order_items(product_sk);
CREATE INDEX idx_fact_order_items_seller_sk ON gold.fact_order_items(seller_sk);
CREATE INDEX idx_fact_order_items_order_id ON gold.fact_order_items(order_id);

-- Verify fact table
SELECT 
    COUNT(*) as total_order_items,
    COUNT(DISTINCT order_id) as unique_orders,
    COUNT(DISTINCT product_sk) as unique_products,
    COUNT(DISTINCT seller_sk) as unique_sellers,
    SUM(price) as total_price,
    SUM(freight_value) as total_freight,
    SUM(total_item_value) as total_item_value,
    AVG(price) as avg_price,
    AVG(freight_value) as avg_freight
FROM gold.fact_order_items;

