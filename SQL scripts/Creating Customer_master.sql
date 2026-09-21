#Verifying the Customer_master table
select count(*) as Customer_count
from customer_master;

#Renaming the ï»¿Customer_ID to customere_id
Alter table Customer_master
rename column ï»¿Customer_ID to Customer_ID;

#limting the 10 customer_id
select *
from customer_master
limit 10;

#validating the customer_id is in the staging_sales or not
select count(*) as invalid_customer_id
from staging_sales s
join customer_master c on s.customer_id = c.customer_id
where c.customer_id is Null;

#validating the customer attributes in staging_sales and customer_master
SELECT s.Customer_ID, s.Area AS Sales_Area, c.Customer_Area AS Master_Area, COUNT(*) AS occurrence
FROM staging_sales s
JOIN customer_master c ON s.Customer_ID = c.Customer_ID
WHERE s.Area IS NOT NULL AND TRIM(s.Area) <> '' AND TRIM(s.Area) <> TRIM(c.Customer_Area)
GROUP BY s.Customer_ID, s.Area, c.Customer_Area
ORDER BY occurrence DESC;

#mismatched area in customer_master and staging_sales
SELECT COUNT(*) AS area_mismatched_rows
FROM staging_sales s
JOIN customer_master c ON s.Customer_ID = c.Customer_ID
WHERE TRIM(LOWER(s.Area)) <> TRIM(LOWER(c.Customer_Area));

#verifying the formatting differnce in both the table staging_sales and customer_master
SELECT COUNT(*) AS area_case_differences
FROM staging_sales s
JOIN customer_master c ON s.Customer_ID = c.Customer_ID
WHERE TRIM(s.Area) <> TRIM(c.Customer_Area) AND TRIM(LOWER(s.Area)) = TRIM(LOWER(c.Customer_Area));

#Validating the data dictionary table
select *
from data_dictionary;

#Renaming the column name
Alter table data_dictionary
Rename column ï»¿Column to Column_name;

#counting the data dictionary total values
select count(*) as dictionary_rows
from data_dictionary;

#Validating the column names in Location_Master
select * from Location_Master;

#Renaming the ï»¿City to city
Alter table Location_Master
Rename Column ï»¿City to City;

#Validating the Area Against the Location Master
SELECT s.Area, COUNT(*) AS occurrence
FROM staging_sales s
LEFT JOIN location_master l ON LOWER(TRIM(s.Area)) = LOWER(TRIM(l.Area))
WHERE l.Area IS NULL
GROUP BY s.Area
ORDER BY occurrence DESC;

#verifying the occurance of the area in staging_sales
SELECT Area, COUNT(*) AS occurrence
FROM staging_sales
GROUP BY Area
ORDER BY occurrence DESC;

#More specific occurance
SELECT s.Order_ID, s.Customer_ID, s.Area, s.Zone, s.City, s.State
FROM staging_sales s
LEFT JOIN location_master l ON LOWER(TRIM(s.Area)) = LOWER(TRIM(l.Area))
WHERE l.Area IS NULL;

#Verifying the Location master shows any recovery for the remaining 34 areas
SELECT l.Area, l.Zone, COUNT(*) AS occurrence
FROM location_master l
GROUP BY l.Area, l.Zone
ORDER BY l.Zone, l.Area;

#Counting the occurance of the city in staging_sales
select city, count(*) as occurance
from staging_sales
group by city
order by occurance desc;

#Counting the occurance of the State in staging_sales
Select State, count(*) as occurance
From staging_sales
group by State
order by occurance desc;

#Counting the occurance of the Zone in staging_sales
Select Zone, count(*) as occurance
From staging_sales
group by Zone
order by occurance desc;

#Joining staging sales and location master on comparing the zone 
select s.area, s.zone, l.zone as master_zone, count(*) as occurance
from staging_sales s 
join location_master l on lower(trim(s.area)) = lower(trim(l.area))
where lower(trim(s.zone))<> lower(trim(l.zone))
group by s.area, s.zone, l.zone
order by occurance desc;

#validating the zones before modifying  staging Zone ≠ Location_Master Zone
select count(*) as Zone_mismatched_rows
from staging_sales s 
join location_master l on lower(trim(s.area)) = lower(trim(l.area))
where lower(trim(s.zone)) <> lower(trim(l.zone));

#Replacing the incorrect sales zone to the correct zone
UPDATE staging_sales s
JOIN location_master l ON LOWER(TRIM(s.Area)) = LOWER(TRIM(l.Area))
SET s.Zone = l.Zone
WHERE LOWER(TRIM(s.Zone)) <> LOWER(TRIM(l.Zone));

#validating the zones after modifying the staging zones = location master
select count(*) as Zone_mismatched_rows
from staging_sales s 
join location_master l on lower(trim(s.area)) = lower(trim(l.area))
where lower(trim(s.zone)) <> lower(trim(l.zone));

