# Production Auto Scaling Module

A production-ready Terraform module for AWS Auto Scaling infrastructure with Application Load Balancers. Designed for high availability, flexibility, and enterprise-grade deployments.

## Production Features

- **High Availability**: Multi-AZ deployment with automatic failover
- **Flexible Load Balancer**: Internal/external ALB with multiple security groups
- **Zero-Downtime Deployments**: Instance refresh and rolling updates
- **Advanced Scaling**: Target tracking, step scaling, and warm pools
- **Enterprise Monitoring**: CloudWatch integration with custom metrics
- **Security Hardened**: IMDSv2, encrypted EBS, and security best practices

## Quick Start

### Basic Web Application
```hcl
module "web_app" {
  source = "./modules/auto-scaling"

  name_prefix        = "prod-web"
  vpc_id            = var.vpc_id
  public_subnet_ids = var.public_subnet_ids
  private_subnet_ids = var.private_subnet_ids

  # External ALB
  load_balancer_internal = false
  load_balancer_security_groups = [var.alb_security_group_id]

  # Target groups
  target_groups = {
    web = {
      name              = "web-tg"
      port              = 80
      protocol          = "HTTP"
      health_check_path = "/health"
    }
  }

  # HTTPS listener
  listeners = {
    https = {
      port                = 443
      protocol            = "HTTPS"
      certificate_arn     = var.ssl_certificate_arn
      default_action_type = "forward"
      default_target_group = "web"
    }
  }

  # Launch template
  launch_templates = {
    web = {
      name_prefix        = "web-"
      image_id          = data.aws_ami.amazon_linux.id
      instance_type     = "t3.medium"
      security_group_ids = [var.web_security_group_id]
      user_data_file    = "${path.module}/user_data/web_user_data.sh"
      user_data_vars    = {
        environment = var.environment
        project     = var.project_name
      }
    }
  }

  # Auto scaling group
  auto_scaling_groups = {
    web = {
      name                = "web-asg"
      launch_template_key = "web"
      target_group_keys   = ["web"]
      min_size           = 2
      max_size           = 10
      desired_capacity   = 3
      subnet_ids         = var.public_subnet_ids
      health_check_type  = "ELB"
    }
  }

  # Target tracking scaling
  scaling_policies = {
    cpu_tracking = {
      name       = "cpu-tracking"
      asg_key    = "web"
      policy_type = "TargetTrackingScaling"
      target_tracking_configuration = {
        target_value = 60.0
        predefined_metric_specification = {
          predefined_metric_type = "ASGAverageCPUUtilization"
        }
      }
    }
  }

  tags = var.common_tags
}
```

### Multi-Tier Application
```hcl
module "multi_tier_app" {
  source = "./modules/auto-scaling"

  name_prefix = "prod-app"
  vpc_id     = var.vpc_id
  public_subnet_ids = var.public_subnet_ids
  private_subnet_ids = var.private_subnet_ids

  # External ALB with WAF
  load_balancer_internal = false
  load_balancer_security_groups = [
    var.alb_security_group_id,
    var.waf_security_group_id
  ]

  # Multiple target groups
  target_groups = {
    web = {
      name              = "web-tg"
      port              = 80
      protocol          = "HTTP"
      health_check_path = "/health"
    }
    api = {
      name              = "api-tg"
      port              = 8080
      protocol          = "HTTP"
      health_check_path = "/actuator/health"
    }
  }

  # HTTPS with API routing
  listeners = {
    https = {
      port                = 443
      protocol            = "HTTPS"
      certificate_arn     = var.ssl_certificate_arn
      default_action_type = "forward"
      default_target_group = "web"
    }
  }

  listener_rules = {
    api_routing = {
      listener_key     = "https"
      priority         = 100
      action_type      = "forward"
      target_group_key = "api"
      conditions = [
        {
          field  = "path-pattern"
          values = ["/api/*"]
        }
      ]
    }
  }

  # Launch templates for both tiers
  launch_templates = {
    web = {
      name_prefix        = "web-"
      image_id          = data.aws_ami.amazon_linux.id
      instance_type     = "t3.medium"
      security_group_ids = [var.web_security_group_id]
      user_data_file    = "${path.module}/user_data/web_user_data.sh"
    }
    api = {
      name_prefix        = "api-"
      image_id          = data.aws_ami.amazon_linux.id
      instance_type     = "t3.large"
      security_group_ids = [var.app_security_group_id]
      user_data_file    = "${path.module}/user_data/app_user_data.sh"
    }
  }

  # Auto scaling groups
  auto_scaling_groups = {
    web = {
      name                = "web-asg"
      launch_template_key = "web"
      target_group_keys   = ["web"]
      min_size           = 2
      max_size           = 20
      desired_capacity   = 4
      subnet_ids         = var.public_subnet_ids
      health_check_type  = "ELB"
    }
    api = {
      name                = "api-asg"
      launch_template_key = "api"
      target_group_keys   = ["api"]
      min_size           = 2
      max_size           = 15
      desired_capacity   = 3
      subnet_ids         = var.private_subnet_ids
      health_check_type  = "ELB"
    }
  }

  tags = var.common_tags
}
```

## Key Configuration Options

### Load Balancer Control
- `load_balancer_internal`: true for internal ALB, false for internet-facing
- `load_balancer_security_groups`: List of security group IDs
- `load_balancer_subnets`: Custom subnet selection (optional)

### High Availability Features
- **Instance Refresh**: Zero-downtime deployments
- **Warm Pools**: Pre-warmed instances for faster scaling
- **Multi-AZ**: Automatic distribution across availability zones
- **Health Checks**: ELB and custom application health checks

### Security Features
- **IMDSv2**: Enforced metadata service v2
- **EBS Encryption**: Encrypted root volumes by default
- **Security Groups**: Granular network access control
- **IAM Roles**: Instance profiles for secure AWS API access

### Monitoring & Scaling
- **Target Tracking**: Automatic scaling based on metrics
- **CloudWatch Integration**: Custom metrics and alarms
- **SNS Notifications**: Auto scaling event notifications

## Production Best Practices

1. **Always use HTTPS** in production with valid SSL certificates
2. **Enable deletion protection** for load balancers
3. **Use target tracking scaling** for better performance
4. **Enable instance refresh** for zero-downtime deployments
5. **Monitor with CloudWatch** and set up proper alarms
6. **Use encrypted EBS volumes** for data security
7. **Implement proper health checks** for application monitoring

## Directory Structure
```
modules/auto-scaling/
├── main.tf           # Core infrastructure resources
├── variables.tf      # Input variables and validation
├── outputs.tf        # Module outputs
├── README.md         # This documentation
└── user_data/        # Instance initialization scripts
    ├── web_user_data.sh   # Web tier setup
    └── app_user_data.sh   # Application tier setup
```

## Requirements
- Terraform >= 1.0
- AWS Provider >= 5.0
- VPC with public and private subnets
- Security groups properly configured
- SSL certificates for HTTPS (recommended)