#Numberic data validation
#grouping the values and counting there occurance
SELECT Quantity, COUNT(*) AS occurrence
FROM staging_sales
WHERE Quantity <= 0 OR Quantity IS NULL
GROUP BY Quantity
ORDER BY Quantity;

#writing this query to get the actual transaction as we know the invalid values in quantity
SELECT Order_ID, Customer_ID, Order_Date, Product_ID, Product_Name, Quantity, Unit_Price, Discount, Order_Status
FROM staging_sales
WHERE Quantity <= 0 OR Quantity IS NULL
ORDER BY Quantity, Order_ID;

#validating the occurance of the unit_prices
SELECT Unit_Price, COUNT(*) AS occurrence
FROM staging_sales
WHERE Unit_Price <= 0 OR Unit_Price IS NULL
GROUP BY Unit_Price
ORDER BY Unit_Price;

#validating the discount 
SELECT Discount, COUNT(*) AS occurrence
FROM staging_sales
WHERE Discount < 0 OR Discount > 0.20 OR Discount IS NULL
GROUP BY Discount
ORDER BY Discount;

#How many unique transactions are affected by at least one numeric-quality problem?
SELECT COUNT(*) AS invalid_numeric_rows
FROM staging_sales
WHERE Quantity <= 0
OR Quantity IS NULL 
OR Unit_Price <= 0 
OR Unit_Price IS NULL 
OR Discount < 0 OR 
Discount > 0.20 OR 
Discount IS NULL;

#Validating the date type
SELECT Order_Date, COUNT(*) AS occurrence
FROM staging_sales
GROUP BY Order_Date
ORDER BY Order_Date;

#finding the missing dates in the table 
Select Count(*) as Missing_order_date
from staging_sales
where order_date is Null or trim(order_date) = '';

#Checking the 36 missing dates are having any different pattern or same
SELECT COUNT(*) AS missing_date_rows,
SUM(
CASE WHEN Quantity <= 0 OR Quantity IS NULL THEN 1 ELSE 0 
END) AS invalid_quantity_rows,
SUM(
CASE WHEN Unit_Price <= 0 OR Unit_Price IS NULL THEN 1 ELSE 0 
END) AS invalid_price_rows,
SUM(
CASE WHEN Discount < 0 OR Discount > 0.20 OR Discount IS NULL THEN 1 ELSE 0 
END) AS invalid_discount_rows,
SUM(
CASE WHEN Customer_ID IS NULL OR TRIM(Customer_ID) = '' THEN 1 ELSE 0 
END ) AS missing_customer_rows
FROM staging_sales
WHERE Order_Date IS NULL OR TRIM(Order_Date) = '';

#Identifying the order id without the order_date in the table 
Select order_id, customer_id, order_date, product_id, product_name, Category, 
Quantity, unit_price, Discount, Area, Zone, Sales_channel, Payment_method, order_status
from staging_sales
where order_date is null or trim(order_date) = ''
order by order_id;

#creating a new date column
Alter table staging_sales
Add column Clean_order_date date;

#Identifying the date formats
SELECT
CASE
WHEN Order_Date IS NULL OR TRIM(Order_Date) = '' THEN 'Missing'
WHEN Order_Date REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' THEN 'YYYY-MM-DD'
WHEN Order_Date REGEXP '^[0-9]{2}/[0-9]{2}/[0-9]{4}$' THEN 'Slash Format'
WHEN Order_Date REGEXP '^[0-9]{2}-[0-9]{2}-[0-9]{4}$' THEN 'Hyphen Format'
ELSE 'Other / Invalid'
END AS Date_Format,
COUNT(*) AS occurrence
FROM staging_sales
GROUP BY Date_Format
ORDER BY occurrence DESC;

#Converting the String_date/Text format to the date format
UPDATE staging_sales
SET Clean_order_date = STR_TO_DATE(Order_Date, '%Y-%m-%d')
WHERE Order_Date REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$';

#Verifying the date conversion we did above
SELECT COUNT(*) AS converted_iso_dates
FROM staging_sales
WHERE Order_Date REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' AND Clean_order_date IS NOT NULL;

#Identifying the slashdate format
SELECT Order_Date, COUNT(*) AS occurrence
FROM staging_sales
WHERE Order_Date REGEXP '^[0-9]{2}/[0-9]{2}/[0-9]{4}$' AND 
(CAST(SUBSTRING_INDEX(Order_Date, '/', 1) AS UNSIGNED) > 12 OR
CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(Order_Date, '/', 2), '/', -1) AS UNSIGNED) > 12)
GROUP BY Order_Date
ORDER BY Order_Date;

