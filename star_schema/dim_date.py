import sys
from pathlib import Path

from pyspark.sql import SparkSession
from pyspark.sql.functions import (
    col,
    lit,
    year,
    quarter,
    month,
    monthname,
    dayofmonth,
    sequence,
    explode,
    to_date,
    expr
)

sys.path.insert(
    0,
    str(Path(__file__).resolve().parent.parent)
)

from db_config import JDBC_URL, CONNECTION_PROPERTIES, MYSQL_JAR


# Spark session
spark = (
    SparkSession.builder
    .appName("HyderabadDateDimension")
    .master("local[*]")
    .config("spark.driver.extraClassPath", MYSQL_JAR)
    .config("spark.executor.extraClassPath", MYSQL_JAR)
    .getOrCreate()
)


# Create complete 2025 calendar
date_dim = (
    spark.range(1)
    .select(
        explode(
            sequence(
                to_date(lit("2025-01-01")),
                to_date(lit("2025-12-31")),
                expr("INTERVAL 1 DAY")
            )
        ).alias("Date")
    )
)


# Create date attributes
date_dim = (
    date_dim
    .withColumn(
        "Date_Key",
        year(col("Date")) * 10000
        + month(col("Date")) * 100
        + dayofmonth(col("Date"))
    )
    .withColumn(
        "Year",
        year(col("Date"))
    )
    .withColumn(
        "Quarter",
        quarter(col("Date"))
    )
    .withColumn(
        "Month_Number",
        month(col("Date"))
    )
    .withColumn(
        "Month_Name",
        monthname(col("Date"))
    )
    .withColumn(
        "Day",
        dayofmonth(col("Date"))
    )
)


# Arrange columns
date_dim = date_dim.select(
    "Date_Key",
    "Date",
    "Year",
    "Quarter",
    "Month_Number",
    "Month_Name",
    "Day"
)


# Validate
print("\nDate Dimension")
print("Rows:", date_dim.count())

print("\nSchema:")
date_dim.printSchema()

print("\nSample:")
date_dim.show(
    10,
    truncate=False
)


# Write to MySQL
date_dim.write.jdbc(
    url=JDBC_URL,
    table="dim_date",
    mode="overwrite",
    properties=CONNECTION_PROPERTIES
)

print("\nSuccessfully written to MySQL: dim_date")


spark.stop()