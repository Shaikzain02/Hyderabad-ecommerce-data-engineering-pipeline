import sys
from pathlib import Path

from pyspark.sql import SparkSession
from pyspark.sql.functions import lit, row_number
from pyspark.sql.window import Window

sys.path.insert(
    0,
    str(Path(__file__).resolve().parent.parent)
)

from db_config import JDBC_URL, CONNECTION_PROPERTIES, MYSQL_JAR


# Spark session
spark = (
    SparkSession.builder
    .appName("HyderabadLocationDimension")
    .master("local[*]")
    .config("spark.driver.extraClassPath", MYSQL_JAR)
    .config("spark.executor.extraClassPath", MYSQL_JAR)
    .getOrCreate()
)


# Extract location master
location_df = spark.read.jdbc(
    url=JDBC_URL,
    table="location_master",
    properties=CONNECTION_PROPERTIES
)


# Build real locations
real_location_df = (
    location_df
    .select(
        "Area",
        "City",
        "State",
        "Zone"
    )
    .dropDuplicates()
    .withColumn(
        "Location_Key",
        row_number().over(Window.orderBy("Area")
        )
    )
)


# Create Unknown Location member
unknown_location = (
    real_location_df
    .limit(1)
    .select(
        lit(0).alias("Location_Key"),
        lit("Unknown Area").alias("Area"),
        lit("Hyderabad").alias("City"),
        lit("Telangana").alias("State"),
        lit("Unknown Zone").alias("Zone")
    )
)


# Combine Unknown + real locations
location_dim = unknown_location.unionByName(
    real_location_df.select(
        "Location_Key",
        "Area",
        "City",
        "State",
        "Zone"
    )
)


# Validate
print("\nLocation Dimension")
print("Rows:", location_dim.count())

print("\nSchema:")
location_dim.printSchema()

print("\nData:")
location_dim.orderBy("Location_Key").show(
    25,
    truncate=False
)


# Write to MySQL
location_dim.write.jdbc(
    url=JDBC_URL,
    table="dim_location",
    mode="overwrite",
    properties=CONNECTION_PROPERTIES
)

print("\nSuccessfully written to MySQL: dim_location")


spark.stop()