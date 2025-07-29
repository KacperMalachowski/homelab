data "cloudflare_zone" "main" {
  filter = {
    name = var.public_domain
  }
}

resource "cloudflare_dns_record" "this" {
  type    = "A"
  zone_id = data.cloudflare_zone.main.zone_id
  name    = "@"
  proxied = true
  ttl     = 1
  content = module.masters.hcloud_servers[0].ipv4_address
}

resource "cloudflare_dns_record" "wildcard" {
  type    = "A"
  zone_id = data.cloudflare_zone.main.zone_id
  name    = "*"
  proxied = true
  ttl     = 1
  content = module.masters.hcloud_servers[0].ipv4_address
}