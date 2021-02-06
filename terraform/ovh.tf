provider "ovh" {
  endpoint = "ovh-ca"
  application_key = data.sops_file.ovh-secrets.data["application_key"]
  application_secret = data.sops_file.ovh-secrets.data["application_secret"]
  consumer_key = data.sops_file.ovh-secrets.data["consumer_key"]
}

data "ovh_vps" "keanu_ovh" {
  service_name = "vps-1d0d9e77.vps.ovh.ca"
}
