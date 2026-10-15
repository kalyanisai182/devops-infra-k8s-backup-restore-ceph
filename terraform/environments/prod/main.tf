locals {
  node_name      = "R2S09"
  template_vm_id = 9000
  template_node  = "R2S16"
  datastore_id   = "ceph-rbd-storage"
  gateway        = "10.30.5.251"
  dns_servers    = ["10.30.4.252", "1.1.1.1"]
  ssh_keys       = [trimspace(file(pathexpand("~/.ssh/id_ed25519.pub")))]

  vms = {
    ceph-prod-master     = { vm_id = 205, ip = "10.30.5.46", cores = 2, memory_mb = 4096, disk_gb = 30 }
    ceph-prod-worker1    = { vm_id = 206, ip = "10.30.5.47", cores = 2, memory_mb = 8192, disk_gb = 40 }
    ceph-prod-worker2    = { vm_id = 207, ip = "10.30.5.48", cores = 2, memory_mb = 8192, disk_gb = 40 }
  }
}

module "vm" {
  source   = "../../modules/proxmox-vm"
  for_each = local.vms

  name      = each.key
  vm_id     = each.value.vm_id
  node_name = local.node_name
  tags      = ["ceph-project", "prod", strcontains(each.key, "master") ? "k8s-master" : "k8s-worker"]

  template_vm_id = local.template_vm_id
  template_node  = local.template_node

  cores        = each.value.cores
  memory_mb    = each.value.memory_mb
  disk_gb      = each.value.disk_gb
  datastore_id = local.datastore_id

  ip              = each.value.ip
  gateway         = local.gateway
  dns_servers     = local.dns_servers
  ssh_public_keys = local.ssh_keys
}

output "vms" {
  value = { for name, vm in module.vm : name => { vm_id = vm.vm_id, ip = vm.ip } }
}
