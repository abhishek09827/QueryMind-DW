
  
    

  create  table "warehouse"."public_gold"."dim_date__dbt_tmp"
  
  
    as
  
  (
    

WITH date_series AS (
    SELECT generate_series(
        '2016-01-01'::DATE,
        '2020-12-31'::DATE,
        '1 day'::INTERVAL
    )::DATE AS date_actual
)

SELECT
    CAST(TO_CHAR(date_actual, 'YYYYMMDD') AS INTEGER) AS date_sk,
    date_actual,
    EXTRACT(DOW FROM date_actual) + 1 AS day_of_week,
    TO_CHAR(date_actual, 'Day') AS day_name,
    EXTRACT(DAY FROM date_actual) AS day_of_month,
    EXTRACT(DOY FROM date_actual) AS day_of_year,
    EXTRACT(WEEK FROM date_actual) AS week_of_year,
    EXTRACT(MONTH FROM date_actual) AS month_number,
    TO_CHAR(date_actual, 'Month') AS month_name,
    EXTRACT(QUARTER FROM date_actual) AS quarter_number,
    'Q' || EXTRACT(QUARTER FROM date_actual) AS quarter_name,
    EXTRACT(YEAR FROM date_actual) AS year_number,
    EXTRACT(DOW FROM date_actual) IN (0, 6) AS is_weekend,
    date_actual = DATE_TRUNC('month', date_actual) AS is_month_start,
    date_actual = (DATE_TRUNC('month', date_actual) + INTERVAL '1 month' - INTERVAL '1 day') AS is_month_end
FROM date_series
  );
  