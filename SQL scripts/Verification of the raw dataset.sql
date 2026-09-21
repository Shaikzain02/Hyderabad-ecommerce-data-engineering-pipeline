#Verifying the missing 70 records while compare it to the original raw excel file which consist of 3075 records. After importing
# we had only 3005 Records loaded to the MySQL

#Investigating the Remaining Records
Select Count(*) As Total_Record, Count(DISTINCT TRIM(Order_ID)) AS distinct_orders, Count(*) - Count(DISTINCT TRIM(Order_ID)) AS duplicate_rows
FROM raw_sales;

CREATE TABLE raw_sales_excel_check (
    Order_ID TEXT,
    Customer_ID TEXT,
    Order_Date TEXT,
    Product_ID TEXT,
    Product_Name TEXT,
    Category TEXT,
    Quantity TEXT,
    Unit_Price TEXT,
    Discount TEXT,
    Area TEXT,
    City TEXT,
    State TEXT,
    Zone TEXT,
    Sales_Channel TEXT,
    Payment_Method TEXT,
    Order_Status TEXT
);

#First comparison: missing Order_IDs
SELECT DISTINCT TRIM(e.Order_ID) AS missing_order_id
FROM raw_sales_excel_check e
LEFT JOIN raw_sales r ON TRIM(e.Order_ID) = TRIM(r.Order_ID)
WHERE r.Order_ID IS NULL
ORDER BY missing_order_id;

#Verifying the 66 order count
SELECT COUNT(*) AS missing_distinct_orders
FROM ( SELECT DISTINCT TRIM(e.Order_ID) AS Order_ID 
FROM raw_sales_excel_check e 
LEFT JOIN raw_sales r ON TRIM(e.Order_ID) = TRIM(r.Order_ID)
WHERE r.Order_ID IS NULL
) x;

#Comparing the duplicate count
SELECT
    TRIM(e.Order_ID) AS Order_ID,
    COUNT(*) AS excel_count,
    COALESCE(r.mysql_count, 0) AS mysql_count,
    COUNT(*) - COALESCE(r.mysql_count, 0) AS missing_duplicate_rows
FROM raw_sales_excel_check e
LEFT JOIN (
    SELECT
        TRIM(Order_ID) AS Order_ID,
        COUNT(*) AS mysql_count
    FROM raw_sales
    GROUP BY TRIM(Order_ID)
) r
    ON TRIM(e.Order_ID) = r.Order_ID
GROUP BY
    TRIM(e.Order_ID),
    r.mysql_count
HAVING COUNT(*) > COALESCE(r.mysql_count, 0)
ORDER BY Order_ID;

#Retriving the first 4 duplicate source raw
SELECT
    TRIM(e.Order_ID) AS Order_ID,
    e.Customer_ID,
    e.Order_Date,
    e.Product_ID,
    e.Product_Name,
    e.Category,
    e.Quantity,
    e.Unit_Price,
    e.Discount,
    e.Area,
    e.City,
    e.State,
    e.Zone,
    e.Sales_Channel,
    e.Payment_Method,
    e.Order_Status
FROM raw_sales_excel_check e
WHERE TRIM(e.Order_ID) IN (
    'ORD100341',
    'ORD100854',
    'ORD101891',
    'ORD102191'
)
ORDER BY TRIM(e.Order_ID);

#Investigating the remaining completely missing 66 records
SELECT
    COUNT(*) AS missing_rows,
    SUM(CASE WHEN TRIM(e.Order_ID) = '' THEN 1 ELSE 0 END) AS blank_order_id,
    SUM(CASE WHEN TRIM(e.Order_Date) = '' THEN 1 ELSE 0 END) AS blank_date,
    SUM(CASE WHEN TRIM(e.Quantity) = '' THEN 1 ELSE 0 END) AS blank_quantity,
    SUM(CASE WHEN TRIM(e.Unit_Price) = '' THEN 1 ELSE 0 END) AS blank_price,
    SUM(CASE WHEN TRIM(e.Discount) = '' THEN 1 ELSE 0 END) AS blank_discount,
    SUM(CASE WHEN TRIM(e.Customer_ID) = '' THEN 1 ELSE 0 END) AS blank_customer,
    SUM(CASE WHEN TRIM(e.Product_ID) = '' THEN 1 ELSE 0 END) AS blank_product
FROM raw_sales_excel_check e
LEFT JOIN raw_sales r
    ON TRIM(e.Order_ID) = TRIM(r.Order_ID)
WHERE r.Order_ID IS NULL;

#Verifying that complete source table consist of 3075 records or not
SELECT COUNT(*) AS source_rows
FROM raw_sales_excel_check;

#creating a rawsales table data for 3075 records
CREATE TABLE raw_sales_complete AS
SELECT *
FROM raw_sales_excel_check;

#verifying the above created table consist of data or not
Select count(*) as total_Count
from raw_sales_complete;

#Checking what all the data is consist of how many distinct values and how many duplicate values
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT TRIM(Order_ID)) AS distinct_orders,
    COUNT(*) - COUNT(DISTINCT TRIM(Order_ID)) AS duplicate_rows
FROM raw_sales_complete;

