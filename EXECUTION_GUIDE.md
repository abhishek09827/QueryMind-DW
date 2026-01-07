# Data Warehouse Execution Guide

This guide provides step-by-step instructions to execute the SQL scripts and build the complete data warehouse.

## Prerequisites

1. **Database Setup**: PostgreSQL or DuckDB installed and running
2. **Dataset Files**: All CSV files in `E:\Personal Projects\DataWarehouse\datasets\`
3. **Database Access**: User with CREATE, INSERT, and SELECT permissions

## Execution Steps

### Step 1: Connect to Your Database

**For PostgreSQL:**
```bash
psql -U your_username -d your_database
```

**For DuckDB:**
```bash
duckdb your_database.db
```

### Step 2: Bronze Layer (Raw Data)

Execute these scripts **in order**:

```sql
-- 1. Create Bronze Schema
\i scripts/bronze/01_create_bronze_schema.sql

-- 2. Create Bronze Tables
\i scripts/bronze/02_create_bronze_tables.sql

-- 3. Load Data (execute all 8 load scripts)
\i scripts/bronze/03_load_bronze_orders.sql
\i scripts/bronze/04_load_bronze_customers.sql
\i scripts/bronze/05_load_bronze_order_items.sql
\i scripts/bronze/06_load_bronze_products.sql
\i scripts/bronze/07_load_bronze_payments.sql
\i scripts/bronze/08_load_bronze_reviews.sql
\i scripts/bronze/09_load_bronze_sellers.sql
\i scripts/bronze/10_load_bronze_geolocation.sql
```

**Verify Bronze Layer:**
```sql
-- Check row counts
SELECT 'orders' AS table_name, COUNT(*) AS row_count FROM bronze.orders
UNION ALL
SELECT 'customers', COUNT(*) FROM bronze.customers
UNION ALL
SELECT 'order_items', COUNT(*) FROM bronze.order_items
UNION ALL
SELECT 'products', COUNT(*) FROM bronze.products
UNION ALL
SELECT 'order_payments', COUNT(*) FROM bronze.order_payments
UNION ALL
SELECT 'order_reviews', COUNT(*) FROM bronze.order_reviews
UNION ALL
SELECT 'sellers', COUNT(*) FROM bronze.sellers
UNION ALL
SELECT 'geolocation', COUNT(*) FROM bronze.geolocation;
```

### Step 3: Silver Layer (Cleaned Data)

Execute these scripts **in order**:

```sql
-- 1. Create Silver Schema
\i scripts/silver/01_create_silver_schema.sql

-- 2. Clean and Transform Data
\i scripts/silver/02_silver_customers_clean.sql
\i scripts/silver/03_silver_orders_clean.sql
\i scripts/silver/04_silver_order_items_clean.sql
\i scripts/silver/05_silver_products_clean.sql
\i scripts/silver/06_silver_payments_clean.sql
\i scripts/silver/07_silver_reviews_clean.sql
\i scripts/silver/08_silver_sellers_clean.sql
\i scripts/silver/09_silver_geolocation_clean.sql
```

**Verify Silver Layer:**
```sql
-- Check row counts and data quality
SELECT 'orders' AS table_name, COUNT(*) AS row_count FROM silver.orders
UNION ALL
SELECT 'customers', COUNT(*) FROM silver.customers
UNION ALL
SELECT 'order_items', COUNT(*) FROM silver.order_items
UNION ALL
SELECT 'products', COUNT(*) FROM silver.products
UNION ALL
SELECT 'order_payments', COUNT(*) FROM silver.order_payments
UNION ALL
SELECT 'order_reviews', COUNT(*) FROM silver.order_reviews
UNION ALL
SELECT 'sellers', COUNT(*) FROM silver.sellers
UNION ALL
SELECT 'geolocation', COUNT(*) FROM silver.geolocation;
```

### Step 4: Gold Layer (Dimensional Model)

Execute these scripts **in order** (IMPORTANT: Date dimension must be created first):

```sql
-- 1. Create Gold Schema
\i scripts/gold/01_create_gold_schema.sql

-- 2. Create Date Dimension FIRST (required by fact tables)
\i scripts/gold/05_dim_date.sql

-- 3. Create Other Dimensions
\i scripts/gold/02_dim_customer.sql
\i scripts/gold/03_dim_product.sql
\i scripts/gold/04_dim_seller.sql

