Create database hyderabad_sales;
SHOW DATABASES;

Use hyderabad_sales;

select count(*) as Total_count
from raw_sales;

SELECT COUNT(*) AS null_order_ids
FROM raw_sales
WHERE Order_ID IS NULL OR TRIM(Order_ID) = '';

DESCRIBE raw_sales;

ALTER TABLE raw_sales
RENAME COLUMN `ï»¿Order_ID` TO Order_ID;

select count(*) as total_count
from raw_sales;

select count(*) as duplicate_order_ids
from ( select trim(order_id) as order_id
		from raw_sales
        group by trim(order_id)
        having count(*)>1
        )as duplicates;
        
SELECT 
    SUM(occurrence - 1) AS extra_duplicate_rows
FROM (
    SELECT 
        TRIM(Order_ID) AS Order_ID,
        COUNT(*) AS occurrence
    FROM raw_sales
    GROUP BY TRIM(Order_ID)
    HAVING COUNT(*) > 1
) AS duplicates;

SELECT
    TRIM(Order_ID) AS Order_ID,
    COUNT(*) AS occurrence
FROM raw_sales
GROUP BY TRIM(Order_ID)
HAVING COUNT(*) > 1
ORDER BY occurrence DESC;

SELECT
    SUM(Order_ID IS NULL OR TRIM(Order_ID) = '') AS missing_order_id,
    SUM(Customer_ID IS NULL OR TRIM(Customer_ID) = '') AS missing_customer_id,
    SUM(Order_Date IS NULL OR TRIM(Order_Date) = '') AS missing_order_date,
    SUM(Product_ID IS NULL OR TRIM(Product_ID) = '') AS missing_product_id,
    SUM(Product_Name IS NULL OR TRIM(Product_Name) = '') AS missing_product_name,
    SUM(Category IS NULL OR TRIM(Category) = '') AS missing_category,
    SUM(Quantity IS NULL OR TRIM(Quantity) = '') AS missing_quantity,
    SUM(Unit_Price IS NULL) AS missing_unit_price,
    SUM(Discount IS NULL) AS missing_discount,
    SUM(Area IS NULL OR TRIM(Area) = '') AS missing_area,
    SUM(City IS NULL OR TRIM(City) = '') AS missing_city,
    SUM(State IS NULL OR TRIM(State) = '') AS missing_state,
    SUM(Zone IS NULL OR TRIM(Zone) = '') AS missing_zone,
    SUM(Sales_Channel IS NULL OR TRIM(Sales_Channel) = '') AS missing_channel,
    SUM(Payment_Method IS NULL OR TRIM(Payment_Method) = '') AS missing_payment,
    SUM(Order_Status IS NULL OR TRIM(Order_Status) = '') AS missing_status
FROM raw_sales;

SELECT COUNT(*) AS invalid_quantity
FROM raw_sales
WHERE CAST(Quantity AS DECIMAL(10,2)) <= 0;

SELECT COUNT(*) AS invalid_price
FROM raw_sales
WHERE Unit_Price <= 0;

SELECT COUNT(*) AS invalid_discount
FROM raw_sales
WHERE Discount < 0
   OR Discount > 0.20;
   
SELECT 
    Order_Date,
    COUNT(*) AS occurrence
FROM raw_sales
GROUP BY Order_Date
ORDER BY occurrence DESC;

SELECT
    TRIM(City) AS City,
    TRIM(State) AS State,
    COUNT(*) AS transaction_count
FROM raw_sales
GROUP BY TRIM(City), TRIM(State)
ORDER BY transaction_count DESC;

select trim(area) as area, count(*) as transaction_count
from raw_sales
group by trim(area)
order by transaction_count desc;