#Find which of the 70 missing rows are actually valid
SELECT
    COUNT(*) AS missing_rows,

    SUM(
        CASE
            WHEN Order_Date = ''
              OR STR_TO_DATE(
                    CASE
                        WHEN Order_Date REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'
                            THEN Order_Date
                        WHEN Order_Date REGEXP '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'
                            THEN STR_TO_DATE(Order_Date, '%d/%m/%Y')
                        WHEN Order_Date REGEXP '^[0-9]{2}-[0-9]{2}-[0-9]{4}$'
                            THEN STR_TO_DATE(Order_Date, '%m-%d-%Y')
                    END,
                    '%Y-%m-%d'
                 ) IS NULL
            THEN 1 ELSE 0
        END
    ) AS date_problem,

    SUM(
        CASE
            WHEN Quantity = ''
              OR CAST(Quantity AS SIGNED) <= 0
            THEN 1 ELSE 0
        END
    ) AS quantity_problem,

    SUM(
        CASE
            WHEN Unit_Price = ''
              OR CAST(Unit_Price AS DECIMAL(12,2)) <= 0
            THEN 1 ELSE 0
        END
    ) AS price_problem,

    SUM(
        CASE
            WHEN Discount = ''
              OR CAST(Discount AS DECIMAL(10,4)) < 0
              OR CAST(Discount AS DECIMAL(10,4)) > 0.20
            THEN 1 ELSE 0
        END
    ) AS discount_problem,

    SUM(
        CASE
            WHEN TRIM(Customer_ID) = ''
            THEN 1 ELSE 0
        END
    ) AS customer_problem,

    SUM(
        CASE
            WHEN TRIM(Product_ID) = ''
            THEN 1 ELSE 0
        END
    ) AS product_problem

FROM raw_sales_complete e
LEFT JOIN raw_sales r
    ON TRIM(e.Order_ID) = TRIM(r.Order_ID)
WHERE r.Order_ID IS NULL
   OR (
        SELECT COUNT(*)
        FROM raw_sales_complete e2
        WHERE TRIM(e2.Order_ID) = TRIM(e.Order_ID)
      )
      >
      (
        SELECT COUNT(*)
        FROM raw_sales r2
        WHERE TRIM(r2.Order_ID) = TRIM(e.Order_ID)
      );

#
SELECT COUNT(*) AS staging_rows, COUNT(DISTINCT TRIM(Order_ID)) AS staging_distinct_orders
FROM staging_sales;

#
SELECT
    COUNT(*) AS missing_rows,

    SUM(
        CASE
            WHEN TRIM(e.Order_Date) = ''
            THEN 1 ELSE 0
        END
    ) AS missing_date,

    SUM(
        CASE
            WHEN TRIM(e.Quantity) = ''
              OR CAST(e.Quantity AS SIGNED) <= 0
            THEN 1 ELSE 0
        END
    ) AS invalid_quantity,

    SUM(
        CASE
            WHEN TRIM(e.Unit_Price) = ''
              OR CAST(e.Unit_Price AS DECIMAL(12,2)) <= 0
            THEN 1 ELSE 0
        END
    ) AS invalid_price,

    SUM(
        CASE
            WHEN TRIM(e.Discount) = ''
              OR CAST(e.Discount AS DECIMAL(10,4)) < 0
              OR CAST(e.Discount AS DECIMAL(10,4)) > 0.20
            THEN 1 ELSE 0
        END
    ) AS invalid_discount,

    SUM(
        CASE
            WHEN TRIM(e.Customer_ID) = ''
            THEN 1 ELSE 0
        END
    ) AS missing_customer,

    SUM(
        CASE
            WHEN TRIM(e.Product_ID) = ''
            THEN 1 ELSE 0
        END
    ) AS missing_product

FROM raw_sales_complete e

LEFT JOIN raw_sales r
    ON TRIM(e.Order_ID) = TRIM(r.Order_ID)

WHERE r.Order_ID IS NULL;

#
SELECT
    TRIM(e.Order_ID) AS Order_ID,
    e.Order_Date,
    e.Quantity,
    e.Unit_Price,
    e.Discount,
    e.Customer_ID,
    e.Product_ID
FROM raw_sales_complete e
LEFT JOIN raw_sales r
    ON TRIM(e.Order_ID) = TRIM(r.Order_ID)
WHERE r.Order_ID IS NULL
  AND TRIM(e.Order_Date) <> ''
  AND TRIM(e.Quantity) <> ''
  AND CAST(e.Quantity AS SIGNED) > 0
  AND TRIM(e.Unit_Price) <> ''
  AND CAST(e.Unit_Price AS DECIMAL(12,2)) > 0
  AND TRIM(e.Discount) <> ''
  AND CAST(e.Discount AS DECIMAL(10,4)) BETWEEN 0 AND 0.20
  AND TRIM(e.Customer_ID) <> ''
  AND TRIM(e.Product_ID) <> ''
ORDER BY TRIM(e.Order_ID);

#
SELECT
    COUNT(*) AS total_rows
FROM raw_sales_complete;

#
DESCRIBE raw_sales_complete;

#
RENAME TABLE raw_sales
TO raw_sales_incomplete_backup;

#
RENAME TABLE raw_sales_complete
TO raw_sales;

#Verifying it without touching any clean data
SELECT
    (SELECT COUNT(*) FROM raw_sales) AS raw_rows,
    (SELECT COUNT(*) FROM staging_sales) AS staging_rows,
    (SELECT COUNT(DISTINCT Order_ID) FROM raw_sales) AS raw_distinct_orders,
    (SELECT COUNT(DISTINCT Order_ID) FROM staging_sales) AS staging_distinct_orders;