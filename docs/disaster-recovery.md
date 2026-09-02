# Disaster Recovery

## Backup strategy

- **Database**: `k8s/base/backup-cronjob.yaml` runs `pg_dump` daily at 2 AM, uploads to
  `s3://taskmanager-backups/postgres/`, retains 7 days locally and 30 days in S3
  (see `terraform/modules/s3` lifecycle rule).
- **Terraform state**: stored in S3 with versioning + DynamoDB locking — recoverable to any
  prior state.

## Recovery procedure (database)

1. Identify the latest good backup:
   ```bash
   aws s3 ls s3://taskmanager-backups/postgres/ --recursive | sort | tail -5
   ```
2. Download it:
   ```bash
   aws s3 cp s3://taskmanager-backups/postgres/taskdb-<timestamp>.dump ./restore.dump
   ```
3. Restore into a fresh/target Postgres instance:
   ```bash
   pg_restore -h <host> -U taskuser -d taskdb -c ./restore.dump
   ```
4. Verify with `/readyz` on the backend and spot-check task data via the API.

## Recovery testing

Run a full restore into a scratch database at least quarterly to confirm backups are valid —
an untested backup is not a backup. Track this as a recurring calendar task, not ad hoc.

## Full cluster loss

1. Re-provision infra: `terraform apply` in the affected environment (state is safe in S3).
2. Re-deploy application: `helm upgrade --install taskmanager ...` (see README).
3. Restore database from latest S3 backup (above).
4. Re-point DNS/Ingress if the load balancer IP changed.

## RTO / RPO targets (adjust to your actual SLAs)

| Environment | RPO | RTO |
|---|---|---|
| Production | 24h (daily backup) | ~1h |
| Staging | Best-effort | ~2h |
