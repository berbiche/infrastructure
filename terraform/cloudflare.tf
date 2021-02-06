provider "cloudflare" {
  email = data.sops_file.cloudflare-secrets.data["email"]
  api_token = data.sops_file.cloudflare-secrets.data["api_token"]
}

resource "cloudflare_zone" "normie_dev" {
  zone = "normie.dev"
  plan = "free"
  type = "full"
}

locals {
  ipv4_addresses = toset([for s in data.ovh_vps.keanu_ovh.ips : s if !can(cidrnetmask("${s}/128"))])
  ipv6_addresses = toset([for s in data.ovh_vps.keanu_ovh.ips : s if can(cidrnetmask("${s}/128"))])
}

resource "cloudflare_record" "normie_dev_ipv4" {
  zone_id  = cloudflare_zone.normie_dev.id

  for_each = local.ipv4_addresses

  type     = "A"
  value    = each.value
  name     = "normie.dev."
  proxied  = false
}

resource "cloudflare_record" "normie_dev_ipv6" {
  zone_id  = cloudflare_zone.normie_dev.id

  for_each = local.ipv6_addresses

  type     = "AAAA"
  value    = each.value
  name     = "normie.dev."
  proxied  = false
}

# resource "cloudflare_record" "" {

# }
