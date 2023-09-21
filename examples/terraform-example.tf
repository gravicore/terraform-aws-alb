module {
  source = "git::https://github.com/gravicore/terraform-aws-alb?ref=1.0.0"

  name            = "my-alb"
  vpc_id          = "vpc-12345678"
  subnet_ids      = ["subnet-12345678", "subnet-87654321"]
  certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/12345678-1234-1234-1234-123456789012"
  dns_zone_id     = "Z1234567890ABC"
  # Note: the R53 record can be made by explicitly passing in a domain name, or by passing in the dns_zone_name
  domain_name = "example.example.com"
  # dns_zone_name = "example.com"
  tags = {
    Owner       = "user"
    Environment = "dev"
  }
}
