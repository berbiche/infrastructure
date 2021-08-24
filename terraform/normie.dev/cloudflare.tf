resource "cloudflare_zone" "normie_dev" {
  zone = "normie.dev"
  plan = "free"
  type = "full"
}

locals {
  ipv4_addresses = toset([for s in data.ovh_vps.keanu_ovh.ips : s if !can(cidrnetmask("${s}/128"))])
  ipv6_addresses = toset([for s in data.ovh_vps.keanu_ovh.ips : s if can(cidrnetmask("${s}/128"))])
}

# resource "ovh_ip_reverse" "normie_dev_ipv4" {
#   for_each = local.ipv4_addresses
#   ip = "${each.value}/32"
#   ip_reverse = each.value
#   reverse = "normie.dev."
# }

# resource "ovh_ip_reverse" "normie_dev_ipv6" {
#   for_each = local.ipv6_addresses
#   ip = "${each.value}/128"
#   ip_reverse = each.value
#   reverse = "normie.dev."
# }

resource "ovh_ip_reverse" "mail_normie_dev_ipv4" {
  for_each = local.ipv4_addresses
  ip = "${each.value}/32"
  ip_reverse = each.value
  reverse = "mail.normie.dev."
}

resource "ovh_ip_reverse" "mail_normie_dev_ipv6" {
  for_each = local.ipv6_addresses
  ip = "${each.value}/128"
  ip_reverse = each.value
  reverse = "mail.normie.dev."
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

resource "cloudflare_record" "sshfp" {
  zone_id = cloudflare_zone.normie_dev.id

  for_each = {
    # "algorithm type fingeprint"
    0: {algorithm = 1, type = 1, fingerprint = "cf1c4f9d33ae03e8461779f98a8715d686870125"},
    1: {algorithm = 1, type = 2, fingerprint = "a5cd4cd55ac00b357408b2ccdd8b95d2b04e9d5c1c01e40f5f35fff28d5be27a"},
    2: {algorithm = 4, type = 1, fingerprint = "144affbdd168f91d2ecd8f4c7616fc0ac7723969"},
    3: {algorithm = 4, type = 2, fingerprint = "5c65db83a95de8b27a5f0a2fffa941c6dd61619ef4fbac18c52408d145a301e2"},
  }

  name = "@"
  type = "SSHFP"
  proxied = false

  data = {
    algorithm = each.value.algorithm
    fingerprint = each.value.fingerprint
    type = each.value.type
  }
}
