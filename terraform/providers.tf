provider "cloudflare" {
  email = data.sops_file.cloudflare-secrets.data["email"]
  api_token = data.sops_file.cloudflare-secrets.data["api_token"]
}

provider "ovh" {
  endpoint = "ovh-ca"
  application_key = data.sops_file.ovh-secrets.data["application_key"]
  application_secret = data.sops_file.ovh-secrets.data["application_secret"]
  consumer_key = data.sops_file.ovh-secrets.data["consumer_key"]
}

provider "proxmox" {
  pm_api_url = data.sops_file.proxmox-secrets.data["api_url"]
  pm_user = data.sops_file.proxmox-secrets.data["user"]
  pm_password = data.sops_file.proxmox-secrets.data["password"]
}
