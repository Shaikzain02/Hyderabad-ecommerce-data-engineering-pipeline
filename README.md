# Hyderabad E Commerce Data Engineering Pipeline

An end to end data engineering and analytics project that transforms raw Hyderabad E commerce data into a validated analytical model and Power BI dashboard.

## 🚀 Pipeline

Excel → MySQL → SQL Cleaning → PySpark ETL → Star Schema → Power BI → Power BI Service

## 🛠️ Tech Stack

- MySQL / SQL
- Python
- PySpark
- JDBC
- Power BI
- DAX
- Excel

## 🔹 What I Built

- Loaded raw e-commerce data into MySQL while preserving the raw layer.
- Created a staging layer for data cleaning and validation.
- Handled duplicates, missing values, invalid dates, prices, quantities, and discounts.
- Performed data quality and referential integrity checks.
- Used PySpark and JDBC for ETL processing.
- Built a star schema with fact and dimension tables.
- Created DAX measures and a Power BI dashboard.
- Published the final report to Power BI Service.

## ⭐ Final Data Model

```text
                 dim_customer
                      │
                      ▼
dim_product ──── fact_sales ──── dim_date
                      │
                      ▼
                dim_location
