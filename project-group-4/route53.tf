resource "aws_route53_record" "www" {
  zone_id = "Z09937073QW4Q0S20WQQ4"
  name = "www.devspro.net"
  type = "A"
  alias {
    name                   = aws_lb.web.dns_name
    zone_id                = aws_lb.web.zone_id
    evaluate_target_health = true
  }

}