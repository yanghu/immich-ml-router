# immich-ml-router

A lightweight FastAPI proxy that sits between [Immich](https://immich.app) and its ML backends, routing requests based on task type.

## Motivation

Immich is configured to use a remote GPU server (4090 PC) for ML tasks. When the PC is offline, **all** ML fails — including CLIP semantic search, which should always be available. This router fixes that.

## Routing Logic

```
Immich Server
    │  IMMICH_MACHINE_LEARNING_URL=http://immich-ml-router:3003
    ▼
immich-ml-router
    ├── CLIP (semantic search)
    │     → remote PC (4090) when online
    │     → local CPU server (fallback when PC is offline)
    │
    └── facial-recognition / OCR
          → remote PC only
          → 503 when offline (Immich queues and retries automatically)
```

## Configuration

| Env var | Default | Description |
|---------|---------|-------------|
| `LOCAL_ML_URL` | `http://immich-ml-local:3003` | Always-on CPU ML server |
| `REMOTE_ML_URL` | `http://10.0.10.12:3003` | GPU PC ML server |

## Development

```bash
# Unit tests (fast, no Docker)
make test-unit

# Integration tests (spins up mock backends via Docker Compose on port 13003)
make test-integration

# Both
make test
```

## Build & Deploy

```bash
# Build and push image to Gitea registry
make push

# Pull and restart on debian.lan
ssh yang@debian.lan "docker compose -f /home/yang/docker/immich/docker-compose.yml pull immich-ml-router \
  && docker compose -f /home/yang/docker/immich/docker-compose.yml up -d immich-ml-router"
```

## docker-compose snippet

Add to your Immich `docker-compose.yml`:

```yaml
services:
  immich-ml-local:
    container_name: immich_ml_local
    image: ghcr.io/immich-app/immich-machine-learning:release
    restart: always
    volumes:
      - ml-model-cache:/cache
    environment:
      - REDIS_HOSTNAME=redis
      - MACHINE_LEARNING_MODEL_TTL=300   # exit after 5min idle, freeing ~2GB RAM

  immich-ml-router:
    container_name: immich_ml_router
    image: git.yhu.me/yang/immich-ml-router:latest
    restart: always
    environment:
      - LOCAL_ML_URL=http://immich-ml-local:3003
      - REMOTE_ML_URL=http://<gpu-pc-ip>:3003

volumes:
  ml-model-cache:
```

And in `.env`:
```
IMMICH_MACHINE_LEARNING_URL=http://immich-ml-router:3003
```
