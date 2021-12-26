provider "proxmox" {
  pm_api_url = data.sops_file.proxmox-secrets.data["api_url"]
  pm_api_token_id = data.sops_file.proxmox-secrets.data["api_token"]
  pm_api_token_secret = data.sops_file.proxmox-secrets.data["api_secret"]
  pm_tls_insecure = true
}
