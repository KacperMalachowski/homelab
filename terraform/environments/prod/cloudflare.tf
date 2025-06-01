data "cloudflare_zone" "main" {
  filter = {
    name = "kacpermalachowski.pl"
  }
}

resource "cloudflare_dns_record" "this" {
  type = "A"
  zone_id = data.cloudflare_zone.main.zone_id
  name = "@"
  proxied = true
  ttl = 1
  content = hcloud_load_balancer.this.ipv4
}

resource "cloudflare_dns_record" "kube" {
  type = "A"
  zone_id = data.cloudflare_zone.main.zone_id
  name = "kube"
  proxied = true
  ttl = 1
  content = hcloud_load_balancer.this.ipv4
}

resource "cloudflare_dns_record" "wildcard" {
  type = "A"
  zone_id = data.cloudflare_zone.main.zone_id
  name = "*"
  proxied = true
  ttl = 1
  content = hcloud_load_balancer.this.ipv4
}