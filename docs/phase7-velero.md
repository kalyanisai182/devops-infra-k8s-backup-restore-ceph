# Phase 7.2 - Velero to Ceph RGW

- Velero 1.18, AWS plugin v1.14.0, CSI snapshots + data mover (Kopia)
- Buckets: velero-nonprod, velero-prod (RGW user velero)
- Schedule nightly-all: 02:00 (nonprod), 02:30 (prod), TTL 7 days
- Test: deleted namespace + PVC + Ceph image, restored in 43s, data intact

## Problem and fix
- DataUpload failed: "Access Denied" writing kopia.blobcfg
- RGW debug log: STREAMING-AWS4-HMAC-SHA256-PAYLOAD and
  "Signature rejected: 'content-type' supplied but not in CanonicalHeaders"
- minio-go (used by Kopia) streams unsigned headers over plain HTTP
- Fix: HTTPS on RGW (port 7443, own CA), BSL s3Url https + caCert

# Phase 7.3-7.5
- CNPG 1.30.1 + Barman Cloud plugin 0.15.1: WAL archiving + nightly base backup -> s3://pg-backups/nonprod (HTTPS)
- PITR drill: DROP TABLE, restored new cluster to the second before -> all rows back
- etcd: scripts/etcd-backup.sh (snapshot + PKI) -> s3://k8s-etcd/<env>, cron 03:00/03:15, 7-day local retention
- scripts/backup-check.sh daily 08:00: etcd/velero freshness (<26h), CNPG archiving + last backup
