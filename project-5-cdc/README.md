<h1 align="center">⚡ Real-Time CDC Pipeline with Debezium, Bytewax, Redis & S3 Monitoring (2025)</h1>

<p align="center">
  <img src="https://img.shields.io/badge/Python-3.10-blue?logo=python&logoColor=white"/>
  <img src="https://img.shields.io/badge/Kafka-Confluent%20Cloud-black?logo=apachekafka"/>
  <img src="https://img.shields.io/badge/Bytewax-Stream%20Processing-8A2BE2?logo=python"/>
  <img src="https://img.shields.io/badge/Redis-Live%20Cache-DC382D?logo=redis&logoColor=white"/>
  <img src="https://img.shields.io/badge/AWS-S3%20%7C%20EC2-orange?logo=amazonaws&logoColor=white"/>
  <img src="https://img.shields.io/badge/Monitoring-Grafana%20%7C%20Prometheus-FFCA28?logo=grafana&logoColor=black"/>
</p>

This project simulates a **production-grade Change Data Capture (CDC) pipeline** designed for **real-time analytics**.  
It continuously captures changes from **PostgreSQL**, streams them to **Kafka (Confluent Cloud)** using **Debezium**,  
transforms events in real time with **Bytewax**, writes the latest state to **Redis**, and archives data into **S3 (Iceberg format)**.  
The entire pipeline is **observable**, **scalable**, and **cloud-ready**.

---

## **Tech Stack**

| Category | Tool / Service | Description |
|-----------|----------------|--------------|
| **Source** | PostgreSQL | Employee table emitting change events (CDC) |
| **CDC Capture** | Debezium | Streams changes from Postgres WAL to Kafka |
| **Messaging Layer** | Confluent Cloud | Fully managed Kafka backbone |
| **Stream Processing** | Bytewax | Python-native framework for real-time transformations |
| **Low-Latency Store** | Redis | Instant data lookup and caching |
| **Data Lake** | AWS S3 + Iceberg | Long-term storage for CDC and analytics |
| **Monitoring** | Prometheus + Grafana | Metrics, alerts, and dashboards |
| **Infra** | Terraform (AWS) | EC2, S3, IAM provisioning |

---

## **Objectives**

- Capture real-time database changes (Insert/Update/Delete) from PostgreSQL  
- Stream CDC events into Bytewax and apply real-time transformations 
- Write the latest state & Archive raw + processed data to S3 in Iceberg format  
- Enable full-stack observability with Prometheus & Grafana  
- Design the pipeline for modularity and scalability  

---

## **End-to-End Data Flow**

1. **Postgres → Debezium → Kafka**  
   Debezium connector listens to the `employees` table and publishes CDC messages to Kafka topics in Confluent Cloud.
2. **Kafka → Bytewax**  
   Bytewax consumes those CDC messages, applies transformations, and forwards results.
3. **Bytewax → Redis + S3**  
   - **Redis** receives real-time upserts for fast data serving  
   - **S3** stores raw and transformed data in Iceberg format for analytics and recovery
4. **Prometheus & Grafana**  
   Monitor CDC throughput, transformation latency, and Redis/S3 write success rates.

---

## **Key Code Components**

### Debezium Connector
#### `postgres-connector.json`
```json
{
  "connector.class": "io.debezium.connector.postgresql.PostgresConnector",
  "tasks.max": "1",
  "database.hostname": "18.xxx.xxx.xxx",
  "database.port": "5432",
  "database.user": "cdc_user",
  "database.password": "cdc123",
  "database.dbname": "cdc_demo",
  "topic.prefix": "postgres_cdc",
  "plugin.name": "pgoutput",
  "publication.name": "debezium_pub",
  "slot.name": "debezium_slot",
  "publication.autocreate.mode": "filtered",
  "tombstones.on.delete": "false",
  "key.converter": "org.apache.kafka.connect.json.JsonConverter",
  "value.converter": "org.apache.kafka.connect.json.JsonConverter"
}
```
### Bytewax Dataflow
#### `cdc_stream.py`
```python
kafka_in = op.input("kafka_in", flow, kafka_source())
transformed = op.map("transform", kafka_in, transform_module.process_cdc)
cleaned = op.filter("remove_none", transformed, lambda x: x is not None)
op.inspect("inspect_records", cleaned)
op.map("send_to_redis", cleaned, send_to_redis)
```
#### `transformations.py`
```python
def process_cdc(msg: KafkaSourceMessage):
    value = msg.value
    if value:
        data = json.loads(value)
        after = data.get("payload", {}).get("after", {})
        if after:
            after["full_name"] = f"{after.get('first_name', '')} {after.get('last_name', '')}"
            return after
```

---
## **Observability & Monitoring**
Real-time pipelines without observability are black boxes.
This project integrates Prometheus + Grafana for complete operational visibility.

### Metric Captured

| Metric | Description |
|-----------|----------------|
|bytewax_records_total |Total records processed in stream
|bytewax_processing_latency_ms |Average transformation time per record
|redis_write_success_total |Successful Redis writes
|redis_write_failures_total |Failed Redis writes
|kafka_consumer_lag |Real-time topic lag per partition

### Grafana Dashboards
- Bytewax Throughput Panel: Events/sec and latency trend
- Kafka Lag Panel: Topic partition lag tracking
- Redis Health Panel: Key writes and error rate
- S3 Storage Panel: Iceberg write success and retry counts

> This visibility ensures SLA adherence and enables root-cause debugging without guesswork.

---
## How to Run

1. Provision Infra
```
cd infra
terraform init && terraform apply -auto-approve
```

2. Start Docker Services
```
cd ec2
docker compose up -d
```
3. Insert a test record in Postgres
```
INSERT INTO employees VALUES (12, 'Liam', 'Johnson', 'IT', '1993-05-12', 'M', 72000, 3);
```
4. Verify outputs
- Redis
```
docker exec -it redis redis-cli KEYS '*'
docker exec -it redis redis-cli GET '12'
```
- Prometheus & Grafana
```
http://<EC2_IP>:9090   # Prometheus
http://<EC2_IP>:3000   # Grafana
```
---
## Next Steps & Enhancements

| Area            | Enhancement |
|-----------------|-------------------------------------------------|
| Data Lake| Integrate **AWS Glue Catalog** for schema versioning and **Iceberg** table management|
| Security| Store credentials securely in **AWS Secrets Manager** or **HashiCorp Vault**|
| Monitoring| Add **Grafana alerts** for lag, latency, or **Redis** write failures|
| Resilience| Implement **DLQ (Dead Letter Queue)** for failed transformation events|
| Scale| Run **Bytewax** in cluster mode (`-w 4`) for horizontal scalability|
| Automation| Add **GitHub Actions** to deploy EC2, push Docker images, and validate infra via `terraform plan` |
| Analytics Layer | Connect **Athena** or **DuckDB** to query **Iceberg** tables in S3|

> Future versions will integrate schema registry, model-driven alerts, and a unified CDC Lakehouse.
---
  <h3 align="center">👤 Author</h3>
<p align="center">
  <b>Sai Prasad L</b><br/>
  <i>Data Engineer | Building Real-Time Data Pipelines for Big Tech</i><br/><br/>
  <a href="https://linkedin.com"><img src="https://img.shields.io/badge/LinkedIn-Follow-blue?logo=linkedin"/></a>
  <a href="https://github.com"><img src="https://img.shields.io/badge/GitHub-Portfolio-black?logo=github"/></a>
</p>
