resource "cloudflare_zone" "normie_dev" {
  zone = "normie.dev"
  plan = "free"
  type = "full"
}

locals {
  ipv4_addresses = toset([for s in data.ovh_vps.keanu_ovh.ips : s if !can(cidrnetmask("${s}/128"))])
  ipv6_addresses = toset([for s in data.ovh_vps.keanu_ovh.ips : s if can(cidrnetmask("${s}/128"))])
}

resource "ovh_ip_reverse" "normie_dev_ipv4" {
  for_each = local.ipv4_addresses
  ip = "${each.value}/32"
  ip_reverse = each.value
  reverse = "normie.dev."
}

resource "ovh_ip_reverse" "normie_dev_ipv6" {
  for_each = local.ipv6_addresses
  ip = "${each.value}/128"
  ip_reverse = each.value
  reverse = "normie.dev."
}

resource "cloudflare_record" "root_ipv4" {
  zone_id  = cloudflare_zone.normie_dev.id

  for_each = local.ipv4_addresses

  name     = "@"
  type     = "A"
  value    = each.value
  proxied  = false
}

resource "cloudflare_record" "root_ipv6" {
  zone_id  = cloudflare_zone.normie_dev.id

  for_each = local.ipv6_addresses

  name     = "@"
  type     = "AAAA"
  value    = each.value
  proxied  = false
}

resource "cloudflare_record" "www" {
  zone_id = cloudflare_zone.normie_dev.id

  name    = "www"
  type    = "CNAME"
  value   = "normie.dev"
  proxied = false
}

resource "cloudflare_record" "MX" {
  zone_id = cloudflare_zone.normie_dev.id

  name    = "mail"
  type    = "MX"
  value   = "normie.dev"
  proxied = false
}

resource "cloudflare_record" "cloud" {
  zone_id = cloudflare_zone.normie_dev.id

  name  = "cloud"
  type  = "CNAME"
  value = "normie.dev"

  proxied = false
}

resource "cloudflare_record" "grafana" {
  zone_id = cloudflare_zone.normie_dev.id

  name  = "grafana"
  type  = "CNAME"
  value = cloudflare_record.cloud.hostname

  proxied = false
}

resource "cloudflare_record" "google_site_verification" {
  zone_id = cloudflare_zone.normie_dev.id

  name  = "@"
  type  = "TXT"
  value = "google-site-verification=O9UeI6JHgKtRHua9kj5jFbSe5naeP5e_fg-FDAlD1zM"

  ttl     = 1800
  proxied = false
}
