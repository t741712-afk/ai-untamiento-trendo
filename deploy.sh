#!/bin/bash
# Deploy script para Ubuntu — AI-untamiento de Trendo
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log()  { echo -e "${GREEN}[+]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }
die()  { echo -e "${RED}[✗]${NC} $*" >&2; exit 1; }

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# 1. Docker
# =============================================================================
install_docker() {
    log "Instalando Docker Engine..."
    apt-get update -qq
    apt-get install -y -qq ca-certificates curl gnupg

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
    log "Docker instalado: $(docker --version)"
}

if ! command -v docker &>/dev/null; then
    [[ $EUID -ne 0 ]] && die "Docker no está instalado. Ejecuta el script como root o con sudo."
    install_docker
else
    log "Docker ya presente: $(docker --version)"
fi

if ! docker compose version &>/dev/null; then
    die "El plugin 'docker compose' no está disponible. Reinstala Docker Engine."
fi

# =============================================================================
# 2. Fichero .env
# =============================================================================
ENV_FILE="$REPO_DIR/.env"

if [[ ! -f "$ENV_FILE" ]]; then
    warn ".env no encontrado. Generando desde .env.example..."
    cp "$REPO_DIR/.env.example" "$ENV_FILE"
    warn "Rellena $ENV_FILE con tus credenciales y vuelve a ejecutar deploy.sh"
    exit 0
fi

# Validar variables obligatorias
REQUIRED_VARS=(
    OPENAI_API_KEY
    TREND_API_KEY
    TREND_AI_URL
    TREND_AI_APP_NAME
    FILE_SECURITY_API_KEY
    FILE_SECURITY_HOST
)

source "$ENV_FILE"

MISSING=()
for var in "${REQUIRED_VARS[@]}"; do
    val="${!var:-}"
    if [[ -z "$val" ]]; then
        MISSING+=("$var")
    fi
done

if [[ ${#MISSING[@]} -gt 0 ]]; then
    die "Faltan estas variables en .env:\n$(printf '  - %s\n' "${MISSING[@]}")"
fi

log "Todas las variables obligatorias presentes."

# =============================================================================
# 3. Build y arranque
# =============================================================================
log "Construyendo imágenes y levantando contenedores..."
cd "$REPO_DIR"
docker compose up -d --build

# =============================================================================
# 4. Verificación
# =============================================================================
log "Esperando a que el backend responda..."
BACKEND_PORT="${BACKEND_PORT:-9000}"
FRONTEND_PORT="${FRONTEND_PORT:-8081}"
MAX_WAIT=60
ELAPSED=0

until curl -sf "http://localhost:${BACKEND_PORT}/" &>/dev/null; do
    sleep 2
    ELAPSED=$((ELAPSED + 2))
    if [[ $ELAPSED -ge $MAX_WAIT ]]; then
        warn "El backend tardó más de ${MAX_WAIT}s. Revisa los logs:"
        warn "  docker compose logs backend-service"
        break
    fi
done

echo ""
echo "=============================================="
log "Despliegue completado"
echo "  Frontend → http://localhost"
echo "  Backend  → http://localhost:${BACKEND_PORT}/api/stats"
echo ""
echo "  Logs:  docker compose logs -f"
echo "  Parar: docker compose down"
echo "=============================================="
