#!/bin/bash

# Apache Airflow Docker Setup Script (Ubuntu 22.04+)

set -e

echo "Updating system and installing Docker..."

# Install prerequisites
sudo apt-get update -y
sudo apt-get install -y ca-certificates curl gnupg lsb-release

# Add Docker’s official GPG key
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Add Docker repository
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
| sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine and Compose
sudo apt-get update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Add current user to docker group
sudo usermod -aG docker $USER
newgrp docker

echo "Docker installed successfully."

# Airflow Setup
echo "Setting up Airflow directories..."
mkdir -p ~/airflow/{dags,logs,plugins,include}
cd ~/airflow

# Create environment file for Docker Compose
echo -e "AIRFLOW_UID=$(id -u)\nAIRFLOW_GID=0" > .env

# Create Airflow Docker Compose file
cat <<'EOF' > docker-compose.yml
version: '3.8'
x-airflow-common:
  &airflow-common
  image: apache/airflow:2.9.2
  environment:
    &airflow-common-env
    AIRFLOW__CORE__EXECUTOR: LocalExecutor
    AIRFLOW__CORE__FERNET_KEY: <FERNET_KEY>
    AIRFLOW__CORE__LOAD_EXAMPLES: 'False'
    AIRFLOW__API__AUTH_BACKENDS: 'airflow.api.auth.backend.basic_auth'
    AIRFLOW__WEBSERVER__RBAC: 'True'
    AIRFLOW__WEBSERVER__EXPOSE_CONFIG: 'True'
    AIRFLOW__DATABASE__SQL_ALCHEMY_CONN: postgresql+psycopg2://airflow:airflow@postgres/airflow
  volumes:
    - ./dags:/opt/airflow/dags
    - ./logs:/opt/airflow/logs
    - ./plugins:/opt/airflow/plugins
  user: "${AIRFLOW_UID:-50000}:${AIRFLOW_GID:-0}"
  depends_on:
    - postgres

services:
  postgres:
    image: postgres:13
    environment:
      POSTGRES_USER: airflow
      POSTGRES_PASSWORD: airflow
      POSTGRES_DB: airflow
    volumes:
      - postgres-db-volume:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD", "pg_isready", "-U", "airflow"]
      interval: 10s
      retries: 5

  airflow-webserver:
    <<: *airflow-common
    command: webserver
    ports:
      - "8080:8080"
    depends_on:
      - airflow-scheduler
      - postgres

  airflow-scheduler:
    <<: *airflow-common
    command: scheduler
    depends_on:
      - postgres

volumes:
  postgres-db-volume:
EOF


# Generate a Fernet key and inject into docker-compose
FERNET_KEY=$(python3 -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())")
sed -i "s|<FERNET_KEY>|$FERNET_KEY|g" docker-compose.yml

# Start Airflow
echo "Initializing Airflow containers..."
docker compose up -d postgres
sleep 10

docker compose run --rm airflow-webserver airflow db init
docker compose up -d airflow-webserver airflow-scheduler


# Create Admin User

docker exec -it $(docker ps -qf "name=airflow-airflow-webserver") airflow users create \
  --username admin \
  --password admin \
  --firstname Admin \
  --lastname User \
  --role Admin \
  --email admin@example.com

echo "Airflow setup complete. Access it at: http://<EC2-Public-IP>:8080"
echo "Login with: admin / admin"

# Install Required Python Packages inside Airflow containers

docker exec -it airflow-airflow-webserver-1 pip install kafka-python boto3 requests
docker exec -it airflow-airflow-scheduler-1 pip install kafka-python boto3 requests


# Environment Variables (for DAGs)

echo 'KAFKA_BOOTSTRAP=<KAFKA_IP>:9092' | sudo tee -a /etc/environment
echo 'YOUTUBE_API_KEY=<YOUTUBE_API_KEY>' | sudo tee -a /etc/environment
source /etc/environment

docker compose restart airflow-scheduler


# Verify Setup

echo "Listing available DAGs..."
docker exec -it airflow-airflow-webserver-1 airflow dags list

echo "Airflow successfully initialized and ready for pipelines!"