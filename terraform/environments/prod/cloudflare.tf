data "cloudflare_zone" "main" {
  filter {
    name = "kacpermalachowski.pl"
  }
}

resource "cloudflare_dns_record" "this" {
  type = "A"
  zone_id = data.cloudflare_zone.main.id
  name = "@"
  proxied = true
  ttl = 1
}

resource "cloudflare_dns_record" "wildcard" {
  type = "A"
  zone_id = data.cloudflare_zone.main.id
  name = "*"
  proxied = true
  ttl = 1
}