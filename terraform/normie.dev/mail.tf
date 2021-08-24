resource "cloudflare_record" "mail" {
  zone_id = cloudflare_zone.normie_dev.id

  for_each = local.ipv4_addresses

  name    = "mail"
  type    = "A"
  value   = each.value
  proxied = false
}
resource "cloudflare_record" "mail_ipv6" {
  zone_id  = cloudflare_zone.normie_dev.id

  for_each = local.ipv6_addresses

  name     = "mail"
  type     = "AAAA"
  value    = each.value
  proxied  = false
}

resource "cloudflare_record" "MX" {
  zone_id = cloudflare_zone.normie_dev.id

  name     = "@"
  type     = "MX"
  value    = "mail.normie.dev"
  priority = 10
  proxied  = false
}

resource "cloudflare_record" "SPF" {
  zone_id = cloudflare_zone.normie_dev.id

  name    = "@"
  type    = "TXT"
  value   = "v=spf1 a:${cloudflare_record.MX.value} -all"
  ttl     = 10800
  proxied = false
}

resource "cloudflare_record" "SPF_2" {
  zone_id = cloudflare_zone.normie_dev.id

  name    = "@"
  type    = "SPF"
  value   = "v=spf1 a:${cloudflare_record.MX.value} -all"
  ttl     = 10800
  proxied = false
}

resource "cloudflare_record" "DKIM" {
  zone_id = cloudflare_zone.normie_dev.id

  name    = "mail._domainkey"
  type    = "TXT"
  value   = "v=DKIM1; k=rsa; s=email; p=${chomp(file("${path.module}/dkim.txt"))}"
  ttl     = 10800
  proxied = false
}

resource "cloudflare_record" "DMARC" {
  zone_id = cloudflare_zone.normie_dev.id

  name    = "_dmarc"
  type    = "TXT"
  value   = "v=DMARC1; p=quarantine; rua=mailto:postmaster@normie.dev; ruf=mailto:postmaster@normie.dev"
  ttl     = 10800
  proxied = false
}
