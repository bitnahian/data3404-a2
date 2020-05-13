from pyspark.sql import SparkSession
from pyspark.sql import functions as F
from operator import add
import argparse
import re

# Number of users per region, most popular users listed first
def top_ten_bidders(spark):

    users = spark.read.csv('s3://data3404-nhas9102/data/auctiondb/users.csv', header=True)\
                 .select(F.col('region').alias('region_id'))

    regions = spark.read.csv('s3://data3404-nhas9102/data/auctiondb/regions.csv', header=True)\
                   .select(F.col('Region id').alias('region_id'), F.col('Region Name').alias('region_name'))

    region_users = regions.join(users, 'region_id', 'left_outer').drop('region_id')

    region_users_count = region_users.groupBy('region_name')\
                                     .count()\
                                     .orderBy("count", ascending=False)
    region_users_count.show()


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Analyse Auction data')
    
    args = parser.parse_args()
    spark = SparkSession\
            .builder.appName('UserPerRegionAnalysis')\
            .getOrCreate()

    top_ten_bidders(spark)
    spark.stop()
    # Adding a comment
    # Adding another comment
