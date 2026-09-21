#Backingup all the data from tmy sql
CREATE TABLE raw_sales_backup AS
SELECT *
FROM raw_sales;

#Verifying the backup data
SELECT COUNT(*) AS backup_rows
FROM raw_sales_backup;