#Verifying any slash dates are ambiguous or not
SELECT Order_Date, COUNT(*) AS occurrence
FROM staging_sales
WHERE Order_Date REGEXP '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'
AND CAST(SUBSTRING_INDEX(Order_Date, '/', 1) AS UNSIGNED) BETWEEN 1 AND 12
AND CAST(SUBSTRING_INDEX( SUBSTRING_INDEX(Order_Date, '/', 2), '/', -1) AS UNSIGNED ) BETWEEN 1 AND 12
GROUP BY Order_Date
ORDER BY Order_Date;

#converting the str_to_date slash format to the hypen format
UPDATE staging_sales
SET Clean_order_date = STR_TO_DATE(Order_Date, '%d/%m/%Y')
WHERE Order_Date REGEXP '^[0-9]{2}/[0-9]{2}/[0-9]{4}$';

#Checking for the current date conversions
SELECT COUNT(*) AS total_rows, COUNT(Clean_order_date) AS converted_dates,
SUM(CASE WHEN Clean_order_date IS NULL THEN 1 ELSE 0 END ) AS remaining_null_dates
FROM staging_sales;

#converting the Str_to_date hypen format to the date hypen format
UPDATE staging_sales
SET Clean_order_date = STR_TO_DATE(Order_Date, '%m-%d-%Y')
WHERE Order_Date REGEXP '^[0-9]{2}-[0-9]{2}-[0-9]{4}$';

#Finding the dates that are not equal to year 2025
select Clean_order_date, count(*) as occurance
from staging_sales
where Clean_order_date is Not Null and Year(Clean_order_date) <> 2025
group by Clean_order_date
order by Clean_order_date;

#Identifying the 12 Invalid year transactions
SELECT Order_ID, Customer_ID, Order_Date, Clean_order_date, Product_ID, Product_Name, Quantity, Unit_Price,
Discount, Area, Zone, Sales_Channel, Payment_Method, Order_Status
FROM staging_sales
WHERE Clean_order_date IS NOT NULL AND YEAR(Clean_order_date) <> 2025
ORDER BY Clean_order_date, Order_ID;

#Creating a validation Flag
Alter table Staging_sales
Add column Date_Quality_Status varchar(30);

#Updating the Date_quality_status
Update staging_sales
set Date_Quality_Status = 
case 
when Clean_order_date is Null Then 'Missing date'
when Year(Clean_order_date) <> 2025 Then 'Invalid year'
else 'Valid'
end;

#Validating the Date_quality_status column
select date_quality_status, Count(*) as occurance
from staging_sales
group by date_quality_status
order by case date_quality_status
when 'Valid' then 1
when 'Missing' then 2
when 'Invalid' then 3
else 4
end;

#Validating the Quantity 
Alter table Staging_sales
Add column Quantity_Quality_status varchar(30);

#Updating the quantity values to the created column above
Update staging_sales
set Quantity_Quality_status = 
case when Quantity is Null or Quantity <=0 then 'Invalid Number'
Else 'valid'
end;

#Verifying the Quantity_quality_status
select Quantity_Quality_status, count(*) as occurance
from staging_sales
group by Quantity_Quality_Status
order by case Quantity_Quality_status
when 'Valid' then 1
when 'Invalid' then 2
else 3
end;

#Validating the Unit_price
Alter table staging_Sales
Add column price_quality_status varchar(30);

#Updating the price values in the above created column
Update Staging_sales
set Price_quality_status = 
case when unit_price is null or unit_price <=0 then 'Invalid'
else 'Valid'
end;

#Verifying the price_quality_status column 
select price_quality_status, count(*) as occurance
from staging_Sales
group by price_quality_status
order by case price_quality_Status 
when 'Valid' then 1 
when 'Invalid' then 2
else 3
end;

#validating the discount column
Alter table staging_Sales
Add column Discount_quality_status varchar(30);

#updating the discount_quality_status column that we created above
Update staging_sales
set Discount_quality_status = 
case when discount is null or discount < 0 or discount > 0.20 then 'invalid'
else 'valid'
end;

