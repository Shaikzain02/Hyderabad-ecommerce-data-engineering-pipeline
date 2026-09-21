from pyspark.sql import SparkSession
from pyspark.sql.functions import col, round

from db_config import JDBC_URL, CONNECTION_PROPERTIES, MYSQL_JAR


# --------------------------------------------------
# 1. Create Spark Session
# --------------------------------------------------

spark = (
    SparkSession.builder
    .appName("HyderabadSalesTransformation")
    .master("local[*]")
    .config("spark.driver.extraClassPath", MYSQL_JAR)
    .config("spark.executor.extraClassPath", MYSQL_JAR)
    .getOrCreate()
)


# --------------------------------------------------
# 2. Extract data from MySQL
# --------------------------------------------------

df = (
    spark.read
    .jdbc(
        url=JDBC_URL,
        table="staging_sales",
        properties=CONNECTION_PROPERTIES
    )
)

print("Source rows:", df.count())


# --------------------------------------------------
# 3. Convert Quantity from string to integer
# --------------------------------------------------

df = df.withColumn(
    "Quantity",
    col("Quantity").cast("int")
)


# --------------------------------------------------
# 4. Create Gross Sales
# --------------------------------------------------

df = df.withColumn(
    "Gross_Sales",
    round(
        col("Quantity") * col("Unit_Price"),
        2
    )
)


# --------------------------------------------------
# 5. Create Net Sales
# --------------------------------------------------

df = df.withColumn(
    "Net_Sales",
    round(
        col("Gross_Sales") * (1 - col("Discount")),
        2
    )
)


# --------------------------------------------------
# 6. Check transformed schema
# --------------------------------------------------

print("\nTransformed schema:")
df.printSchema()


# --------------------------------------------------
# 7. Display transformed data
# --------------------------------------------------

print("\nSample transformed records:")

df.select(
    "Order_ID",
    "Quantity",
    "Unit_Price",
    "Discount",
    "Gross_Sales",
    "Net_Sales"
).show(5, truncate=False)


# --------------------------------------------------
# 8. Stop Spark
# --------------------------------------------------

spark.stop()