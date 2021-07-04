provider "proxmox" {
  pm_api_url = data.sops_file.proxmox-secrets.data["api_url"]
  pm_user = data.sops_file.proxmox-secrets.data["user"]
  pm_password = data.sops_file.proxmox-secrets.data["password"]
}
