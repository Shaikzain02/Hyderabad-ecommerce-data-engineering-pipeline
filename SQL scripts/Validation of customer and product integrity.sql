#Validate Customer and Product Integrity
Select Count(*) as Invalid_customer_id
from staging_sales s 
left join Customer_master c on trim(s.customer_id) = trim(c.customer_id)
where c.customer_id is Null or trim(s.customer_id) = '';

#Identifying the 42 invalid customers 
SELECT s.staging_row_id, s.Order_ID, s.Customer_ID
FROM staging_sales s
LEFT JOIN customer_master c ON TRIM(s.Customer_ID) = TRIM(c.Customer_ID)
WHERE c.Customer_ID IS NULL OR TRIM(s.Customer_ID) = ''
ORDER BY s.Customer_ID, s.staging_row_id;

#Creating a new table and storing all the invalid customers
CREATE TABLE rejected_customer_quality_sales AS
SELECT *
FROM staging_sales s
WHERE TRIM(s.Customer_ID) = '';

#Verifying all the invalid customers are stored in the created table above or not
select * from rejected_customer_quality_sales;

#Deleting all the invalid customers from the staging_sales table
Delete from Staging_sales
where trim(customer_id) = '';

#Validating the product ids
select count(*) as invalid_product_counts
from staging_sales s
left join product_master p on trim(s.product_id) = trim(p.product_id)
where p.product_id is Null or Trim(p.product_id) = '';

#Validating the product consistency
Select count(*) as product_mismatch_rows
from staging_sales s
join product_master p on trim(s.product_id) = trim(p.product_id)
where trim(s.product_name) <> trim(p.product_name) or trim(s.category) <> trim(p.category);

#Validating the Area in Location master
Select Count(*) as invalid_area_rows
from staging_sales s
left join Location_master l on trim(s.Area) = trim(l.Area)
where l.Area is Null And trim(s.Area) <> 'Unknown Area';

#Validating Area and zone consistency between both the tables
select count(*) as zone_mismatch_rows
from staging_sales s
join location_master l on trim(s.Area) = trim(l.Area) 
where trim(s.area) <> 'Unknown Area' and trim(s.zone) <> trim(l.zone);

#Validation of the city in the staging_sales
Select city, count(*) as City_count
from staging_sales
group by City
order by City_count desc;

#Validation of the State in the Staging_Sales
Select State, Count(*) as State_count
From Staging_sales
Group By State
Order By State_count desc;

#Validating the Sales_channel in the Staging_Sales
Select Sales_channel, Count(*) as Row_count
From Staging_sales
group By Sales_channel
Order by Row_count desc;

#Validating the Payment method in Staging_sales
Select Payment_Method, count(*) as Total_count
From Staging_sales
Group By Payment_method
Order By Total_count desc;

#Validating the Order Status in the Staging_sales
Select Order_status, count(*) as Row_count
From Staging_sales
Group By Order_status
Order By Row_count desc;

#Final Data Quality Validation Check
Select Count(*) as Total_Count,
Sum(Case When Clean_order_date is Null Or Year(Clean_order_date) <> 2025 Then 1 Else 0 End) As Invalid_dates,
Sum(Case When Quantity is Null Or Quantity <= 0 Then 1 Else 0 End) As Invalid_Quantity,
Sum(Case When Unit_price is Null Or Unit_price <=0 Then 1 Else 0 End) As Invalid_Prices,
Sum(Case When Discount is Null Or Discount < 0 Or Discount > 0.20 Then 1 Else 0 End) As Invalid_Discount,
Sum(Case When Trim(Customer_id) = '' Then 1 Else 0 End) As Missing_Customer,
Sum(Case When Trim(Product_id) = '' Then 1 Else 0 End) As Missing_product,
Sum(Case When Trim(City) <> 'Hyderabad' Then 1 Else 0 End) As Invalid_City,
Sum(Case When Trim(State) <> 'Telangana' Then 1 Else 0 End) As Invalid_State
From Staging_sales;