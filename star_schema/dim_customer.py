import sys
from pathlib import Path

from pyspark.sql import SparkSession
from pyspark.sql.functions import row_number
from pyspark.sql.window import Window

sys.path.insert(
    0,
    str(Path(__file__).resolve().parent.parent)
)

from db_config import JDBC_URL, CONNECTION_PROPERTIES, MYSQL_JAR


# Spark session
spark = (
    SparkSession.builder
    .appName("HyderabadCustomerDimension")
    .master("local[*]")
    .config("spark.driver.extraClassPath", MYSQL_JAR)
    .config("spark.executor.extraClassPath", MYSQL_JAR)
    .getOrCreate()
)


# Extract validated customers from staging
sales_df = spark.read.jdbc(
    url=JDBC_URL,
    table="staging_sales",
    properties=CONNECTION_PROPERTIES
)


# Build customer dimension
customer_dim = (
    sales_df
    .select("Customer_ID")
    .dropDuplicates()
    .withColumn(
        "Customer_Key",
        row_number().over(
            Window.orderBy("Customer_ID")
        )
    )
)


# Arrange columns
customer_dim = customer_dim.select(
    "Customer_Key",
    "Customer_ID"
)


# Validate
print("\nCustomer Dimension")
print("Rows:", customer_dim.count())

print("\nSchema:")
customer_dim.printSchema()

print("\nSample:")
customer_dim.show(
    10,
    truncate=False
)


# Write to MySQL
customer_dim.write.jdbc(
    url=JDBC_URL,
    table="dim_customer",
    mode="overwrite",
    properties=CONNECTION_PROPERTIES
)

print("\nSuccessfully written to MySQL: dim_customer")


spark.stop()