# Phase 4 - Ceph CSI (RBD) for Kubernetes

- ceph-csi-rbd Helm chart 3.18.1, StorageClass ceph-rbd (default)
- One pool + one Ceph user per cluster: k8s-nonprod, k8s-prod
- Key lives only in a K8s Secret (created with kubectl, not in Git)
- Tested: PVC Bound, data survives pod delete, PVC delete removes RBD image

## Problems and fixes
1. CSI pods CrashLoop: "CPU does not support x86-64-v3"
   -> VM cpu type x86-64-v2-AES -> x86-64-v3 (Terraform module)
2. Disk attach timed out, kernel log: mon session lost every ~60s
   -> asymmetric routing (VM -> router -> Ceph, Ceph -> VM direct)
   -> static /32 routes via the Proxmox hosts (playbooks/ceph-routes.yml)
3. New pools got size 3 (mons still use old default until restart)
   -> set size 2 / min_size 1 by hand for each new pool
