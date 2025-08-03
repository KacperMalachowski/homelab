data "cloudflare_zone" "this" {
  filter = {
    name = var.public_domain
  }
}

resource "cloudflare_dns_record" "this" {
  type    = "A"
  zone_id = data.cloudflare_zone.this.id
  name    = var.public_domain
  proxied = true
  ttl     = 1
  content = module.kube_hetzner.ingress_public_ipv4
}

resource "cloudflare_dns_record" "wildcard" {
  type    = "A"
  zone_id = data.cloudflare_zone.this.id
  name    = "*"
  proxied = true
  ttl     = 1
  content = module.kube_hetzner.ingress_public_ipv4
}
