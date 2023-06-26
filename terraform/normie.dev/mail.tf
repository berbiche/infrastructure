resource "cloudflare_record" "mail" {
  zone_id = cloudflare_zone.normie_dev.id

  for_each = local.ipv4_addresses

  name    = "mail"
  type    = "A"
  value   = each.value
  proxied = false
}
resource "cloudflare_record" "mail_ipv6" {
  zone_id = cloudflare_zone.normie_dev.id

  for_each = local.ipv6_addresses

  name    = "mail"
  type    = "AAAA"
  value   = each.value
  proxied = false
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

resource "cloudflare_record" "cname-mta-sts" {
  zone_id = cloudflare_zone.normie_dev.id

  name  = "mta-sts"
  type  = "CNAME"
  value = cloudflare_record.MX.value

  proxied = false
}

// Autodiscovery settings: https://nixos-mailserver.readthedocs.io/en/latest/autodiscovery.html
resource "cloudflare_record" "_submissions_tcp" {
  zone_id = cloudflare_zone.normie_dev.id
  name    = "_submissions._tcp"
  type    = "SRV"

  data {
    service  = "_submissions"
    proto    = "_tcp"
    name     = "terraform-srv.normie.dev"
    priority = 5
    weight   = 0
    port     = 465
    target   = cloudflare_record.MX.value
  }
}

resource "cloudflare_record" "_imaps_tcp" {
  zone_id = cloudflare_zone.normie_dev.id
  name    = "_imaps._tcp"
  type    = "SRV"

  data {
    service  = "_imaps"
    proto    = "_tcp"
    name     = "terraform-srv.normie.dev"
    priority = 5
    weight   = 0
    port     = 993
    target   = cloudflare_record.MX.value
  }
}

resource "cloudflare_record" "mta_sts" {
  zone_id = cloudflare_zone.normie_dev.id
  name    = "_mta-sts"
  type    = "TXT"
  value   = "v=STSv1; id=20230618T010101;"
  proxied = false
}

resource "cloudflare_record" "smtp_tls" {
  zone_id = cloudflare_zone.normie_dev.id
  name    = "_smtp._tls"
  type    = "TXT"
  value   = "v=TLSRPTv1; rua=mailto:postmaster@normie.dev"
  proxied = false
}

