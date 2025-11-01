# ===================================
# LOAD BALANCER OUTPUTS
# ===================================
output "load_balancer_arn" {
  description = "ARN of the load balancer"
  value       = var.create_load_balancer ? aws_lb.main[0].arn : null
}

output "load_balancer_dns_name" {
  description = "DNS name of the load balancer"
  value       = var.create_load_balancer ? aws_lb.main[0].dns_name : null
}

output "load_balancer_zone_id" {
  description = "Zone ID of the load balancer"
  value       = var.create_load_balancer ? aws_lb.main[0].zone_id : null
}

output "load_balancer_hosted_zone_id" {
  description = "Hosted zone ID of the load balancer"
  value       = var.create_load_balancer ? aws_lb.main[0].zone_id : null
}

# ===================================
# TARGET GROUP OUTPUTS
# ===================================
output "target_group_arns" {
  description = "Map of target group ARNs"
  value       = { for k, v in aws_lb_target_group.this : k => v.arn }
}

output "target_group_names" {
  description = "Map of target group names"
  value       = { for k, v in aws_lb_target_group.this : k => v.name }
}

# ===================================
# LISTENER OUTPUTS
# ===================================
output "listener_arns" {
  description = "Map of listener ARNs"
  value       = { for k, v in aws_lb_listener.this : k => v.arn }
}

output "listener_rule_arns" {
  description = "Map of listener rule ARNs"
  value       = { for k, v in aws_lb_listener_rule.this : k => v.arn }
}

# ===================================
# LAUNCH TEMPLATE OUTPUTS
# ===================================
output "launch_template_ids" {
  description = "Map of launch template IDs"
  value       = { for k, v in aws_launch_template.this : k => v.id }
}

output "launch_template_arns" {
  description = "Map of launch template ARNs"
  value       = { for k, v in aws_launch_template.this : k => v.arn }
}

output "launch_template_latest_versions" {
  description = "Map of launch template latest versions"
  value       = { for k, v in aws_launch_template.this : k => v.latest_version }
}

# ===================================
# AUTO SCALING GROUP OUTPUTS
# ===================================
output "auto_scaling_group_names" {
  description = "Map of Auto Scaling Group names"
  value       = { for k, v in aws_autoscaling_group.this : k => v.name }
}

output "auto_scaling_group_arns" {
  description = "Map of Auto Scaling Group ARNs"
  value       = { for k, v in aws_autoscaling_group.this : k => v.arn }
}

output "auto_scaling_group_availability_zones" {
  description = "Map of Auto Scaling Group availability zones"
  value       = { for k, v in aws_autoscaling_group.this : k => v.availability_zones }
}

output "auto_scaling_group_min_sizes" {
  description = "Map of Auto Scaling Group minimum sizes"
  value       = { for k, v in aws_autoscaling_group.this : k => v.min_size }
}

output "auto_scaling_group_max_sizes" {
  description = "Map of Auto Scaling Group maximum sizes"
  value       = { for k, v in aws_autoscaling_group.this : k => v.max_size }
}

output "auto_scaling_group_desired_capacities" {
  description = "Map of Auto Scaling Group desired capacities"
  value       = { for k, v in aws_autoscaling_group.this : k => v.desired_capacity }
}

# ===================================
# SCALING POLICY OUTPUTS
# ===================================
output "scaling_policy_arns" {
  description = "Map of scaling policy ARNs"
  value       = { for k, v in aws_autoscaling_policy.this : k => v.arn }
}

output "scaling_policy_names" {
  description = "Map of scaling policy names"
  value       = { for k, v in aws_autoscaling_policy.this : k => v.name }
}

# ===================================
# CLOUDWATCH ALARM OUTPUTS
# ===================================
output "cloudwatch_alarm_arns" {
  description = "Map of CloudWatch alarm ARNs"
  value       = { for k, v in aws_cloudwatch_metric_alarm.this : k => v.arn }
}

output "cloudwatch_alarm_names" {
  description = "Map of CloudWatch alarm names"
  value       = { for k, v in aws_cloudwatch_metric_alarm.this : k => v.alarm_name }
}

# ===================================
# LEGACY OUTPUTS (for backward compatibility)
# ===================================
output "web_target_group_arn" {
  description = "ARN of the web target group (legacy - use target_group_arns instead)"
  value       = contains(keys(aws_lb_target_group.this), "web") ? aws_lb_target_group.this["web"].arn : null
}

output "app_target_group_arn" {
  description = "ARN of the app target group (legacy - use target_group_arns instead)"
  value       = contains(keys(aws_lb_target_group.this), "app") ? aws_lb_target_group.this["app"].arn : null
}

output "web_launch_template_id" {
  description = "ID of the web launch template (legacy - use launch_template_ids instead)"
  value       = contains(keys(aws_launch_template.this), "web") ? aws_launch_template.this["web"].id : null
}

output "app_launch_template_id" {
  description = "ID of the app launch template (legacy - use launch_template_ids instead)"
  value       = contains(keys(aws_launch_template.this), "app") ? aws_launch_template.this["app"].id : null
}

output "web_asg_arn" {
  description = "ARN of the web Auto Scaling Group (legacy - use auto_scaling_group_arns instead)"
  value       = contains(keys(aws_autoscaling_group.this), "web") ? aws_autoscaling_group.this["web"].arn : null
}

output "app_asg_arn" {
  description = "ARN of the app Auto Scaling Group (legacy - use auto_scaling_group_arns instead)"
  value       = contains(keys(aws_autoscaling_group.this), "app") ? aws_autoscaling_group.this["app"].arn : null
}