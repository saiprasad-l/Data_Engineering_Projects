#!/bin/bash

# Kafka + Zookeeper Docker Setup Script (Ubuntu 22.04+)

set -e

echo "Updating system and installing Docker..."

# Install prerequisites
sudo apt-get update -y
sudo apt-get install -y ca-certificates curl gnupg lsb-release

# Add Docker’s official GPG key
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Set up the repository
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
| sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine + Compose
sudo apt-get update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Add current user to docker group
sudo usermod -aG docker $USER
newgrp docker

# Kafka Setup

mkdir -p ~/kafka && cd ~/kafka

cat <<'EOF' > docker-compose.yml
version: "3.8"

services:
  zookeeper:
    image: bitnami/zookeeper:3
    container_name: zookeeper
    environment:
      - ALLOW_ANONYMOUS_LOGIN=yes
    ports:
      - "2181:2181"

  kafka:
    image: bitnami/kafka:3
    container_name: kafka
    depends_on:
      - zookeeper
    ports:
      - "9092:9092"   # External (for EC2 / Airflow access)
      - "29092:29092" # Internal (for local container comm)
    environment:
      - KAFKA_BROKER_ID=1
      - KAFKA_CFG_ZOOKEEPER_CONNECT=zookeeper:2181
      - KAFKA_CFG_LISTENERS=INTERNAL://0.0.0.0:29092,EXTERNAL://0.0.0.0:9092
      - KAFKA_CFG_ADVERTISED_LISTENERS=INTERNAL://kafka:29092,EXTERNAL://<PRIVATE_EC2_IP>:9092
      - KAFKA_CFG_LISTENER_SECURITY_PROTOCOL_MAP=INTERNAL:PLAINTEXT,EXTERNAL:PLAINTEXT
      - KAFKA_INTER_BROKER_LISTENER_NAME=INTERNAL
      - ALLOW_PLAINTEXT_LISTENER=yes
EOF

# Replace with actual EC2 private IP automatically
sed -i "s|<PRIVATE_EC2_IP>|$(hostname -I | awk '{print $1}')|g" docker-compose.yml

echo "Docker Compose file created successfully."
echo "Starting Kafka + Zookeeper containers..."
docker compose down -v
docker compose up -d

echo "Waiting for Kafka to initialize..."
sleep 15

echo "Creating Kafka topic: youtube_stats..."
docker exec -it kafka kafka-topics.sh \
  --create \
  --topic youtube_stats \
  --bootstrap-server kafka:29092 \
  --partitions 1 \
  --replication-factor 1

echo "Listing topics..."
docker exec -it kafka kafka-topics.sh --list --bootstrap-server kafka:29092

echo "Kafka setup complete. To test message flow:"
echo "docker exec -it kafka kafka-console-producer.sh --bootstrap-server kafka:29092 --topic youtube_stats"
echo "docker exec -it kafka kafka-console-consumer.sh --bootstrap-server kafka:29092 --topic youtube_stats --from-beginning"