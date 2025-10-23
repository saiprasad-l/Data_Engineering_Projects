# 🎥 Project 3: YouTube Analytics ETL Pipeline using Kafka, Airflow, and AWS(Glue & S3)

This project simulates a production-grade real-time → batch data pipeline on AWS using streaming ingestion, data lake architecture (Bronze → Silver → Gold), and workflow orchestration.

This pipeline tracks YouTube channel statistics (views, subscribers, video count) over time using Kafka, processes them via AWS Glue, and makes them queryable through Athena.

---
##  Tools & Technologies

| Tool / Service        | Purpose                                               |
|-----------------------|-------------------------------------------------------|
| AWS EC2               | Hosts Docker containers for Kafka and Airflow         |
| Docker                | Containerization for Kafka, Airflow, Postgres         |
| Apache Kafka          | Real-time ingestion of YouTube statistics             |
| Apache Airflow        | Orchestration of pipeline steps                       |
| AWS S3                | Data Lake storage (Bronze, Silver, Gold)              |
| AWS Glue              | ETL transformation using PySpark                      |
| AWS Athena            | SQL queries on processed data stored in S3            |
| YouTube Data API      | Source of channel statistics (viewCount, subscriberCount, videoCount) |

---

## Objectives

- Ingest YouTube channel statistics using Kafka.
- Land raw JSON data into S3 Bronze using Airflow.
- Transform Bronze JSON to Silver Parquet with AWS Glue (type casting, partitioning).
- Transform Silver to Gold with daily aggregated metrics (growth analysis).
- Query and verify Gold data using AWS Athena.
- Maintain production-like structure with modular components in Git.

---

## Project Structure

---

## Data Sources & Lake Layers


| Layer / Source       | Location in S3                                            | Format  | Description                                      |
|----------------------|-----------------------------------------------------------|---------|--------------------------------------------------|
| Source (YouTube API) | Fetched via REST: `channels?part=statistics&id=...`      | JSON    | Raw API response                                 |
| Bronze               | `s3://youtube-pipeline-sai/bronze/channel_stats/`        | JSON    | Raw Kafka consumption, no schema enforced        |
| Silver               | `s3://youtube-pipeline-sai/silver/channel_stats/`        | Parquet | Cleaned, casted, partitioned by `dt`             |
| Gold                 | `s3://youtube-pipeline-sai/gold/youtube_channel_stats_daily/` | Parquet | Aggregated daily metrics per channel             |

---

## Transformations (What actually happens to the data)

### 1) Bronze → Silver (Glue: bronze_to_silver.py)

**Input:** newline JSON with keys
channel_id (str), viewCount (str), subscriberCount (str), videoCount (str), ts (epoch seconds)

**Operations:**
- Cast to numeric types:
viewCount → BIGINT, subscriberCount → BIGINT, videoCount → BIGINT
- Normalize timestamp: keep ts as BIGINT (optionally convert to event_time TIMESTAMP)
- Drop obvious nulls and duplicates
- Add dt partition as YYYYMMDD derived from run context or timestamp
- Write Parquet partitioned by dt

**Silver schema (effective):**

channel_id STRING,

viewCount BIGINT,

subscriberCount BIGINT,

videoCount BIGINT,

ts BIGINT,

dt STRING     -- partition

### 2) Silver → Gold (Glue: silver_to_gold.py)

**Goal:** Compute daily metrics per channel (end-of-day snapshot + growth).

**Aggregations (per channel_id, dt):**
- end_views = max(viewCount)
- start_views = min(viewCount)
- end_subs = max(subscriberCount)
- start_subs = min(subscriberCount)
- views_gained = end_views - start_views
- subs_gained = end_subs - start_subs

**Gold schema:**

channel_id STRING,

end_views BIGINT,

start_views BIGINT,

end_subs BIGINT,

start_subs BIGINT,

views_gained BIGINT,

subs_gained BIGINT,

dt STRING     -- partition

---

## End-to-End Pipeline Flow

1. Airflow Task 1 – Produce to Kafka
	- Fetch channel stats from YouTube API using requests
	- Send message to Kafka topic youtube_stats
2. Airflow Task 2 – Consume Kafka → S3 (Bronze)
	- Read messages from Kafka
	- Append to JSON file with path: s3://youtube-pipeline-sai/bronze/channel_stats/dt=YYYYMMDD/file.json
3. Airflow Task 3 – Trigger Glue Bronze → Silver
	- Converts raw JSON to Parquet
	- Casts view/subscriber counts to BIGINT
	- Adds dt partition
4. Airflow Task 4 – Trigger Glue Silver → Gold
	- Aggregates per day per channel
	- Writes Parquet to: s3://youtube-pipeline-sai/gold/youtube_channel_stats_daily/
5. Athena
	- Athena tables are created on Silver & Gold paths
	- Verified using SQL

---
## How to Run

1. On EC2 (Kafka + Airflow):
```
docker-compose -f docker-compose-kafka.yml up -d 
docker-compose -f docker-compose-airflow.yml up -d
```

2. Set environment variables in Airflow .env:
```
KAFKA_BOOTSTRAP=172.31.xx.xx:9092
YOUTUBE_API_KEY=xxxxxxxxxxxxxxxx
AWS_ACCESS_KEY_ID=xxxxxx
AWS_SECRET_ACCESS_KEY=xxxxxx
AWS_REGION=us-east-2
```
3. Enable DAG in Airflow UI → Trigger manually or schedule every 5 mins

4. AWS Glue Jobs
    - youtube_bronze_to_silver
    - youtube_silver_to_gold

5. Athena – Query Data
```
SELECT * FROM youtube_analytics.youtube_channel_stats_daily ORDER BY dt DESC;
```
---

## Enhancements & Next Steps

- Dashboards: Athena federated queries → QuickSight/Redash for daily channel growth & alerts
- Observability: Add Slack/Email alerts in Airflow on task failure; log Glue metrics to CloudWatch
- Backfills: Parameterize dt for historical reprocessing via Airflow variables
- Stronger Validations: Great Expectations on Silver/Gold with Data Docs export
- Video-Level Pipeline: New DAG & topic (youtube_trending) for mostPopular by region; extend Silver/Gold
- Cost/Perf: Consider compaction, larger Parquet row groups, partition pruning practices
- Security: Restrict SGs, rotate keys, use IAM roles for EC2 (instance profiles) instead of static keys

---

##  Author

**Sai Prasad L**  
_Data Engineer | Building Data Portfolios for Big Tech_
