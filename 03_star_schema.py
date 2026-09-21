from pyspark.sql import SparkSession
from pyspark.sql.functions import col, row_number
from pyspark.sql.window import Window

from db_config import JDBC_URL, CONNECTION_PROPERTIES, MYSQL_JAR


# --------------------------------------------------
# 1. Create Spark Session
# --------------------------------------------------

spark = (
    SparkSession.builder
    .appName("HyderabadSalesStarSchema")
    .master("local[*]")
    .config("spark.driver.extraClassPath", MYSQL_JAR)
    .config("spark.executor.extraClassPath", MYSQL_JAR)
    .getOrCreate()
)


# --------------------------------------------------
# 2. Extract transformed data
# --------------------------------------------------

df = (
    spark.read
    .jdbc(
        url=JDBC_URL,
        table="staging_sales",
        properties=CONNECTION_PROPERTIES
    )
)


# --------------------------------------------------
# 3. Apply required transformation
# --------------------------------------------------

df = df.withColumn(
    "Quantity",
    col("Quantity").cast("int")
)

df = df.withColumn(
    "Gross_Sales",
    col("Quantity") * col("Unit_Price")
)

df = df.withColumn(
    "Net_Sales",
    col("Gross_Sales") * (1 - col("Discount"))
)


# --------------------------------------------------
# 4. Create Customer Dimension
# --------------------------------------------------

customer_df = (
    df
    .select("Customer_ID")
    .dropDuplicates()
)

window_spec = Window.orderBy("Customer_ID")

customer_df = customer_df.withColumn(
    "Customer_Key",
    row_number().over(window_spec)
)

customer_df = customer_df.select(
    "Customer_Key",
    "Customer_ID"
)


# --------------------------------------------------
# 5. Validate Customer Dimension
# --------------------------------------------------

print("\nCustomer dimension validation:")

print(
    "Total customer records:",
    customer_df.count()
)

print(
    "Distinct Customer_IDs:",
    customer_df.select("Customer_ID").distinct().count()
)

print(
    "Distinct Customer_Keys:",
    customer_df.select("Customer_Key").distinct().count()
)

print("\nCustomer dimension sample:")
customer_df.show(10, truncate=False)


# --------------------------------------------------
# 5. Verify Customer Dimension
# --------------------------------------------------

print("Customer dimension created!")
print("Customer count:", customer_df.count())

customer_df.show(10, truncate=False)


# --------------------------------------------------
# 6. Stop Spark
# --------------------------------------------------

spark.stop()