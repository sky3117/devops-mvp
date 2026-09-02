# Architecture

## Components

- **Frontend**: Next.js app, server-rendered, calls backend REST API. Runs as 2+ pods behind
  an Ingress.
- **Backend**: FastAPI, stateless (safe to scale horizontally). Each pod connects to shared
  PostgreSQL and Redis. Exposes `/healthz` (liveness), `/readyz` (readiness — checks DB+Redis),
  `/metrics` (Prometheus).
- **PostgreSQL**: Deployed as a StatefulSet with a PersistentVolumeClaim — data survives pod
  restarts. In cloud environments, prefer managed RDS (see `terraform/modules/rds`) over
  self-hosting in-cluster.
- **Redis**: Deployment used purely as a cache (task list caching, 30s TTL) — not
  a source of truth, so it doesn't need persistence guarantees.

## Networking

Ingress (nginx) terminates TLS (cert-manager + Let's Encrypt) and routes:
- `taskmanager.example.com` → frontend Service (port 3000)
- `api.taskmanager.example.com` → backend Service (port 8000)

## Security boundaries

- Non-root containers (both Dockerfiles create dedicated users).
- Secrets injected via Kubernetes Secrets / Helm `--set` at deploy time — never committed.
- RBAC enforced at the API layer (`admin`, `manager`, `member` roles) in addition to k8s RBAC
  for cluster-level access control (not included here — add `k8s/rbac.yaml` per team needs).
- Trivy scans every image for CRITICAL CVEs before it reaches the registry; Semgrep scans code
  for common vulnerability patterns and hardcoded secrets.

## Data flow: creating a task

1. User logs in → frontend stores JWT.
2. `POST /api/v1/tasks` with `Authorization: Bearer <token>`.
3. Backend validates JWT → `get_current_user` dependency.
4. Task inserted into PostgreSQL, owner_id = current user.
5. Redis cache for that user's task list is invalidated (`cache_delete_pattern`).
6. Response returned; Prometheus increments `http_requests_total`.
