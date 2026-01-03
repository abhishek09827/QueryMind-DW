# Quick Start Guide

## Prerequisites
- PostgreSQL or DuckDB installed
- All CSV files in `datasets/` folder

## Execution Steps (Copy & Paste)

### 1. Connect to Database
```bash
psql -U your_username -d your_database
```

### 2. Run Bronze Layer
```sql
\i scripts/bronze/01_create_bronze_schema.sql
\i scripts/bronze/02_create_bronze_tables.sql
\i scripts/bronze/03_load_bronze_orders.sql
\i scripts/bronze/04_load_bronze_customers.sql
\i scripts/bronze/05_load_bronze_order_items.sql
\i scripts/bronze/06_load_bronze_products.sql
\i scripts/bronze/07_load_bronze_payments.sql
\i scripts/bronze/08_load_bronze_reviews.sql
\i scripts/bronze/09_load_bronze_sellers.sql
\i scripts/bronze/10_load_bronze_geolocation.sql
```

### 3. Run Silver Layer
```sql
\i scripts/silver/01_create_silver_schema.sql
\i scripts/silver/02_silver_customers_clean.sql
\i scripts/silver/03_silver_orders_clean.sql
\i scripts/silver/04_silver_order_items_clean.sql
\i scripts/silver/05_silver_products_clean.sql
\i scripts/silver/06_silver_payments_clean.sql
\i scripts/silver/07_silver_reviews_clean.sql
\i scripts/silver/08_silver_sellers_clean.sql
\i scripts/silver/09_silver_geolocation_clean.sql
```

### 4. Run Gold Layer
```sql
\i scripts/gold/01_create_gold_schema.sql
\i scripts/gold/05_dim_date.sql
\i scripts/gold/02_dim_customer.sql
\i scripts/gold/03_dim_product.sql
\i scripts/gold/04_dim_seller.sql
\i scripts/gold/06_fact_orders.sql
\i scripts/gold/07_fact_order_items.sql
\i scripts/gold/08_fact_payments.sql
\i scripts/gold/09_fact_reviews.sql
```

### 5. Run Tests
```sql
\i tests/test_row_counts.sql
\i tests/test_nulls.sql
\i tests/test_fk_integrity.sql
```

## Verify Success
```sql
SELECT 
    'Bronze' AS layer, COUNT(*) AS total_tables
FROM information_schema.tables 
WHERE table_schema = 'bronze'
UNION ALL
SELECT 'Silver', COUNT(*) FROM information_schema.tables WHERE table_schema = 'silver'
UNION ALL
SELECT 'Gold', COUNT(*) FROM information_schema.tables WHERE table_schema = 'gold';
```

## Expected Execution Time
- **Total**: ~15-25 minutes
- Bronze: 5-10 min | Silver: 2-5 min | Gold: 3-8 min | Tests: 1-2 min


