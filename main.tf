# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

resource "aws_security_group" "alb" {
  count       = var.create ? 1 : 0
  name        = local.module_prefix
  tags        = local.tags
  description = "Controls access to the ALB (HTTP/HTTPS)"

  vpc_id = var.vpc_id
}

resource "aws_security_group_rule" "egress" {
  count = var.create ? 1 : 0

  type              = "egress"
  from_port         = "0"
  to_port           = "0"
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = concat(aws_security_group.alb.*.id, [""])[0]
}

resource "aws_security_group_rule" "alb_http_ingress" {
  count = var.create ? var.http_redirect_enabled ? 1 : length(var.target_groups) : 0

  type              = "ingress"
  from_port         = var.http_redirect_enabled ? 80 : var.target_groups[count.index].port
  to_port           = var.http_redirect_enabled ? 80 : var.target_groups[count.index].port
  protocol          = "tcp"
  cidr_blocks       = var.http_ingress_cidr_blocks
  prefix_list_ids   = var.http_ingress_prefix_list_ids
  security_group_id = concat(aws_security_group.alb.*.id, [""])[0]
}

resource "aws_security_group_rule" "alb_https_ingress" {
  count = var.create ? length(var.https_ports) : 0

  type              = "ingress"
  from_port         = var.https_ports[count.index]
  to_port           = var.https_ports[count.index]
  protocol          = "tcp"
  cidr_blocks       = var.https_ingress_cidr_blocks
  prefix_list_ids   = var.https_ingress_prefix_list_ids
  security_group_id = concat(aws_security_group.alb.*.id, [""])[0]
}

resource "aws_lb" "alb" {
  count = var.create ? 1 : 0
  name  = local.module_prefix
  tags  = local.tags

  load_balancer_type = "application"
  internal           = var.internal
  security_groups = compact(
    concat(var.security_group_ids, [concat(aws_security_group.alb.*.id, [""])[0]]),
  )
  subnets                          = var.subnet_ids
  enable_cross_zone_load_balancing = var.cross_zone_load_balancing_enabled
  enable_http2                     = var.http2_enabled
  idle_timeout                     = var.idle_timeout
  ip_address_type                  = var.ip_address_type
  enable_deletion_protection       = var.deletion_protection_enabled
  access_logs {
    bucket  = join("", aws_s3_bucket.default.*.id)
    prefix  = var.access_logs_prefix
    enabled = var.access_logs_enabled
  }
}

resource "aws_lb_target_group" "alb" {
  count = var.create ? length(var.target_groups) : 0
  name  = lower(join("-", [local.module_prefix, var.target_groups[count.index].protocol, var.target_groups[count.index].port]))
  tags  = local.tags

  vpc_id               = var.vpc_id
  port                 = var.target_groups[count.index].port
  protocol             = var.target_groups[count.index].protocol
  target_type          = var.target_groups[count.index].target_type
  deregistration_delay = var.target_groups[count.index].deregistration_delay
  health_check {
    enabled             = var.target_groups[count.index].health_check.enabled
    path                = var.target_groups[count.index].health_check.path
    protocol            = var.target_groups[count.index].protocol
    timeout             = var.target_groups[count.index].health_check.timeout
    healthy_threshold   = var.target_groups[count.index].health_check.healthy_threshold
    unhealthy_threshold = var.target_groups[count.index].health_check.unhealthy_threshold
    interval            = var.target_groups[count.index].health_check.interval
    matcher             = var.target_groups[count.index].health_check.matcher
  }

  dynamic "stickiness" {
    for_each = lookup(var.target_groups[count.index], "stickiness", null) == null ? [] : [var.target_groups[count.index].stickiness]
    content {
      type            = stickiness.value["type"]
      cookie_duration = stickiness.value["cookie_duration"]
      enabled         = stickiness.value["enabled"]
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_listener" "http" {
  count = var.create ? var.http_redirect_enabled ? 1 : length(var.target_groups) : 0

  load_balancer_arn = concat(aws_lb.alb.*.arn, [""])[0]
  port              = var.http_redirect_enabled ? 80 : var.target_groups[count.index].port
  protocol          = "HTTP"
  default_action {
    type             = var.http_redirect_enabled ? "redirect" : "forward"
    target_group_arn = var.http_redirect_enabled ? "" : aws_lb_target_group.alb[count.index].arn
    dynamic "redirect" {
      for_each = var.http_redirect_enabled ? [1] : []
      content {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  }
}

resource "aws_lb_listener" "https" {
  count             = var.create && var.https_enabled ? length(var.https_ports) : 0
  load_balancer_arn = concat(aws_lb.alb.*.arn, [""])[0]

  port            = var.https_ports[count.index]
  protocol        = "HTTPS"
  ssl_policy      = var.https_ssl_policy
  certificate_arn = var.certificate_arn

  default_action {
    target_group_arn = aws_lb_target_group.alb[count.index].arn
    type             = "forward"
  }
}

resource "aws_route53_record" "alb" {
  count = var.create && var.dns_zone_id != "" && var.dns_zone_name != "" ? 1 : 0

  zone_id         = var.dns_zone_id
  name            = coalesce(var.domain_name, join(".", [var.name, var.dns_zone_name]))
  type            = "CNAME"
  ttl             = 30
  records         = [concat(aws_lb.alb.*.dns_name, [""])[0]]
  allow_overwrite = true
}

# ----------------------------------------------------------------------------------------------------------------------
# ACCESS LOGS MODULES/RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

resource "aws_s3_bucket" "default" {
  count         = var.create ? 1 : 0
  bucket        = "${local.module_prefix}-access-logs"
  acl           = var.acl
  force_destroy = var.force_destroy
  policy        = <<policy
{
  "Id": "Policy",
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:PutObject"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:s3:::${local.module_prefix}-access-logs/AWSLogs/*",
      "Principal": {
        "AWS": [
          "arn:aws:iam::127311923021:root"
        ]
      }
    }
  ]
}
policy
  versioning {
    enabled = var.versioning_enabled
  }

  lifecycle_rule {
    id                                     = local.module_prefix
    enabled                                = var.lifecycle_rule_enabled
    prefix                                 = var.lifecycle_prefix
    tags                                   = var.lifecycle_tags
    abort_incomplete_multipart_upload_days = var.abort_incomplete_multipart_upload_days

    noncurrent_version_expiration {
      days = var.noncurrent_version_expiration_days
    }


    transition {
      days          = var.standard_transition_days
      storage_class = "STANDARD_IA"
    }

    expiration {
      days = var.expiration_days
    }

  }

  # https://docs.aws.amazon.com/AmazonS3/latest/dev/bucket-encryption.html
  # https://www.terraform.io/docs/providers/aws/r/s3_bucket.html#enable-default-server-side-encryption
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm     = var.sse_algorithm
        kms_master_key_id = var.kms_master_key_arn
      }
    }
  }

  tags = local.tags
}

# Refer to the terraform documentation on s3_bucket_public_access_block at
# https://www.terraform.io/docs/providers/aws/r/s3_bucket_public_access_block.html
# for the nuances of the blocking options
resource "aws_s3_bucket_public_access_block" "default" {
  count  = var.create ? 1 : 0
  bucket = join("", aws_s3_bucket.default.*.id)

  block_public_acls       = var.block_public_acls
  block_public_policy     = var.block_public_policy
  ignore_public_acls      = var.ignore_public_acls
  restrict_public_buckets = var.restrict_public_buckets
}
