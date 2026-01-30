data "cloudflare_zone" "root" {
  filter = {
    name = var.root_domain
  }
}


resource "cloudflare_dns_record" "a1" {
  zone_id = data.cloudflare_zone.root.id
  name    = var.root_domain
  proxied = false

  content = "ip-address"
  type    = "A"
  ttl     = 60 # seconds
}
