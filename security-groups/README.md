# Security Groups Module

Creates security groups for multi-tier applications with proper layered security.

## Features

- ALB security group (internet-facing)
- Web tier security group
- Application tier security group
- Database security group
- EKS cluster and node security groups
- Least privilege access patterns

## Usage

```hcl
module "security_groups" {
  source = "github.com/cloudcrafted31/terraform-modules-aws//security-groups?ref=v1.0.0"

  name_prefix = "my-app"
  vpc_id      = module.vpc.vpc_id
  vpc_cidr    = "10.0.0.0/16"
  
  tags = {
    Environment = "prod"
    Project     = "my-app"
  }
}
```

## Security Model

- **ALB SG**: Allows HTTP/HTTPS from internet
- **Web SG**: Allows traffic from ALB only
- **App SG**: Allows traffic from Web tier only
- **DB SG**: Allows database traffic from App tier only
- **EKS SGs**: Proper cluster and node communication

## Outputs

| Name | Description |
|------|-------------|
| alb_security_group_id | ID of the ALB security group |
| web_security_group_id | ID of the web tier security group |
| app_security_group_id | ID of the app tier security group |
| database_security_group_id | ID of the database security group |
| eks_cluster_security_group_id | ID of the EKS cluster security group |
| eks_nodes_security_group_id | ID of the EKS nodes security group |
