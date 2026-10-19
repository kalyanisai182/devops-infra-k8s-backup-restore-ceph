#!/usr/bin/env bash
# etcd snapshot + PKI -> s3://k8s-etcd/<env>/   Usage: etcd-backup.sh nonprod|prod
set -euo pipefail
ENV=${1:?usage: $0 nonprod|prod}
case $ENV in nonprod) MASTER=10.30.5.43 ;; prod) MASTER=10.30.5.46 ;; *) exit 1 ;; esac
KC=/root/.kube/ceph-$ENV.conf; POD=etcd-ceph-$ENV-master
TS=$(date -u +%Y%m%dT%H%M%SZ); DIR=/root/etcd-backups/$ENV; mkdir -p "$DIR"
CERTS="--endpoints=https://127.0.0.1:2379 --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/server.crt --key=/etc/kubernetes/pki/etcd/server.key"
kubectl --kubeconfig $KC -n kube-system exec $POD -- etcdctl $CERTS snapshot save /var/lib/etcd/snap-$TS.db
kubectl --kubeconfig $KC -n kube-system exec $POD -- etcdutl snapshot status /var/lib/etcd/snap-$TS.db -w table
ssh ubuntu@$MASTER "sudo cat /var/lib/etcd/snap-$TS.db" > "$DIR/etcd-$ENV-$TS.db"
ssh ubuntu@$MASTER "sudo rm -f /var/lib/etcd/snap-$TS.db"
ssh ubuntu@$MASTER "sudo tar czf - -C /etc/kubernetes pki" > "$DIR/pki-$ENV-$TS.tgz"
source /root/ceph-s3/creds.env
docker run --rm --network host -v "$DIR:$DIR" -e AWS_ACCESS_KEY_ID=$ETCD_KEY -e AWS_SECRET_ACCESS_KEY=$ETCD_SECRET -e AWS_DEFAULT_REGION=us-east-1 \
  amazon/aws-cli --endpoint-url http://10.30.5.20:7480 s3 cp "$DIR/" "s3://k8s-etcd/$ENV/" --recursive --exclude "*" --include "*$TS*"
find "$DIR" -type f -mtime +7 -delete
echo "etcd backup $ENV $TS OK"
