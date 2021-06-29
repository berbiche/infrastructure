locals {
  ipv4_prefix = "10.97.42"
}

module "proxmox" {
  source = "./proxmox"

  host                 = "proxmox-zion"
  ssh_host             = "proxmox-zion.node.tq.rs"
  ssh_private_key_path = pathexpand("~/.ssh/keanu.ovh")
  node_count           = 3
  thinpool             = "proxthin"
  ipv4_addresses       = [for s in range(4): "${local.ipv4_prefix}.${50 + s}/24"]
  ipv4_gateway         = "${local.ipv4_prefix}.1"
  nameservers          = [ "${local.ipv4_prefix}.1" ]

  secrets = {
    hashed_password = data.sops_file.proxmox-secrets.data["k8s-node-nicolas-hashed-password"]
  }
}

# module "proxmox" {
#   source = "./proxmox"

#   host                 = "proxmox-morpheus"
#   ssh_host             = "proxmox-morpheus.node.tq.rs"
#   ssh_private_key_path = file("~/.ssh/keanu.ovh")
#   node_count           = 3
#   thinpool             = "proxthin"
#   ipv4_addresses       = [for s in range(4): "${local.ipv4_prefix}.${60 + s}/24"]
#   ipv4_gateway         = "${local.ipv4_prefix}.1"
#   nameservers          = [ "${local.ipv4_prefix}.6", "${local.ipv4_prefix}.1" ]

#   secrets = {
#     hashed_password = data.sops_file.proxmox-secrets.data["k8s-node-nicolas-hashed-password"]
#   }
# }
