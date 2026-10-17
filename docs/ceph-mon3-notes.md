# Third Ceph monitor (ceph-mon3, 10.30.5.49) - parked

Goal: 3rd monitor so Ceph survives losing one Proxmox host.

Findings:
- Ceph public network is 10.30.4.0/24, VMs are on 10.30.5.0/24 (routed).
- Clients on 10.30.5.x work fine (ceph -s from the VM worked).
- New mon: TCP, banner and cephx auth succeed, then existing mons
  close the connection after client_ident (loop every 0.2s).

Fixes along the way:
- mkfs as root left /var/log/ceph owned by root -> chown ceph:ceph.
- Two RGW pools had size 3 -> set to size 2 / min_size 1.

Next try (rolling restart): ms_bind_before_connect = true for mons,
or put the VM on VLAN 304 (10.30.4.x).
- Lead: asymmetric routing (fixed in Phase 4 with static routes) may be the real cause. Retry mon3.
