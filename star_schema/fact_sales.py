import sys
from pathlib import Path

from pyspark.sql import SparkSession
from pyspark.sql.functions import col, row_number, date_format, when, round
from pyspark.sql.window import Window

sys.path.insert(
    0,
    str(Path(__file__).resolve().parent.parent)
)

from db_config import JDBC_URL, CONNECTION_PROPERTIES, MYSQL_JAR


# Spark session
spark = (
    SparkSession.builder
    .appName("HyderabadSalesFactTable")
    .master("local[*]")
    .config("spark.driver.extraClassPath", MYSQL_JAR)
    .config("spark.executor.extraClassPath", MYSQL_JAR)
    .getOrCreate()
)


# Extract source data
sales_df = spark.read.jdbc(
    url=JDBC_URL,
    table="staging_sales",
    properties=CONNECTION_PROPERTIES
)

product_df = spark.read.jdbc(
    url=JDBC_URL,
    table="product_master",
    properties=CONNECTION_PROPERTIES
)

location_df = spark.read.jdbc(
    url=JDBC_URL,
    table="location_master",
    properties=CONNECTION_PROPERTIES
)

print("Source rows:", sales_df.count())


# Customer mapping
customer_dim = (
    sales_df
    .select("Customer_ID")
    .dropDuplicates()
    .withColumn(
        "Customer_Key",
        row_number().over(Window.orderBy("Customer_ID"))
    )
)

fact_df = sales_df.join(
    customer_dim,
    "Customer_ID",
    "left"
)


# Product mapping
product_dim = (
    product_df
    .select("Product_ID")
    .dropDuplicates()
    .withColumn(
        "Product_Key",
        row_number().over(Window.orderBy("Product_ID"))
    )
)

fact_df = fact_df.join(
    product_dim,
    "Product_ID",
    "left"
)


# Date mapping
date_dim = (
    sales_df
    .select("Clean_order_date")
    .dropDuplicates()
    .filter(col("Clean_order_date").isNotNull())
    .withColumn(
        "Date_Key",
        date_format(
            col("Clean_order_date"),
            "yyyyMMdd"
        ).cast("int")
    )
)

fact_df = fact_df.join(
    date_dim,
    "Clean_order_date",
    "left"
)


# Location mapping
location_dim = (
    location_df
    .select("Area")
    .dropDuplicates()
    .withColumn(
        "Location_Key",
        row_number().over(Window.orderBy("Area"))
    )
)

fact_df = fact_df.join(
    location_dim,
    "Area",
    "left"
)


# Unknown location handling
fact_df = fact_df.withColumn(
    "Location_Key",
    when(
        col("Location_Key").isNull(),
        0
    ).otherwise(col("Location_Key"))
)


# Transform measures
fact_df = (
    fact_df
    .withColumn(
        "Quantity",
        col("Quantity").cast("int")
    )
    .withColumn(
        "Gross_Sales",
        round(
            col("Quantity") * col("Unit_Price"),
            2
        )
    )
    .withColumn(
        "Net_Sales",
        round(
            col("Gross_Sales") * (1 - col("Discount")),
            2
        )
    )
    .withColumn(
        "Sales_Key",
        col("staging_row_id")
    )
)


# Final fact table
fact_df = fact_df.select(
    "Sales_Key",
    "Order_ID",
    "Customer_Key",
    "Product_Key",
    "Date_Key",
    "Location_Key",
    "Quantity",
    "Unit_Price",
    "Discount",
    "Gross_Sales",
    "Net_Sales",
    "Sales_Channel",
    "Payment_Method",
    "Order_Status"
)


# Final validation
print("\nFinal Fact Table")
print("Rows:", fact_df.count())

print(
    "Null Customer Keys:",
    fact_df.filter(
        col("Customer_Key").isNull()
    ).count()
)

print(
    "Null Product Keys:",
    fact_df.filter(
        col("Product_Key").isNull()
    ).count()
)

print(
    "Null Date Keys:",
    fact_df.filter(
        col("Date_Key").isNull()
    ).count()
)

print(
    "Null Location Keys:",
    fact_df.filter(
        col("Location_Key").isNull()
    ).count()
)

print("\nFinal Schema:")
fact_df.printSchema()

print("\nSample:")
fact_df.show(
    10,
    truncate=False
)


# Write to MySQL
fact_df.write.jdbc(
    url=JDBC_URL,
    table="fact_sales",
    mode="overwrite",
    properties=CONNECTION_PROPERTIES
)

print("\nSuccessfully written to MySQL: fact_sales")


spark.stop()