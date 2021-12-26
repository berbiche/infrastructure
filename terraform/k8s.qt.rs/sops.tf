provider "sops" {}

data "sops_file" "ovh-secrets" {
  source_file = "../../secrets/ovh.yaml"
}

data "sops_file" "cloudflare-secrets" {
  source_file = "../../secrets/cloudflare.yaml"
}

data "sops_file" "backblaze-secrets" {
  source_file = "../../secrets/backblaze.yaml"
}

data "sops_file" "proxmox-secrets" {
  source_file = "../../secrets/proxmox.yaml"
}