#Verifying the discount column that we updated
select discount_quality_status, count(*) as occurance
from staging_Sales
group by discount_quality_status
order by case discount_quality_status
when 'Valid' then 1 
when 'Invalid Discount' then 2
else 3
end;

#Finding the transaction with the data quality issues
select count(*) as total_quality_status_issue
from staging_sales
where date_quality_status <>'Valid' 
or quantity_quality_status <> 'Valid'
or price_quality_status <> 'Valid'
or discount_quality_status <> 'Valid';

#verifying the Quality rules that are overlapping
SELECT
CONCAT(
CASE WHEN Date_Quality_Status <> 'Valid'
THEN 'Date; ' ELSE '' END,
CASE WHEN Quantity_Quality_Status <> 'Valid'
THEN 'Quantity; ' ELSE '' END,
CASE WHEN Price_Quality_Status <> 'Valid'
THEN 'Price; ' ELSE '' END,
CASE WHEN Discount_Quality_Status <> 'Valid'
THEN 'Discount' ELSE '' END) AS Issue_Combination,
COUNT(*) AS occurrence
FROM staging_sales
WHERE Date_Quality_Status <> 'Valid'
OR Quantity_Quality_Status <> 'Valid'
OR Price_Quality_Status <> 'Valid'
OR Discount_Quality_Status <> 'Valid'
GROUP BY Issue_Combination
ORDER BY occurrence DESC;

#Identifying the missing order ids
select count(*) as Missing_orderid_count
from staging_sales
where order_id is null or trim(order_id) ='';

#Identifying the duplicate order_ids
select trim(order_id) as order_id, count(*) as Duplicate_value
from staging_sales
group by trim(order_id)
having count(*) > 1
order by duplicate_value desc, order_id;

#Identifying the duplicates are identical or not
SELECT s.Order_ID, s.Customer_ID, s.Order_Date, s.Product_ID, s.Product_Name, s.Category, s.Area,
s.City, s.State, s.Zone, s.Quantity, s.Unit_Price, s.Discount, s.Sales_Channel, s.Payment_Method, s.Order_Status
FROM staging_sales s
JOIN (
SELECT TRIM(Order_ID) AS Order_ID
FROM staging_sales
GROUP BY TRIM(Order_ID)
HAVING COUNT(*) > 1
) d
ON TRIM(s.Order_ID) = d.Order_ID
ORDER BY s.Order_ID;

#Exact duplicate values that are identically same
select trim(order_id) as order_id, count(*) as occurance
from staging_sales
group by trim(order_id) 
having count(*) > 1 And count(distinct concat_ws('|',
        Customer_ID,
        Order_Date,
        Product_ID,
        Product_Name,
        Category,
        Area,
        City,
        State,
        Zone,
        Quantity,
        Unit_Price,
        Discount,
        Sales_Channel,
        Payment_Method,
        Order_Status)) = 1
order by order_id;

#Identifying the dirty duplicates means which is having a formatting issue
SELECT TRIM(Order_ID) AS Order_ID, COUNT(*) AS occurrence
FROM staging_sales
GROUP BY TRIM(Order_ID)
HAVING COUNT(*) > 1
   AND COUNT(DISTINCT CONCAT_WS('|',
        Customer_ID,
        Order_Date,
        Product_ID,
        Product_Name,
        Category,
        Area,
        City,
        State,
        Zone,
        Quantity,
        Unit_Price,
        Discount,
        Sales_Channel,
        Payment_Method,
        Order_Status
   )) > 1
ORDER BY Order_ID;

#making all the city names in the lowercase while updating it in the staging_sales
update staging_sales
set city  ='Hyderabad'
where lower(trim(city)) = 'hyderabad';

#making all the State names in the lowercase while updating it in the staging_sales
update staging_sales
set state  = 'Telangana'
where lower(trim(state)) = 'telangana';

#making all the Order_Status in the lowercase while updating it in the staging_sales
UPDATE staging_sales
SET Order_Status =
CASE
WHEN LOWER(TRIM(Order_Status)) = 'delivered'
THEN 'Delivered'
WHEN LOWER(TRIM(Order_Status)) = 'shipped'
THEN 'Shipped'
WHEN LOWER(TRIM(Order_Status)) = 'cancelled'
THEN 'Cancelled'
WHEN LOWER(TRIM(Order_Status)) = 'returned'
THEN 'Returned'
ELSE Order_Status
END;

