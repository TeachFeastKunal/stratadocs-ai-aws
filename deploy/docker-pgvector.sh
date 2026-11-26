#!/usr/bin/env bash
set -euo pipefail

# ------------------------------------------------------------------------------
# StrataDocs AI — PostgreSQL 16 + pgvector Container Initialization Script
# Runs on DocWorkspace-DB (Private IP: 10.0.1.95) with persistent EBS storage
# ------------------------------------------------------------------------------

DATA_DIR="/mnt/pgdata"
CONTAINER_NAME="docworkspace-pgvector"
DB_NAME="${DB_NAME:-docworkspace}"
DB_USER="${DB_USER:-admin}"
DB_PASSWORD="${DB_PASSWORD:-ChangeMeStrongPassword123!}"

echo "[1/4] Ensuring persistent EBS data directory exists at ${DATA_DIR}..."
sudo mkdir -p "${DATA_DIR}"
sudo chown -R 999:999 "${DATA_DIR}"

echo "[2/4] Pulling official pgvector PostgreSQL 16 image..."
docker pull pgvector/pgvector:pg16

if docker ps -a --format '{{.Names}}' | grep -Eq "^${CONTAINER_NAME}$"; then
  echo "[3/4] Removing existing container ${CONTAINER_NAME} (EBS data remains intact)..."
  docker rm -f "${CONTAINER_NAME}"
fi

echo "[3/4] Starting ${CONTAINER_NAME} on TCP Port 5432 with restart policy..."
docker run -d \
  --name "${CONTAINER_NAME}" \
  --restart unless-stopped \
  -e POSTGRES_DB="${DB_NAME}" \
  -e POSTGRES_USER="${DB_USER}" \
  -e POSTGRES_PASSWORD="${DB_PASSWORD}" \
  -v "${DATA_DIR}:/var/lib/postgresql/data" \
  -p 5432:5432 \
  pgvector/pgvector:pg16

echo "[4/4] Waiting for PostgreSQL readiness and enabling pgvector extension..."
sleep 4
docker exec -i "${CONTAINER_NAME}" psql -U "${DB_USER}" -d "${DB_NAME}" -c "CREATE EXTENSION IF NOT EXISTS vector;"
echo "PostgreSQL 16 + pgvector is live and backed by persistent EBS storage."
