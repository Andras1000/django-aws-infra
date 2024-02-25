resource "aws_route53_zone" "prod" {
  name = var.prod_base_domain
}

resource "aws_acm_certificate" "prod_backend" {
  domain_name = var.prod_backend_domain
  validation_method = "DNS"
}

resource "aws_route53domains_registered_domain" "prod_domain" {
  domain_name = var.prod_base_domain
  dynamic "name_server" {
    for_each = aws_route53_zone.prod.name_servers
    content {
      name = name_server.value
    }
  }
}

resource "aws_route53_record" "prod_backend_certificate_validation" {
  for_each = {
    for dvo in aws_acm_certificate.prod_backend.domain_validation_options : dvo.domain_name => {
      name  = dvo.resource_record_name
      type  = dvo.resource_record_type
      value = dvo.resource_record_value
    }
  }

  allow_overwrite = true
  name = each.value.name
  records = [each.value.value]
  ttl = 60
  type = each.value.type
  zone_id = aws_route53_zone.prod.zone_id
}

resource "aws_acm_certificate_validation" "prod_backend" {
  certificate_arn = aws_acm_certificate.prod_backend.arn
  validation_record_fqdns = [for record in aws_route53_record.prod_backend_certificate_validation : record.fqdn]
}

resource "aws_route53_record" "prod_backend_a" {
  zone_id = aws_route53_zone.prod.zone_id
  name = var.prod_backend_domain
  type = "A"

  alias {
    name = aws_lb.prod.dns_name
    zone_id = aws_lb.prod.zone_id
    evaluate_target_health = true
  }
}
