from airflow import DAG
from airflow.operators.python import PythonOperator
from datetime import datetime, timedelta
import os, json, time, requests, boto3
from kafka import KafkaProducer, KafkaConsumer

# ---------------- CONFIG ---------------- #
AWS_REGION = "us-east-2"
S3_BUCKET = "youtube-pipeline-sai"
KAFKA_BOOTSTRAP = os.getenv("KAFKA_BOOTSTRAP")
YOUTUBE_API_KEY = os.getenv("YOUTUBE_API_KEY")
CHANNEL_ID = "UC_x5XG1OV2P6uZZ5FSM9Ttw"  # Google Developers

# Glue job names MUST exist in AWS Glue
GLUE_JOB_SILVER = "Channel Bronze to Silver"
GLUE_JOB_GOLD   = "Channel Silver to Gold"

# ---------------- PRODUCER ---------------- #
def produce_to_kafka():
    assert KAFKA_BOOTSTRAP and YOUTUBE_API_KEY, "Missing env vars"
    url = (
        "https://www.googleapis.com/youtube/v3/channels"
        f"?part=statistics&id={CHANNEL_ID}&key={YOUTUBE_API_KEY}"
    )
    r = requests.get(url, timeout=30)
    r.raise_for_status()
    stats = r.json()["items"][0]["statistics"]
    payload = {
        "channel_id": CHANNEL_ID,
        "viewCount": stats.get("viewCount"),
        "subscriberCount": stats.get("subscriberCount"),
        "videoCount": stats.get("videoCount"),
        "ts": int(time.time()),
    }
    producer = KafkaProducer(
        bootstrap_servers=KAFKA_BOOTSTRAP,
        value_serializer=lambda v: json.dumps(v).encode("utf-8"),
    )
    producer.send("youtube_stats", payload)
    producer.flush()
    producer.close()
    print("Produced to Kafka:", payload)

# ---------------- CONSUMER → BRONZE ---------------- #
def consume_to_s3():
    s3 = boto3.client("s3", region_name=AWS_REGION)
    consumer = KafkaConsumer(
        "youtube_stats",
        bootstrap_servers=KAFKA_BOOTSTRAP,
        auto_offset_reset="earliest",
        enable_auto_commit=True,
        value_deserializer=lambda b: json.loads(b.decode("utf-8")),
        consumer_timeout_ms=15000,  # stop after idle
    )

    batch = [msg.value for msg in consumer]
    consumer.close()

    if batch:
        dt = datetime.utcnow().strftime("%Y%m%d")
        key = f"bronze/channel_stats/google_dev/dt={dt}/google_{int(time.time())}.json"
        body = "\n".join(json.dumps(x) for x in batch).encode("utf-8")
        s3.put_object(Bucket=S3_BUCKET, Key=key, Body=body)
        print(f"Wrote {len(batch)} records to s3://{S3_BUCKET}/{key}")
    else:
        print("No messages consumed from Kafka in this run.")

# ---------------- GLUE HELPERS ---------------- #
def trigger_glue_job_silver():
    glue = boto3.client("glue", region_name=AWS_REGION)
    resp = glue.start_job_run(JobName=GLUE_JOB_SILVER)
    run_id = resp["JobRunId"]
    print("Started Glue Silver Job:", run_id)
    return run_id  # <- pushed to XCom automatically

def trigger_glue_job_gold():
    glue = boto3.client("glue", region_name=AWS_REGION)
    resp = glue.start_job_run(JobName=GLUE_JOB_GOLD)
    run_id = resp["JobRunId"]
    print("Started Glue Gold Job:", run_id)
    return run_id  # <- pushed to XCom automatically

def wait_for_glue_job(job_name: str, trigger_task_id: str, **context):
    glue = boto3.client("glue", region_name=AWS_REGION)
    ti = context["ti"]
    run_id = ti.xcom_pull(task_ids=trigger_task_id)
    if not run_id:
        raise RuntimeError(f"No run_id found in XCom from task {trigger_task_id}")

    status = "RUNNING"
    while status in ("RUNNING", "STARTING", "STOPPING"):
        time.sleep(30)
        resp = glue.get_job_run(JobName=job_name, RunId=run_id)
        status = resp["JobRun"]["JobRunState"]
        print(f"Glue Job {job_name} [{run_id}] Status:", status)

    if status != "SUCCEEDED":
        raise RuntimeError(f"Glue Job {job_name} failed with status: {status}")

    print(f"Glue Job {job_name} [{run_id}] SUCCEEDED")

# ---------------- DAG ---------------- #
default_args = {
    "owner": "you",
    "retries": 1,
    "retry_delay": timedelta(minutes=2),
}

with DAG(
    dag_id="youtube_kafka_glue_full_pipeline",
    start_date=datetime(2025, 1, 1),
    schedule_interval="*/5 * * * *",
    catchup=False,
    default_args=default_args,
    tags=["youtube", "kafka", "glue", "s3"],
) as dag:

    t1_produce = PythonOperator(
        task_id="produce_to_kafka",
        python_callable=produce_to_kafka,
    )

    t2_consume_bronze = PythonOperator(
        task_id="consume_to_s3",
        python_callable=consume_to_s3,
    )

    t3_trigger_silver = PythonOperator(
        task_id="trigger_glue_silver",
        python_callable=trigger_glue_job_silver,
    )

    t4_wait_silver = PythonOperator(
        task_id="wait_glue_silver",
        python_callable=wait_for_glue_job,
        op_kwargs={"job_name": GLUE_JOB_SILVER, "trigger_task_id": "trigger_glue_silver"},
    )

    t5_trigger_gold = PythonOperator(
        task_id="trigger_glue_gold",
        python_callable=trigger_glue_job_gold,
    )

    t6_wait_gold = PythonOperator(
        task_id="wait_glue_gold",
        python_callable=wait_for_glue_job,
        op_kwargs={"job_name": GLUE_JOB_GOLD, "trigger_task_id": "trigger_glue_gold"},
    )

    # Orchestration
    t1_produce >> t2_consume_bronze >> t3_trigger_silver >> t4_wait_silver >> t5_trigger_gold >> t6_wait_gold