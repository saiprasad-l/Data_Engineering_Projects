import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from pyspark.sql import functions as F

# --- Job Args ---
args = getResolvedOptions(sys.argv, ['JOB_NAME'])

# --- Glue Setup ---
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

# --- Read Bronze JSON ---
bronze_path = f"s3://youtube-pipeline-sai/bronze/channel_stats/"
df = spark.read.json(bronze_path)

# --- Clean / Enrich Data ---
df_clean = (
    df.withColumn("viewCount", F.col("viewCount").cast("long"))
      .withColumn("subscriberCount", F.col("subscriberCount").cast("long"))
      .withColumn("videoCount", F.col("videoCount").cast("long"))
      .withColumn("ts", F.from_unixtime(F.col("ts")).cast("timestamp"))
      .dropna()
)

# --- Write to Silver (Parquet, Partitioned by Date) ---
silver_path = f"s3://youtube-pipeline-sai/silver/channel_stats/"
(
    df_clean.withColumn("dt", F.to_date("ts"))
            .repartition("dt")
            .write.mode("overwrite")
            .partitionBy("dt")
            .parquet(silver_path)
)

job.commit()