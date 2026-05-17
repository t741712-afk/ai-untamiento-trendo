#!/bin/bash
set -euo pipefail

# =============================================================================
# Credenciales — rellena estos valores antes de usar el script
# =============================================================================
OPENAI_API_KEY=""
TREND_API_KEY=""
TREND_AI_URL="https://api.eu.xdr.trendmicro.com/v3.0/aiSecurity/applyGuardrails"
TREND_AI_APP_NAME="ai-untamiento-trendo"
FILE_SECURITY_API_KEY=""
FILE_SECURITY_REGION="eu-central-1"
# =============================================================================

REPO_URL="https://github.com/t741712-afk/ai-untamiento-trendo.git"
DEST_DIR="/opt/ai-untamiento"

# --- Docker -------------------------------------------------------------------
apt-get update -qq
apt-get install -y -qq ca-certificates curl gnupg git

install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu \
$(. /etc/os-release && echo "${VERSION_CODENAME}") stable" \
    | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update -qq
apt-get install -y -qq \
    docker-ce docker-ce-cli containerd.io \
    docker-buildx-plugin docker-compose-plugin

systemctl enable --now docker

# --- Repo ---------------------------------------------------------------------
git clone "$REPO_URL" "$DEST_DIR"

# --- .env ---------------------------------------------------------------------
cat > "$DEST_DIR/.env" <<EOF
OPENAI_API_KEY=${OPENAI_API_KEY}
TREND_API_KEY=${TREND_API_KEY}
TREND_AI_URL=${TREND_AI_URL}
TREND_AI_APP_NAME=${TREND_AI_APP_NAME}
FILE_SECURITY_API_KEY=${FILE_SECURITY_API_KEY}
FILE_SECURITY_REGION=${FILE_SECURITY_REGION}
BACKEND_PORT=9000
FRONTEND_PORT=80
UPLOAD_DIR=/data/uploads
EOF

# --- Arrancar -----------------------------------------------------------------
cd "$DEST_DIR"
docker compose up -d --build
