import os
from pathlib import Path

from dotenv import load_dotenv


# Load environment variables
load_dotenv()


# MySQL configuration
MYSQL_HOST = os.getenv("MYSQL_HOST")
MYSQL_PORT = os.getenv("MYSQL_PORT")
MYSQL_DATABASE = os.getenv("MYSQL_DATABASE")
MYSQL_USER = os.getenv("MYSQL_USER")
MYSQL_PASSWORD = os.getenv("MYSQL_PASSWORD")


# MySQL JDBC driver
MYSQL_JAR = str(
    Path(__file__).resolve().parent.parent
    / "jars"
    / "mysql-connector-j-26.7.0.jar"
)


# JDBC connection URL
JDBC_URL = (
    f"jdbc:mysql://{MYSQL_HOST}:{MYSQL_PORT}/{MYSQL_DATABASE}"
)


# JDBC connection properties
CONNECTION_PROPERTIES = {
    "user": MYSQL_USER,
    "password": MYSQL_PASSWORD,
    "driver": "com.mysql.cj.jdbc.Driver"
}