# Troubleshooting Guide

## Pod stuck in `CrashLoopBackOff`
```bash
kubectl logs <pod> -n taskmanager --previous
kubectl describe pod <pod> -n taskmanager
```
Common causes: bad `DATABASE_URL` in secret, DB not ready yet (check `readyz`), missing env var.

## Pod stuck in `Pending`
```bash
kubectl describe pod <pod> -n taskmanager
```
Usually insufficient CPU/memory on nodes, or PVC can't bind (check StorageClass exists).

## `/readyz` returning 503
Means DB or Redis check failed. Exec into the pod and test connectivity:
```bash
kubectl exec -it <backend-pod> -n taskmanager -- python -c "import socket; socket.create_connection(('postgres', 5432), timeout=3)"
```
Check the Postgres StatefulSet is `Running` and `Ready`, and the Service DNS name resolves.

## High latency / High Error Rate alerts firing
1. Check Grafana "API Overview" dashboard for which endpoint is slow.
2. `kubectl top pods -n taskmanager` — check if pods are CPU/memory throttled.
3. Check HPA is actually scaling: `kubectl get hpa -n taskmanager`.
4. Check Postgres connection pool isn't exhausted (`pool_size=10` in `database.py` — bump if needed).

## CI pipeline failing on Trivy scan
The CD pipeline fails the build on CRITICAL CVEs by design. Check the scan output artifact,
upgrade the affected base image or dependency, and re-push.

## Helm upgrade stuck / rollback needed
```bash
helm history taskmanager -n taskmanager-prod
helm rollback taskmanager <REVISION> -n taskmanager-prod
```

## Rolling update not picking up new image
Kubernetes won't redeploy on `:latest` tag alone if the manifest is unchanged. Always deploy
with an explicit tag (the CI/CD pipeline uses `${{ github.sha }}`) to force a new rollout.
