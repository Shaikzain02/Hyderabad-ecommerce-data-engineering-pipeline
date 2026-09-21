#creating a new staging_sales table for the transformation of the data without editing the raw sales table
create table staging_sales as select * from raw_sales;

#verifying the staging_sales table
select *
from staging_sales;

#Counting how many rows are consist in the staging_sales table
select count(*) as staging_rows
from staging_sales;

#setting Mysql safemode to 0
SET SQL_SAFE_UPDATES = 0;

#removing the spaces from the area column
update staging_sales
set
	Order_id = trim(order_id),
    Customer_ID = trim(Customer_ID),
    Order_Date = trim(Order_Date),
    Product_ID = trim(Product_ID),
    Product_Name = Trim(Product_Name),
    Category = trim(Category),
    Area = trim(Area),
    City = trim(City),
    State = trim(State),
    Zone = trim(Zone),
    Sales_Channel = trim(Sales_Channel),
    Payment_Method = trim(Payment_Method),
    Order_Status = trim(Order_status);

#verifying the transformation that we did above by removing the trailing spaces from the text
select distinct Area
from staging_sales
order by Area;
    
#checking for the white spaces in the columns
select distinct area
from staging_sales
where area = ' ';

#checking for the occurance of the store details in the sales_channel column
select sales_channel, count(*) as occurance
from staging_sales
group by sales_channel
order by occurance desc;

#checking fro the occurance of the paymenth mehtod column
select Payment_method, count(*) as occurance
from staging_sales
group by Payment_method
order by occurance desc;

#Counting for the Null_payment_ids
select count(*) as Null_payments
from staging_sales
where payment_method is Null;

#Counting for the blank_payment_ids
select count(*) as Blank_payment_method
from staging_sales
where trim(payment_method) = ' ';

#checking for the inconsistence values in the order_status
select order_status, count(*) as occurance
from staging_sales
group by order_status
order by occurance desc;

#checking for the inconsistence value in the category column
select category, count(*) as occurance
from staging_sales
group by category
order by occurance desc;

#checking for the Null/Missing values in the category column
select count(*) as category_null_values
from staging_sales
where category is Null;

select count(*) as Blank_values
from staging_sales
where trim(category) = ' ';

#Lets find out the distinct category values in the table
select count(distinct(category)) as Unique_values
from staging_sales;

#counting the occurance of the product_name values
select product_name, count(*) as occurance
from staging_sales
group by product_name
order by occurance desc;