-- 4. Create Fact Tables
\i scripts/gold/06_fact_orders.sql
\i scripts/gold/07_fact_order_items.sql
\i scripts/gold/08_fact_payments.sql
\i scripts/gold/09_fact_reviews.sql
```

**Verify Gold Layer:**
```sql
-- Check dimensions
SELECT 'dim_customer' AS table_name, COUNT(*) AS row_count FROM gold.dim_customer
UNION ALL
SELECT 'dim_product', COUNT(*) FROM gold.dim_product
UNION ALL
SELECT 'dim_seller', COUNT(*) FROM gold.dim_seller
UNION ALL
SELECT 'dim_date', COUNT(*) FROM gold.dim_date;

-- Check fact tables
SELECT 'fact_orders' AS table_name, COUNT(*) AS row_count FROM gold.fact_orders
UNION ALL
SELECT 'fact_order_items', COUNT(*) FROM gold.fact_order_items
UNION ALL
SELECT 'fact_payments', COUNT(*) FROM gold.fact_payments
UNION ALL
SELECT 'fact_reviews', COUNT(*) FROM gold.fact_reviews;
```

### Step 5: Run Tests

Execute all test scripts to validate data quality:

```sql
-- 1. Test Row Counts (Bronze vs Silver vs Gold)
\i tests/test_row_counts.sql

-- 2. Test NULL Values
\i tests/test_nulls.sql

-- 3. Test Foreign Key Integrity
\i tests/test_fk_integrity.sql
```

## Quick Execution Script (PostgreSQL)

If you want to run everything at once, create a master script:

```sql
-- master_execution.sql
BEGIN;

-- Bronze Layer
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

-- Silver Layer
\i scripts/silver/01_create_silver_schema.sql
\i scripts/silver/02_silver_customers_clean.sql
\i scripts/silver/03_silver_orders_clean.sql
\i scripts/silver/04_silver_order_items_clean.sql
\i scripts/silver/05_silver_products_clean.sql
\i scripts/silver/06_silver_payments_clean.sql
\i scripts/silver/07_silver_reviews_clean.sql
\i scripts/silver/08_silver_sellers_clean.sql
\i scripts/silver/09_silver_geolocation_clean.sql

-- Gold Layer
\i scripts/gold/01_create_gold_schema.sql
\i scripts/gold/05_dim_date.sql
\i scripts/gold/02_dim_customer.sql
\i scripts/gold/03_dim_product.sql
\i scripts/gold/04_dim_seller.sql
\i scripts/gold/06_fact_orders.sql
\i scripts/gold/07_fact_order_items.sql
\i scripts/gold/08_fact_payments.sql
\i scripts/gold/09_fact_reviews.sql

-- Tests
\i tests/test_row_counts.sql
\i tests/test_nulls.sql
\i tests/test_fk_integrity.sql

COMMIT;
```

Then run:
```bash
psql -U your_username -d your_database -f master_execution.sql
```

## Troubleshooting

### Issue: COPY command fails with path error
**Solution**: 
- Ensure the path uses forward slashes or escaped backslashes
- Check file permissions
- Verify the file path is accessible from the database server

### Issue: Foreign key constraint violations
**Solution**: 
- Ensure you run scripts in the correct order
- Date dimension must be created before fact tables
- Check that Silver layer data is clean before creating Gold layer

### Issue: Duplicate key errors
**Solution**: 
- Drop and recreate tables if re-running
- Use `TRUNCATE` statements in load scripts (uncomment if needed)

### Issue: Memory errors during large loads
**Solution**: 
- Load data in batches
- Increase database memory settings
- Consider using `\copy` instead of `COPY` for client-side loading

## Expected Results

After successful execution, you should have:

- **Bronze Layer**: ~100K+ rows across 8 tables
- **Silver Layer**: Similar or fewer rows (after deduplication)
- **Gold Layer**: 
  - 4 dimension tables
  - 4 fact tables
  - Date dimension with 1,826 days (2016-2020)

## Next Steps

After successful execution:

1. **Run Analytics Queries**: Use the example queries in README.md
2. **Create Views**: Build business-friendly views on top of Gold layer
3. **Schedule Refresh**: Set up automated pipeline to refresh data
4. **Build Reports**: Connect BI tools to Gold layer for reporting

## Execution Time Estimates

- **Bronze Layer**: 5-10 minutes (data loading)
- **Silver Layer**: 2-5 minutes (transformations)
- **Gold Layer**: 3-8 minutes (dimensional model creation)
- **Tests**: 1-2 minutes

**Total**: ~15-25 minutes for complete execution

