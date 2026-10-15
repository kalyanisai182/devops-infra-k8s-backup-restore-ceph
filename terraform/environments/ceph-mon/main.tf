locals {
  node_name      = "R2S16"
  template_vm_id = 9000
  template_node  = "R2S16"
  datastore_id   = "local-vms-r2s16"
  gateway        = "10.30.5.251"
  dns_servers    = ["10.30.4.252", "1.1.1.1"]
  ssh_keys       = [trimspace(file(pathexpand("~/.ssh/id_ed25519.pub")))]

  vms = {
    ceph-mon3 = { vm_id = 208, ip = "10.30.5.49", cores = 1, memory_mb = 2048, disk_gb = 16 }
  }
}

module "vm" {
  source   = "../../modules/proxmox-vm"
  for_each = local.vms

  name      = each.key
  vm_id     = each.value.vm_id
  node_name = local.node_name
  tags      = ["ceph-project", "ceph", "monitor"]

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
