# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------

output "alb_name" {
  description = "The ARN suffix of the ALB"
  value       = concat(aws_lb.alb.*.name, [""])[0]
}

output "alb_arn" {
  description = "The ARN of the ALB"
  value       = concat(aws_lb.alb.*.arn, [""])[0]
}

output "alb_arn_suffix" {
  description = "The ARN suffix of the ALB"
  value       = concat(aws_lb.alb.*.arn_suffix, [""])[0]
}

output "alb_dns_name" {
  description = "DNS name of ALB"
  value       = concat(aws_lb.alb.*.dns_name, [""])[0]
}

output "alb_zone_id" {
  description = "The ID of the zone which ALB is provisioned"
  value       = concat(aws_lb.alb.*.zone_id, [""])[0]
}

output "security_group_ids" {
  description = "The security group IDs of the ALB"
  value       = aws_security_group.alb.*.id
}

output "target_group_arns" {
  description = "The target group ARNs"
  value       = aws_lb_target_group.alb.*.arn
}

output "http_listener_arns" {
  description = "The ARNs of the HTTP listeners"
  value       = aws_lb_listener.http.*.arn
}

output "https_listener_arns" {
  description = "The ARNs of the HTTPS listeners"
  value       = aws_lb_listener.https.*.arn
}

output "listener_arns" {
  description = "A list of all the listener ARNs"
  value = compact(
    concat(aws_lb_listener.http.*.arn, aws_lb_listener.https.*.arn),
  )
}

output "route53_dns_name" {
  description = "DNS name of Route53"
  value       = length(aws_route53_record.alb) == 1 ? aws_route53_record.alb[0].name : ""
}

# ----------------------------------------------------------------------------------------------------------------------
# ACCESS LOGS OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------

output "access_log_bucket_domain_name" {
  value       = join("", aws_s3_bucket.default.*.bucket_domain_name)
  description = "FQDN of bucket"
}

output "access_log_bucket_id" {
  value       = join("", aws_s3_bucket.default.*.id)
  description = "Bucket Name (aka ID)"
}
