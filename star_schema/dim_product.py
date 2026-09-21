import sys
from pathlib import Path

from pyspark.sql import SparkSession

sys.path.insert(
    0,
    str(Path(__file__).resolve().parent.parent)
)

from db_config import JDBC_URL, CONNECTION_PROPERTIES, MYSQL_JAR


# Spark session
spark = (
    SparkSession.builder
    .appName("HyderabadProductDimension")
    .master("local[*]")
    .config("spark.driver.extraClassPath", MYSQL_JAR)
    .config("spark.executor.extraClassPath", MYSQL_JAR)
    .getOrCreate()
)


# Extract product master
product_df = spark.read.jdbc(
    url=JDBC_URL,
    table="product_master",
    properties=CONNECTION_PROPERTIES
)


# Build product dimension
product_dim = product_df.select(
    "Product_ID",
    "Product_Name",
    "Category",
    "Standard_Price"
).dropDuplicates()


# Generate surrogate key
from pyspark.sql.functions import row_number
from pyspark.sql.window import Window

product_dim = product_dim.withColumn(
    "Product_Key",
    row_number().over(
        Window.orderBy("Product_ID")
    )
)


# Arrange columns
product_dim = product_dim.select(
    "Product_Key",
    "Product_ID",
    "Product_Name",
    "Category",
    "Standard_Price"
)


# Validate
print("\nProduct Dimension")
print("Rows:", product_dim.count())

print("\nSchema:")
product_dim.printSchema()

print("\nData:")
product_dim.show(
    20,
    truncate=False
)


# Write to MySQL
product_dim.write.jdbc(
    url=JDBC_URL,
    table="dim_product",
    mode="overwrite",
    properties=CONNECTION_PROPERTIES
)

print("\nSuccessfully written to MySQL: dim_product")


spark.stop()