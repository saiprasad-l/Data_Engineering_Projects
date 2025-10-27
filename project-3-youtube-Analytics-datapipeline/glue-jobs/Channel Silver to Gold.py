import sys
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from pyspark.sql import functions as F

args = getResolvedOptions(sys.argv, ['JOB_NAME'])
# bucket = args['S3_BUCKET']

sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

# --- Read Silver ---
silver_path = f"s3://youtube-pipeline-sai/silver/channel_stats/"
df = spark.read.parquet(silver_path)

# --- Aggregate to Daily Gold ---
gold_df = (
    df.groupBy("channel_id", "dt")
      .agg(
          F.max("viewCount").alias("end_views"),
          F.min("viewCount").alias("start_views"),
          F.max("subscriberCount").alias("end_subs"),
          F.min("subscriberCount").alias("start_subs")
      )
      .withColumn("views_gained", F.col("end_views") - F.col("start_views"))
      .withColumn("subs_gained", F.col("end_subs") - F.col("start_subs"))
)

# --- Write to Gold ---
gold_path = f"s3://youtube-pipeline-sai/gold/youtube_channel_stats_daily/"
gold_df.write.mode("overwrite").partitionBy("dt").parquet(gold_path)

job.commit()