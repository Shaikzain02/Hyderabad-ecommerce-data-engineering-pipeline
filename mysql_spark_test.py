import os
from pathlib import Path 
from dotenv import load_dotenv
from pyspark.sql import SparkSession

# Load variables from .env
load_dotenv()

# Read MySQL configuration
mysql_host = os.getenv("MYSQL_HOST")
mysql_port = os.getenv("MYSQL_PORT")
mysql_database = os.getenv("MYSQL_DATABASE")
mysql_user = os.getenv("MYSQL_USER")
mysql_password = os.getenv("MYSQL_PASSWORD")


#Create Spark Session
mysql_jar = str(
    Path(__file__).resolve().parent
    / "jars"
    / "mysql-connector-j-26.7.0.jar"
)

spark = (
    SparkSession.builder
    .appName("HyderabadSalesMySQLConnection")
    .master("local[*]")
    .config("spark.driver.extraClassPath", mysql_jar)
    .config("spark.executor.extraClassPath", mysql_jar)
    .getOrCreate()
)

# MySQL JDBC URL
jdbc_url = (
    f"jdbc:mysql://{mysql_host}:{mysql_port}/{mysql_database}"
)

# MySQL connection properties
connection_properties = {
    "user": mysql_user,
    "password": mysql_password,
    "driver": "com.mysql.cj.jdbc.Driver"
}

# Read staging_sales from MySQL
df = (
    spark.read
    .jdbc(
        url=jdbc_url,
        table="staging_sales",
        properties=connection_properties
    )
)

# Verify the connection
print("MySQL connection successful!")
print("Total rows:", df.count())

print("\nSchema:")
df.printSchema()

print("\nSample records:")
df.show(5, truncate=False)

spark.stop()