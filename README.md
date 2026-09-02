# 🚀 TaskManager — Full DevOps MVP

A production-shaped reference project demonstrating a complete DevOps stack:
Application → Docker → Kubernetes → Helm → CI/CD → IaC → Monitoring → Logging → Security.

## Architecture

```
┌─────────────┐      ┌─────────────┐
│  Next.js UI │─────▶│  FastAPI    │─────▶ PostgreSQL (StatefulSet)
│  (frontend) │      │  (backend)  │─────▶ Redis (cache)
└─────────────┘      └─────────────┘
       │                     │
       ▼                     ▼
   Ingress/TLS          /metrics ──▶ Prometheus ──▶ Grafana
                         /healthz, /readyz ──▶ K8s probes
                         logs ──▶ Promtail ──▶ Loki ──▶ Grafana
```

Full request path: Internet → Ingress (nginx + cert-manager TLS) → Service → Pod
→ FastAPI → PostgreSQL/Redis. Backend exposes Prometheus metrics and structured logs.

## Tech Stack

| Layer | Tech |
|---|---|
| Frontend | Next.js 14, React 18 |
| Backend | FastAPI, SQLAlchemy, JWT auth, RBAC |
| Database | PostgreSQL 16 |
| Cache | Redis 7 |
| Containers | Docker (multi-stage builds, non-root users, healthchecks) |
| Orchestration | Kubernetes (Deployments, StatefulSet, HPA, Ingress, CronJob) |
| Packaging | Helm chart + Kustomize overlays (dev/staging/production) |
| CI/CD | GitHub Actions (test → scan → build → push → deploy) |
| IaC | Terraform (VPC, EKS, RDS, S3) |
| Config Mgmt | Ansible (for non-k8s VM deployments) |
| Monitoring | Prometheus + Grafana |
| Logging | Loki + Promtail |
| Security | Trivy (image/dependency scan), Semgrep (SAST) |

## Quickstart (local)

```bash
cp backend/.env.example backend/.env
docker compose up --build
```

- Frontend: http://localhost:3000
- Backend API docs: http://localhost:8000/docs
- Prometheus: http://localhost:9090
- Grafana: http://localhost:3001 (admin/admin)

Register a user, log in, and start adding tasks.

## Deploying to Kubernetes

```bash
# via kustomize
kubectl apply -k k8s/overlays/dev

# via Helm
helm upgrade --install taskmanager ./helm/taskmanager -f ./helm/taskmanager/values-dev.yaml
```

## Provisioning cloud infra (Terraform)

```bash
cd terraform/environments/dev
terraform init
terraform plan -var="db_password=$(openssl rand -hex 16)"
terraform apply
```

## CI/CD Pipeline

- **CI** (`.github/workflows/ci.yml`): runs on every PR — backend pytest suite against real
  Postgres+Redis service containers, frontend lint/build, Trivy filesystem scan, Semgrep SAST.
- **CD** (`.github/workflows/cd.yml`): on push to `main` — builds & scans Docker images
  (fails on CRITICAL CVEs), pushes to GHCR, deploys to staging automatically, deploys to
  production on git tag `v*` behind a manual approval gate, with automatic Helm rollback on failure.

## Deployment strategy

Rolling updates by default (`maxUnavailable: 0` = zero downtime). For blue-green or canary,
swap traffic weights at the Ingress/service-mesh layer — see `docs/deployment-strategies.md`.

## Docs

- [Architecture](docs/architecture.md)
- [Troubleshooting Guide](docs/troubleshooting.md)
- [Disaster Recovery](docs/disaster-recovery.md)
- [Deployment Strategies](docs/deployment-strategies.md)

## Environments

| Env | Replicas (backend) | Autoscale | Log level |
|---|---|---|---|
| dev | 1 | off | DEBUG |
| staging | 2 | off | INFO |
| production | 4 (HPA 4-20) | on | WARNING |
