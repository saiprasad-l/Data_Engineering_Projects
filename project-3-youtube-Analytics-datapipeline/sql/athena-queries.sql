CREATE DATABASE IF NOT EXISTS youtube_analytics;

CREATE EXTERNAL TABLE youtube_analytics.gold_channel_stats (
  channel_id              string,
  viewCount               bigint,
  subscriberCount         bigint,
  videoCount              bigint
)
PARTITIONED BY (dt string)
STORED AS PARQUET
LOCATION 's3://youtube-pipeline-sai/gold/youtube_channel_stats_daily/';

MSCK REPAIR TABLE youtube_analytics.gold_channel_stats;

SELECT * FROM youtube_analytics.gold_channel_stats ORDER BY dt DESC LIMIT 5;

CREATE EXTERNAL TABLE youtube_analytics.silver_channel_stats (
  channel_id        string,
  viewCount         bigint,
  subscriberCount   bigint,
  videoCount        bigint,
  ts                bigint
)
PARTITIONED BY (dt string)
STORED AS PARQUET
LOCATION 's3://youtube-pipeline-sai/silver/channel_stats/';

MSCK REPAIR TABLE youtube_analytics.silver_channel_stats;

SELECT * FROM youtube_analytics.silver_channel_stats ORDER BY dt DESC LIMIT 5;
