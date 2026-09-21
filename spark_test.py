from pyspark.sql import SparkSession

spark = (
    SparkSession.builder
    .appName("HyderabadSalesPipeline")
    .master("local[*]")
    .getOrCreate()
)

print("Spark version:", spark.version)
print("Spark session created successfully!")

spark.stop()