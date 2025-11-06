# Monitoring Module

Creates CloudWatch monitoring and SNS notifications for infrastructure.

## Features

- SNS topics for notifications
- Email subscriptions
- CloudWatch log groups
- Basic CloudWatch alarms
- Configurable retention and alerting

## Usage

```hcl
module "monitoring" {
  source = "github.com/cloudcrafted31/terraform-modules-aws//monitoring?ref=v1.0.0"

  name_prefix = "my-app"
  
  sns_email_endpoints = [
    "alerts@company.com",
    "devops@company.com"
  ]
  
  tags = {
    Environment = "prod"
    Project     = "my-app"
  }
}
```

## Notifications

The module creates SNS topics that can be used by:
- Auto Scaling Groups
- CloudWatch Alarms
- Lambda functions
- Other AWS services

## Outputs

| Name | Description |
|------|-------------|
| sns_topic_arn | ARN of the SNS topic |
| sns_topic_name | Name of the SNS topic |
| cloudwatch_log_group_name | Name of the CloudWatch log group |
