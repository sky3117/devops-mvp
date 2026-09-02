# Deployment Strategies

## Rolling deployment (default, used here)

`k8s/base/backend-deployment.yaml` sets `maxUnavailable: 0, maxSurge: 1` — new pods come up
and pass readiness checks before old pods are terminated. Zero downtime, simplest to operate.

```bash
kubectl rollout status deployment/backend -n taskmanager
kubectl rollout undo deployment/backend -n taskmanager   # rollback
```

## Blue-Green

Run two full environments (`blue` = current, `green` = new). Deploy to `green`, run smoke
tests, then flip the Ingress/Service selector to point at `green` all at once. Instant
rollback = flip back. Costs 2x infra during the switch window.

## Canary

Route a small % of traffic to the new version before full rollout. With plain Ingress-nginx,
approximate this using two Deployments + `nginx.ingress.kubernetes.io/canary-weight`
annotation on a second Ingress resource. For fine-grained traffic splitting, use a service
mesh (Istio/Linkerd) or Argo Rollouts.

## Zero-downtime checklist

- [ ] Readiness probe actually validates DB/cache connectivity (`/readyz` does this here)
- [ ] `maxUnavailable: 0` on the Deployment
- [ ] Database migrations are backward-compatible with the previous app version during rollout
- [ ] HPA min replicas ≥ 2 (never scale to a single point of failure)
