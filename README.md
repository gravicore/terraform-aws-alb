![](https://media.licdn.com/dms/image/C4E0BAQF-zlJOBQR0bA/company-logo_200_200/0/1630601585844/gravicore_logo?e=2147483647&v=beta&t=n0Vlt1Svlsz8ivI05Uresp3-7DA7UDK3P-_TRw2PHgs)

# Gravicore Terraform AWS ALB
A Gravicore module for deploying an AWS ALB
Reach out to us through our website [gravicore.io](gravicore.io)

## A module for creating an AWS ALB (Application Load Balancer) using Terraform

A module enabling the deployment of [AWS Elastic Load Balancing (Application Load Balancer)](https://aws.amazon.com/elasticloadbalancing//) solutions. Best suited for HTTP/HTTPS traffic or microservice/container applications.

## Required Providers/Versions

### Terraform

| Name       | Version |
| :-------:  | :-----: |
|[terraform](https://developer.hashicorp.com/terraform) | >1.0.0  |

### Providers

| Name       | Version |
| :--------: | :-----: |
|[aws](https://registry.terraform.io/providers/hashicorp/aws/latest/docs) | >= 3.74.0 |

## Modules used

None

## Resources

### ALB

| Name | Type |
| :--- | :--: |
| aws_security_group.alb                    | resource |
| aws_security_group_rule.egress            | resource |
| aws_security_group_rule.alb_http_ingress  | resource |
| aws_security_group_rule.alb_https_ingress | resource |
| aws_lb.alb                                | resource |
| aws_lb_target_group.alb                   | resource |
| aws_lb_listener.http                      | resource |
| aws_lb_listener.https                     | resource |
| aws_route53_record.alb                    | resource |

### ACCESS LOGS

| Name | Type |
| :--- | :--: |
| aws_s3_bucket.default | resource |
| aws_s3_bucket_public_access_block.default | resource |

## Inputs

| Name | Description | Type | Default | Required |
| :--: | :---------- | :--: | :-----: | :------: |
| name                         | The name of the module/resource                                            | `string`         | N/A              | yes |
| create                       | Wether to actually implement the underlying resources                      | `bool`           | `true`           | no  |
| vpc_id                       | The ID of the VPC to create the ALB resources in                           | `string`         | N/A              | yes |
| subnet_ids                   | A list of subnet IDs to associate with the ALB resources                   | `list(string)`   | N/A              | yes |
| security_group_ids           | A list of additional security group IDs to allow access to ALB             | `list(string)`   | `[]`             | no  |
| internal                     | A flag to determine whether the ALB should be internal                     | `bool`           | `false`          | no  |
| http_redirect_enabled        | A flag to enable/disable HTTP listener                                     | `bool`           | `true`           | no  |
| http_ingress_cidr_blocks     | A List of CIDR blocks to allow in HTTP security group                      | `list(string)`   | `["10.0.0.0/8"]` | no  |
| http_ingress_prefix_list_ids | List of prefix list IDs for allowing access to HTTP ingress security group | `list(string)`   | `[]`             | no  |
| domain_name                  | The domain name for the route 53 record associated with the ALB            | `string`         | `""`             | no  |
*More inputs to be added*