#making all the sales_channel in the lowercase while updating it in the staging_sales
UPDATE staging_sales
SET Sales_Channel =
CASE
WHEN LOWER(TRIM(Sales_Channel)) = 'online'
THEN 'Online'
WHEN LOWER(TRIM(Sales_Channel)) = 'retail store'
THEN 'Retail Store'
WHEN LOWER(TRIM(Sales_Channel)) = 'corporate sales'
THEN 'Corporate Sales'
ELSE Sales_Channel
END;

#Identifying the payment_method column
SELECT Payment_Method, COUNT(*) AS occurrence, HEX(Payment_Method) AS hex_value, CHAR_LENGTH(Payment_Method) AS character_length
FROM staging_sales
GROUP BY Payment_Method
ORDER BY occurrence DESC;

#Handling the missing payment method using unknown value instead of leaving it blank to make the data clean
UPDATE staging_sales
SET Payment_Method =
CASE
WHEN LOWER(TRIM(Payment_Method)) = 'upi'
THEN 'UPI'
WHEN LOWER(TRIM(Payment_Method)) = 'credit card'
THEN 'Credit Card'
WHEN LOWER(TRIM(Payment_Method)) = 'debit card'
THEN 'Debit Card'
WHEN LOWER(TRIM(Payment_Method)) = 'net banking'
THEN 'Net Banking'
WHEN LOWER(TRIM(Payment_Method)) = 'cash on delivery'
THEN 'Cash on Delivery'
WHEN TRIM(Payment_Method) = ''
THEN 'Unknown'
ELSE Payment_Method
END;

#standardizing the category column
UPDATE staging_sales s
JOIN product_master p ON s.Product_ID = p.Product_ID
SET s.Category = p.Category
WHERE s.Category <> p.Category
OR s.Category IS NULL OR TRIM(s.Category) = '';

#Standardizing the product name column
UPDATE staging_Sales s
join product_master p on s.product_id = p.product_id
set s.product_name = p.product_name
where s.product_name <> p.product_name
or s.product_name is null or trim(s.product_name) ='';

#Verifying the Area current missing count
SELECT COUNT(*) AS missing_area
FROM staging_sales
WHERE Area IS NULL OR TRIM(Area) = '';

#filling the missing areas with 'unknown' without leaving it blank
UPDATE staging_sales
SET Area = 'Unknown Area'
WHERE Area IS NULL OR TRIM(Area) = '';

#Validating the area with the zone where it has a blank value that is filled by the unknown area or not
SELECT s.Area, s.Zone, COUNT(*) AS occurrence
FROM staging_sales s
LEFT JOIN location_master l ON LOWER(TRIM(s.Area)) = LOWER(TRIM(l.Area))
WHERE s.Area <> 'Unknown Area'
AND (
l.Area IS NULL OR LOWER(TRIM(s.Zone)) <> LOWER(TRIM(l.Zone)))
GROUP BY s.Area, s.Zone
ORDER BY occurrence DESC;

#Standardizing the zone 
UPDATE staging_sales s
JOIN location_master l ON LOWER(TRIM(s.Area)) = LOWER(TRIM(l.Area))
SET s.Zone = l.Zone
WHERE s.Area <> 'Unknown Area';

#Re-Validating the duplicate values to verify the duplicate is consist of identical or not
SELECT TRIM(Order_ID) AS Order_ID, COUNT(*) AS occurrence
FROM staging_sales
GROUP BY TRIM(Order_ID)
HAVING COUNT(*) > 1
   AND COUNT(DISTINCT CONCAT_WS('|',
        Customer_ID,
        Clean_order_date,
        Product_ID,
        Product_Name,
        Category,
        Area,
        City,
        State,
        Zone,
        Quantity,
        Unit_Price,
        Discount,
        Sales_Channel,
        Payment_Method,
        Order_Status
   )) = 1
ORDER BY Order_ID;

#Still remaining 13 records are missing that we are investigating now
SELECT TRIM(Order_ID) AS Order_ID, COUNT(*) AS occurrence
FROM staging_sales
GROUP BY TRIM(Order_ID)
HAVING COUNT(*) > 1
   AND COUNT(DISTINCT CONCAT_WS('|',
        Customer_ID,
        Clean_order_Date,
        Product_ID,
        Product_Name,
        Category,
        Area,
        City,
        State,
        Zone,
        Quantity,
        Unit_Price,
        Discount,
        Sales_Channel,
        Payment_Method,
        Order_Status
   )) > 1
