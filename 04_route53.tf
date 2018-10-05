#####################################
# Route53 Settings
#####################################
resource "aws_route53_zone" "this" {
  name = "${local.domain}"
}

resource "aws_route53_record" "this" {
  zone_id = "${aws_route53_zone.this.zone_id}"
  name    = "${local.domain}"
  type    = "A"

  alias {
    name                   = "${aws_cloudfront_distribution.this.domain_name}"
    zone_id                = "${aws_cloudfront_distribution.this.hosted_zone_id}"
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "ns" {
  zone_id = "${local.apex_domain_hosted_zone_id}"
  name    = "${local.domain}"
  type    = "NS"
  ttl     = "300"

  records = [
    "${aws_route53_zone.this.name_servers.0}",
    "${aws_route53_zone.this.name_servers.1}",
    "${aws_route53_zone.this.name_servers.2}",
    "${aws_route53_zone.this.name_servers.3}",
  ]
}

resource "aws_route53_record" "acm" {
  count   = "${length(aws_acm_certificate.cloudfront.domain_validation_options)}"
  zone_id = "${aws_route53_zone.this.zone_id}"
  name    = "${lookup(aws_acm_certificate.cloudfront.domain_validation_options[count.index],"resource_record_name")}"
  type    = "${lookup(aws_acm_certificate.cloudfront.domain_validation_options[count.index],"resource_record_type")}"
  ttl     = "300"
  records = ["${lookup(aws_acm_certificate.cloudfront.domain_validation_options[count.index],"resource_record_value")}"]
}
