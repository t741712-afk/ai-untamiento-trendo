# AI-untamiento de Trendo

Demo end-to-end de protección de aplicaciones con IA y canal documental seguro utilizando capacidades de Trend Micro (Trend Vision One / TrendAI).

El proyecto simula una sede electrónica municipal con:

- Chatbot basado en LLM (Groq — Llama 3.3 70b)
- Subida de documentación por parte de la ciudadanía
- Dashboard de actividad y protección en tiempo real
- Integración de seguridad con Trend Vision One
- Despliegue automatizado en Ubuntu con un único script

---

# Arranque rápido (Docker Compose en Ubuntu)

El modo recomendado es Docker Compose sobre Ubuntu. No requiere Kubernetes.

## 1. Clonar el repositorio

```bash
git clone https://github.com/t741712-afk/ai-untamiento-trendo.git
cd ai-untamiento-trendo
```

## 2. Configurar credenciales

```bash
cp .env.example .env
nano .env
```

Variables necesarias:

| Variable | Descripción |
|----------|-------------|
| `GROQ_API_KEY` | API key de Groq (gratuita en console.groq.com) |
| `TREND_API_KEY` | API key de Vision One — AI Application Security |
| `TREND_AI_URL` | Endpoint de AI Guard (por defecto región EU) |
| `TREND_AI_APP_NAME` | Nombre de la app en Vision One |
| `FILE_SECURITY_API_KEY` | API key de Vision One — File Security SDK |
| `FILE_SECURITY_REGION` | Región del tenant (`eu-central-1`, `us-east-1`, etc.) |

## 3. Lanzar

```bash
sudo bash deploy.sh
```

Acceso una vez desplegado:

- Frontend: `http://IP_DE_LA_MAQUINA`
- Backend stats: `http://IP_DE_LA_MAQUINA:9000/api/stats`

---

# Despliegue automatizado (Launch Script)

Para lanzar la máquina ya configurada desde cero, usa `launch-script.sh`.
Rellena las credenciales en las primeras líneas y pégalo en el campo "Launch Script" de tu plataforma de virtualización.
El entorno estará disponible en ~5 minutos sin intervención manual.

Puedes seguir el progreso en la máquina con:

```bash
tail -f /var/log/ai-untamiento-deploy.log
```

---

# Arquitectura

## Frontend
- React SPA servida por nginx en puerto 80
- Chat IA con indicador de validación de AI Guard
- Subida de archivos con resultado del scan en tiempo real
- Dashboard de actividad y protección

## Backend (FastAPI — puerto 9000 externo / 8007 interno)
- `POST /api/chat` — chatbot con AI Guard en entrada y salida
- `POST /api/files/upload` — subida con escaneo File Security
- `GET /api/stats` — métricas en tiempo real

## LLM
- Proveedor: **Groq** (gratuito)
- Modelo: `llama-3.3-70b-versatile`
- Temperatura: 0.3 para respuestas consistentes en contexto municipal

## Seguridad

### AI Guard (Trend Vision One)
- Protección frente a prompt injection
- Detección de contenido dañino y amenazas
- Validación de salida del modelo
- Comunicación REST con `api.eu.xdr.trendmicro.com`

### File Security (Trend Vision One)
- Scanner cloud vía SDK gRPC (`init_by_region`)
- Veredicto: `clean` → `/data/uploads/clean/` | `malicious` → `/data/uploads/quarantine/`

---

# Flujo de seguridad

## Chat
1. Usuario → backend
2. Backend → AI Guard (validación de entrada)
3. Si bloqueado → respuesta de rechazo al usuario
4. Si permitido → Groq LLM
5. Respuesta LLM → AI Guard (validación de salida)
6. Respuesta al usuario con badge "Validado por Trend AI Guard"

## Archivos
1. Upload → `/data/uploads/incoming/`
2. Escaneo con Vision One File Security SDK
3. Resultado:
   - `clean` → `/data/uploads/clean/`
   - malicioso → `/data/uploads/quarantine/`
   - error → permanece en `incoming/`

---

# Gestión de secretos

No se suben al repositorio:

- `.env`
- `.env.docker`
- `k8s/secret.yaml`
- `k8s/file-security-secrets.yaml`
- `overrides.yaml`

Sí se suben como plantilla:

- `.env.example`
- `k8s/secret.yaml.template`

---

# Comandos útiles

```bash
# Ver logs en tiempo real
sudo docker compose logs -f

# Reiniciar solo el backend
sudo docker compose up -d --build backend-service

# Parar todo
sudo docker compose down

# Estado de contenedores
sudo docker ps
```

---

# Autores

- Álvaro de Miguel (repo original)
- Toni Sánchez (fork Docker Compose + Vision One cloud)