ORDER BY Order_ID;

#extracting only the 13 records to compare them with the columns
SELECT
    TRIM(Order_ID) AS Order_ID,
    Customer_ID,
    Clean_order_date,
    Product_ID,
    Product_Name,
    Category,
    Area,
    Zone,
    Quantity,
    Unit_Price,
    Discount,
    Sales_Channel,
    Payment_Method,
    Order_Status
FROM staging_sales
WHERE TRIM(Order_ID) IN (
    'ORD100029',
    'ORD100145',
    'ORD100282',
    'ORD100454',
    'ORD100543',
    'ORD100998',
    'ORD101118',
    'ORD101295',
    'ORD101331',
    'ORD101777',
    'ORD101983',
    'ORD102003',
    'ORD102773'
)
ORDER BY Order_ID;

#adding a staging row_id
ALTER TABLE staging_sales
ADD COLUMN staging_row_id INT AUTO_INCREMENT PRIMARY KEY;

#verifying the row ids
SELECT
    staging_row_id,
    Order_ID,
    Customer_ID,
    Clean_order_date,
    Product_ID,
    Quantity,
    Unit_Price,
    Discount,
    Area,
    Payment_Method
FROM staging_sales
WHERE TRIM(Order_ID) IN (
    'ORD100282',
    'ORD100543',
    'ORD101295',
    'ORD101777',
    'ORD102003',
    'ORD102773'
)
ORDER BY Order_ID, staging_row_id;

#Creating a small table that consist of 6 rows that we are going to delete it 
CREATE TABLE rejected_duplicate_sales AS
SELECT *
FROM staging_sales
WHERE staging_row_id IN (
    2743,
    118,
    292,
    2632,
    1547,
    2668
);

#Verifying that the created table consist of 6 rows or not
SELECT COUNT(*) AS rejected_rows
FROM rejected_duplicate_sales;

#verifying the rows that we are going to remove
SELECT
    staging_row_id,
    Order_ID,
    Customer_ID,
    Clean_Order_Date,
    Product_ID,
    Quantity,
    Unit_Price,
    Discount,
    Area,
    Payment_Method
FROM rejected_duplicate_sales
ORDER BY Order_ID;

#Deleting those 6 rows from the staging table
DELETE FROM staging_sales
WHERE staging_row_id IN (
    2743,
    118,
    292,
    2632,
    1547,
    2668
);

#reserving the count of unresolved issues
SELECT
    COUNT(*) AS unresolved_conflict_rows
FROM staging_sales
WHERE TRIM(Order_ID) IN (
    'ORD100029',
    'ORD100145',
    'ORD100454',
    'ORD100998',
    'ORD101118',
    'ORD101331',
    'ORD101983'
);

#creating a table to store the unresovled issues
CREATE TABLE rejected_conflict_sales AS
SELECT *
FROM staging_sales
WHERE TRIM(Order_ID) IN (
    'ORD100029',
    'ORD100145',
    'ORD100454',
    'ORD100998',
    'ORD101118',
    'ORD101331',
    'ORD101983'
);

#verifying the created table 
SELECT COUNT(*) AS conflict_rows
FROM rejected_conflict_sales;

#Removing those unresolved issues from the staging_sales table
DELETE FROM staging_sales
WHERE TRIM(Order_ID) IN (
    'ORD100029',
    'ORD100145',
    'ORD100454',
    'ORD100998',
    'ORD101118',
    'ORD101331',
    'ORD101983'
);

#Verifying the duplicate records
SELECT TRIM(Order_ID) AS Order_ID, COUNT(*) AS occurrence
FROM staging_sales
GROUP BY TRIM(Order_ID)
HAVING COUNT(*) > 1
ORDER BY occurrence DESC, Order_ID;

#Storing the exact Duplicate values in the new table
CREATE TABLE rejected_exact_duplicates AS
SELECT s.*
FROM staging_sales s
JOIN (
SELECT staging_row_id
FROM (SELECT 
		staging_row_id, ROW_NUMBER() OVER (PARTITION BY TRIM(Order_ID), Customer_ID, Clean_Order_Date, Product_ID, Product_Name, Category, Area, City, State,
                    Zone, Quantity, Unit_Price, Discount, Sales_Channel, Payment_Method, Order_Status ORDER BY staging_row_id) AS rn
                    FROM staging_sales) x
WHERE rn > 1 ) d ON s.staging_row_id = d.staging_row_id;

