# SQL Data Warehouse Project - Olist Brazilian E-Commerce Dataset

This project implements a Medallion architecture (Bronze, Silver, Gold layers) for the Olist Brazilian E-Commerce dataset using SQL.

## Project Structure

```
DataWarehouse/
├── scripts/
│   ├── bronze/
│   │   ├── 01_create_bronze_schema.sql
│   │   ├── 02_create_bronze_tables.sql
│   │   ├── 03_load_bronze_orders.sql
│   │   ├── 04_load_bronze_customers.sql
│   │   ├── 05_load_bronze_order_items.sql
│   │   ├── 06_load_bronze_products.sql
│   │   ├── 07_load_bronze_payments.sql
│   │   ├── 08_load_bronze_reviews.sql
│   │   ├── 09_load_bronze_sellers.sql
│   │   └── 10_load_bronze_geolocation.sql
│   ├── silver/
│   │   ├── 01_create_silver_schema.sql
│   │   ├── 02_silver_customers_clean.sql
│   │   ├── 03_silver_orders_clean.sql
│   │   ├── 04_silver_order_items_clean.sql
│   │   ├── 05_silver_products_clean.sql
│   │   ├── 06_silver_payments_clean.sql
│   │   ├── 07_silver_reviews_clean.sql
│   │   ├── 08_silver_sellers_clean.sql
│   │   └── 09_silver_geolocation_clean.sql
│   └── gold/
│       ├── 01_create_gold_schema.sql
│       ├── 02_dim_customer.sql
│       ├── 03_dim_product.sql
│       ├── 04_dim_seller.sql
│       ├── 05_dim_date.sql
│       ├── 06_fact_orders.sql
│       ├── 07_fact_order_items.sql
│       ├── 08_fact_payments.sql
│       └── 09_fact_reviews.sql
└── tests/
    ├── test_row_counts.sql
    ├── test_nulls.sql
    └── test_fk_integrity.sql
```

## Architecture Overview

### Bronze Layer
- **Purpose**: Raw, unprocessed data from CSV files
- **Tables**: Exact copies of source CSV structure
- **No transformations**: Data loaded as-is

### Silver Layer
- **Purpose**: Cleaned, deduplicated, standardized data
- **Transformations Applied**:
  - Trim whitespace
  - Lowercase/uppercase standardization
  - Convert timestamps to proper types
  - Remove duplicates
  - Replace empty strings with NULL
  - Validate numeric columns
  - Date logic validation

### Gold Layer
- **Purpose**: Dimensional model (Star Schema) for analytics
- **Dimensions**:
  - `dim_customer` (SCD Type 2)
  - `dim_product`
  - `dim_seller`
  - `dim_date` (5-year calendar: 2016-2020)
- **Fact Tables**:
  - `fact_orders` (order metrics, delivery times)
  - `fact_order_items` (item-level metrics)
  - `fact_payments` (payment transactions)
  - `fact_reviews` (customer reviews)

## Execution Order

### 1. Bronze Layer
```sql
-- Execute in order:
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


### 2. Silver Layer
```sql
-- Execute in order:
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

### 3. Gold Layer
```sql
-- Execute in order:
\i scripts/gold/01_create_gold_schema.sql
\i scripts/gold/05_dim_date.sql  -- Create date dimension first (used by facts)
\i scripts/gold/02_dim_customer.sql
\i scripts/gold/03_dim_product.sql
\i scripts/gold/04_dim_seller.sql
\i scripts/gold/06_fact_orders.sql
\i scripts/gold/07_fact_order_items.sql
\i scripts/gold/08_fact_payments.sql
\i scripts/gold/09_fact_reviews.sql
```

### 4. Run Tests
```sql
-- Execute tests:
\i tests/test_row_counts.sql
\i tests/test_nulls.sql
\i tests/test_fk_integrity.sql
```

## Database Compatibility

The SQL scripts are designed to work with:
- **PostgreSQL** (primary target)
- **DuckDB** (with minor syntax adjustments)

### PostgreSQL Notes
- Uses `SERIAL` for auto-incrementing keys
- Uses `COPY` command for CSV loading
- Uses `EXTRACT()` and `DATE_TRUNC()` for date functions

### DuckDB Notes
- Replace `SERIAL` with `INTEGER PRIMARY KEY` and use sequences
- `COPY` syntax may need adjustment
- Date functions are compatible

## Dataset Requirements

Download the Olist Brazilian E-Commerce dataset from Kaggle:
- `olist_orders_dataset.csv`
- `olist_customers_dataset.csv`
- `olist_order_items_dataset.csv`
- `olist_products_dataset.csv`
- `olist_sellers_dataset.csv`
- `olist_order_payments_dataset.csv`
- `olist_order_reviews_dataset.csv`
- `olist_geolocation_dataset.csv`

## Key Features

### Bronze Layer
- Exact CSV structure preservation
- No data loss
- Fast bulk loading

### Silver Layer
- Data quality improvements
- Standardized formats
- Duplicate removal
- Type conversions

### Gold Layer
- Star schema design
- SCD Type 2 for customer dimension
- Comprehensive date dimension
- Calculated metrics (delivery delays, processing times)
- Foreign key relationships

### Testing
- Row count validation (Bronze → Silver → Gold)
- NULL value checks in key columns
- Foreign key integrity validation
- Cross-layer consistency checks

## Example Queries

### Sales by Product Category
```sql
SELECT 
    dp.product_category_name,
    COUNT(DISTINCT foi.order_id) AS order_count,
    SUM(foi.price) AS total_revenue,
    SUM(foi.freight_value) AS total_freight,
    AVG(foi.price) AS avg_price
FROM gold.fact_order_items foi
JOIN gold.dim_product dp ON foi.product_sk = dp.product_sk
GROUP BY dp.product_category_name
ORDER BY total_revenue DESC;
```

### Customer Order Analysis
```sql
SELECT 
    dd.year_number,
    dd.quarter_name,
    COUNT(DISTINCT fo.order_id) AS total_orders,
    COUNT(DISTINCT fo.customer_sk) AS unique_customers,
    AVG(fo.total_processing_time_hours) AS avg_delivery_hours,
    AVG(fo.delivery_delay_days) AS avg_delay_days
FROM gold.fact_orders fo
JOIN gold.dim_date dd ON fo.purchase_date_sk = dd.date_sk
WHERE fo.order_status = 'delivered'
GROUP BY dd.year_number, dd.quarter_name
ORDER BY dd.year_number, dd.quarter_number;
```

### Review Score Distribution
```sql
SELECT 
    fr.review_score,
    COUNT(*) AS review_count,
    COUNT(*) * 100.0 / SUM(COUNT(*)) OVER () AS percentage
FROM gold.fact_reviews fr
GROUP BY fr.review_score
ORDER BY fr.review_score DESC;
```

## Notes

- All timestamps are converted to proper TIMESTAMP types
- Empty strings are replaced with NULL values
- Text fields are standardized (lowercase cities, uppercase states)
- Date dimension covers 2016-2020 (full 5-year period)
- Customer dimension uses SCD Type 2 for historical tracking
- All fact tables include surrogate keys and foreign key relationships