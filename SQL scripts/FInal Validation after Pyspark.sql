#Final validation after making transformations and creating the star schema using pyspark and return all the transformation to the MYSQL
-- 1. Check analytical table row counts
SELECT 'dim_customer' AS table_name, COUNT(*) AS row_count
FROM dim_customer

UNION ALL

SELECT 'dim_product', COUNT(*)
FROM dim_product

UNION ALL

SELECT 'dim_date', COUNT(*)
FROM dim_date

UNION ALL

SELECT 'dim_location', COUNT(*)
FROM dim_location

UNION ALL

SELECT 'fact_sales', COUNT(*)
FROM fact_sales;

# 1. Customer key validation
SELECT COUNT(*) AS invalid_customer_keys
FROM fact_sales f
LEFT JOIN dim_customer d
    ON f.Customer_Key = d.Customer_Key
WHERE d.Customer_Key IS NULL;

# 2. Product key validation
SELECT COUNT(*) AS invalid_product_keys
FROM fact_sales f
LEFT JOIN dim_product d
    ON f.Product_Key = d.Product_Key
WHERE d.Product_Key IS NULL;

# 3. Date key validation
SELECT COUNT(*) AS invalid_date_keys
FROM fact_sales f
LEFT JOIN dim_date d
    ON f.Date_Key = d.Date_Key
WHERE d.Date_Key IS NULL;

# 4. Location key validation
SELECT COUNT(*) AS invalid_location_keys
FROM fact_sales f
LEFT JOIN dim_location d
    ON f.Location_Key = d.Location_Key
WHERE d.Location_Key IS NULL;