#Deleting the exact duplicate records from the staging_sales table
DELETE FROM staging_sales
WHERE staging_row_id IN (
    SELECT staging_row_id
    FROM rejected_exact_duplicates
);

#Verifying the staging_sales count now
SELECT COUNT(*) AS staging_row_count
FROM staging_sales;

#checking for any duplicate values exist or not
SELECT TRIM(Order_ID) AS Order_ID, COUNT(*) AS occurrence
FROM staging_sales
GROUP BY TRIM(Order_ID)
HAVING COUNT(*) > 1;

#Checking for the order date quality
SELECT Date_Quality_Status, COUNT(*) AS row_count
FROM staging_sales
GROUP BY Date_Quality_Status
ORDER BY row_count DESC;

#Investigating the invalid year 10 records
SELECT staging_row_id, Order_ID, Order_Date, Clean_Order_Date, Date_Quality_Status
FROM staging_sales
WHERE Date_Quality_Status = 'Invalid Year'
ORDER BY Clean_Order_Date;

#Creating a new table to store the invalid dates
CREATE TABLE rejected_date_quality_sales AS
SELECT *
FROM staging_sales
WHERE Date_Quality_Status IN ('Missing date', 'Invalid year');

#deleting these store invalid dates from the staging_sales table
DELETE FROM staging_sales
WHERE Date_Quality_Status IN ('Missing date', 'Invalid year');

#Checkign the Quantity quality records
SELECT Quantity_Quality_Status, COUNT(*) AS row_count
FROM staging_sales
GROUP BY Quantity_Quality_Status
ORDER BY row_count DESC;

#Investigating the 60 invalid records
SELECT
    staging_row_id,
    Order_ID,
    Quantity,
    Quantity_Quality_Status
FROM staging_sales
WHERE Quantity_Quality_Status <> 'valid'
ORDER BY Quantity, staging_row_id;

#Creating a new table to store the invalid records of the quantity_quality status
CREATE TABLE rejected_quantity_quality_sales AS
SELECT *
FROM staging_sales
WHERE Quantity_Quality_Status <> 'valid';

#Verifying the count after creating the new table for invalid records
SELECT COUNT(*) AS rejected_quantity_rows
FROM rejected_quantity_quality_sales;

#deleting the invalid records of the quantity_quality_status from the staging_sales table
DELETE FROM staging_sales
WHERE Quantity_Quality_Status <> 'valid';

#Checking for the count of unit_price Quality
Select price_quality_status, count(*) as Invalid_price
from staging_sales
group by price_quality_status
order by Invalid_price desc;

#verifying the invalid prices
select staging_row_id, order_id, unit_price, price_quality_status
from staging_sales
where price_quality_status <> 'valid' 
order by unit_price, staging_row_id;

#Creating a new table to store the invalid prices 
Create table rejected_price_quality_sales as 
select *
from staging_sales
where price_quality_status <> 'valid';

#Deleting all the invalid prices from the staging_Sales
Delete From staging_sales
where price_quality_status <> 'valid';

#Checking all the Discount_prices_quality
Select Discount_quality_status, count(*) as row_count
from staging_sales
group by discount_quality_status
order by row_count desc;

#Verifying all the invalid discount prices in the staging_sales
select staging_row_id, order_id, discount, discount_quality_status
from staging_sales
where discount_quality_status <> 'valid'
order by discount, staging_row_id;

#creating a new table to store all the invalid discount prices
Create table rejected_discount_sales as 
select *
from staging_sales
where discount_quality_status <> 'valid';

#Verifying the created new table that all the invalid records are loaded into it
select count(*) as rejected_discount_sales from rejected_discount_sales;

#Deleting all the 21 invalid discount prices from the staging_sales table after storing those records in the new table
Delete From staging_sales
where Discount_quality_status <> 'valid';

#Checking final data quality Validation to ensure everything is clean
Select count(*) as remaining_rows,
sum(case when clean_order_date is Null or Year(clean_order_date) <> 2025 then 1 else 0 end) as Invalid_dates,
sum(case when quantity is Null or quantity <=0 then 1 else 0 end) as Invalid_quantity,
sum(case when unit_price is Null or unit_price <= 0 then 1 else 0 end) as Invalid_prices,
sum(case when discount is Null or discount < 0 or discount > 0.20 then 1 else 0 end) as Invalid_discount
From staging_sales;

