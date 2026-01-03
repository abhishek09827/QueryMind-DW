-- =====================================================
-- BRONZE LAYER: Table Creation
-- =====================================================
-- Purpose: Create all bronze tables matching the raw CSV structure
--          These tables will store exact copies of source data
-- =====================================================

-- Drop tables if they exist (for re-running)
DROP TABLE IF EXISTS bronze.orders CASCADE;
DROP TABLE IF EXISTS bronze.customers CASCADE;
DROP TABLE IF EXISTS bronze.order_items CASCADE;
DROP TABLE IF EXISTS bronze.products CASCADE;
DROP TABLE IF EXISTS bronze.sellers CASCADE;
DROP TABLE IF EXISTS bronze.order_payments CASCADE;
DROP TABLE IF EXISTS bronze.order_reviews CASCADE;
DROP TABLE IF EXISTS bronze.geolocation CASCADE;

-- =====================================================
-- 1. ORDERS TABLE
-- =====================================================
CREATE TABLE bronze.orders (
    order_id VARCHAR(50) PRIMARY KEY,
    customer_id VARCHAR(50),
    order_status VARCHAR(20),
    order_purchase_timestamp TIMESTAMP,
    order_approved_at TIMESTAMP,
    order_delivered_carrier_date TIMESTAMP,
    order_delivered_customer_date TIMESTAMP,
    order_estimated_delivery_date TIMESTAMP
);

-- =====================================================
-- 2. CUSTOMERS TABLE
-- =====================================================
CREATE TABLE bronze.customers (
    customer_id VARCHAR(50) PRIMARY KEY,
    customer_unique_id VARCHAR(50),
    customer_zip_code_prefix VARCHAR(10),
    customer_city VARCHAR(100),
    customer_state VARCHAR(2)
);

-- =====================================================
-- 3. ORDER ITEMS TABLE
-- =====================================================
CREATE TABLE bronze.order_items (
    order_id VARCHAR(50),
    order_item_id INTEGER,
    product_id VARCHAR(50),
    seller_id VARCHAR(50),
    shipping_limit_date TIMESTAMP,
    price DECIMAL(10, 2),
    freight_value DECIMAL(10, 2),
    PRIMARY KEY (order_id, order_item_id)
);

-- =====================================================
-- 4. PRODUCTS TABLE
-- =====================================================
CREATE TABLE bronze.products (
    product_id VARCHAR(50) PRIMARY KEY,
    product_category_name VARCHAR(100),
    product_name_lenght INTEGER,
    product_description_lenght INTEGER,
    product_photos_qty INTEGER,
    product_weight_g INTEGER,
    product_length_cm INTEGER,
    product_height_cm INTEGER,
    product_width_cm INTEGER
);

-- =====================================================
-- 5. SELLERS TABLE
-- =====================================================
CREATE TABLE bronze.sellers (
    seller_id VARCHAR(50) PRIMARY KEY,
    seller_zip_code_prefix VARCHAR(10),
    seller_city VARCHAR(100),
    seller_state VARCHAR(2)
);

-- =====================================================
-- 6. ORDER PAYMENTS TABLE
-- =====================================================
CREATE TABLE bronze.order_payments (
    order_id VARCHAR(50),
    payment_sequential INTEGER,
    payment_type VARCHAR(20),
    payment_installments INTEGER,
    payment_value DECIMAL(10, 2),
    PRIMARY KEY (order_id, payment_sequential)
);

-- =====================================================
-- 7. ORDER REVIEWS TABLE
-- =====================================================
CREATE TABLE bronze.order_reviews (
    review_id VARCHAR(50) PRIMARY KEY,
    order_id VARCHAR(50),
    review_score INTEGER,
    review_comment_title VARCHAR(255),
    review_comment_message TEXT,
    review_creation_date TIMESTAMP,
    review_answer_timestamp TIMESTAMP
);

-- =====================================================
-- 8. GEOLOCATION TABLE
-- =====================================================
CREATE TABLE bronze.geolocation (
    geolocation_zip_code_prefix VARCHAR(10),
    geolocation_lat DECIMAL(10, 8),
    geolocation_lng DECIMAL(11, 8),
    geolocation_city VARCHAR(100),
    geolocation_state VARCHAR(2)
);

-- Create indexes for better query performance
CREATE INDEX idx_bronze_orders_customer_id ON bronze.orders(customer_id);
CREATE INDEX idx_bronze_order_items_order_id ON bronze.order_items(order_id);
CREATE INDEX idx_bronze_order_items_product_id ON bronze.order_items(product_id);
CREATE INDEX idx_bronze_order_items_seller_id ON bronze.order_items(seller_id);
CREATE INDEX idx_bronze_order_payments_order_id ON bronze.order_payments(order_id);
CREATE INDEX idx_bronze_order_reviews_order_id ON bronze.order_reviews(order_id);

