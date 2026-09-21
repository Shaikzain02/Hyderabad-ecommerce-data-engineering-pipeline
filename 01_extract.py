from pyspark.sql import SparkSession

from db_config import JDBC_URL, CONNECTION_PROPERTIES, MYSQL_JAR


# --------------------------------------------------
# 1. Create Spark Session
# --------------------------------------------------

spark = (
    SparkSession.builder
    .appName("HyderabadSalesETL")
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


# --------------------------------------------------
# 3. Validate extraction
# --------------------------------------------------

print("Extraction successful!")
print("Rows extracted:", df.count())

print("\nExtracted schema:")
df.printSchema()

print("\nSample records:")
df.show(5, truncate=False)


# --------------------------------------------------
# 4. Stop Spark
# --------------------------------------------------

spark.stop()