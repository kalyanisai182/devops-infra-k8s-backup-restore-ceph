#!/usr/bin/env bash
# Checks etcd, Velero and CNPG backups are fresh (<26h) and healthy. Exit 1 on any FAIL.
source /root/ceph-s3/creds.env
FAIL=0; NOW=$(date +%s); MAX=93600
ok(){ echo "OK    $*"; }; bad(){ echo "FAIL  $*"; FAIL=1; }
s3(){ docker run --rm --network host -e AWS_ACCESS_KEY_ID=$1 -e AWS_SECRET_ACCESS_KEY=$2 -e AWS_DEFAULT_REGION=us-east-1 amazon/aws-cli --endpoint-url http://10.30.5.20:7480 "${@:3}"; }
for ENV in nonprod prod; do
  KC=/root/.kube/ceph-$ENV.conf
  L=$(s3 $ETCD_KEY $ETCD_SECRET s3 ls s3://k8s-etcd/$ENV/ | grep '\.db$' | sort | tail -1 | awk '{print $1" "$2}')
  if [ -n "$L" ] && [ $((NOW-$(date -d "$L UTC" +%s))) -lt $MAX ]; then ok "etcd   $ENV  last: $L UTC"; else bad "etcd   $ENV  last: ${L:-none}"; fi
  V=$(kubectl --kubeconfig $KC -n velero get backups.velero.io -l velero.io/schedule-name=nightly-all --sort-by=.metadata.creationTimestamp \
      -o jsonpath='{range .items[*]}{.status.phase} {.status.completionTimestamp}{"\n"}{end}' | tail -1)
  P=${V%% *}; T=${V#* }
  if [ "$P" = Completed ] && [ $((NOW-$(date -d "$T" +%s))) -lt $MAX ]; then ok "velero $ENV  $V"; else bad "velero $ENV  ${V:-none}"; fi
done
KC=/root/.kube/ceph-nonprod.conf
A=$(kubectl --kubeconfig $KC -n model-registry get cluster registry-db -o jsonpath='{.status.conditions[?(@.type=="ContinuousArchiving")].status}')
[ "$A" = True ] && ok "cnpg   WAL archiving" || bad "cnpg   WAL archiving: ${A:-unknown}"
B=$(kubectl --kubeconfig $KC -n model-registry get backups.postgresql.cnpg.io --sort-by=.metadata.creationTimestamp -o jsonpath='{range .items[*]}{.status.phase}{"\n"}{end}' | tail -1)
[ "$B" = completed ] && ok "cnpg   last base backup" || bad "cnpg   last base backup: ${B:-none}"
[ $FAIL = 0 ] && echo "ALL BACKUPS HEALTHY" || echo "SOME BACKUPS NEED ATTENTION"
exit $FAIL
