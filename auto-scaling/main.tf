# ===================================
# APPLICATION LOAD BALANCER
# ===================================
resource "aws_lb" "main" {
  count = var.create_load_balancer ? 1 : 0
  
  name               = "${var.name_prefix}-alb"
  internal           = var.load_balancer_internal
  load_balancer_type = var.load_balancer_type
  security_groups    = var.load_balancer_security_groups
  
  # Use specified subnets or default based on internal/external
  subnets = length(var.load_balancer_subnets) > 0 ? var.load_balancer_subnets : (
    var.load_balancer_internal ? var.private_subnet_ids : var.public_subnet_ids
  )

  enable_deletion_protection = var.enable_deletion_protection
  idle_timeout              = var.load_balancer_idle_timeout

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-alb"
    Type = var.load_balancer_internal ? "Internal" : "External"
  })
}

# ===================================
# TARGET GROUPS
# ===================================
resource "aws_lb_target_group" "this" {
  for_each = var.target_groups

  name        = "${var.name_prefix}-${each.value.name}"
  port        = each.value.port
  protocol    = each.value.protocol
  vpc_id      = var.vpc_id
  target_type = each.value.target_type

  health_check {
    enabled             = each.value.health_check_enabled
    healthy_threshold   = each.value.healthy_threshold
    unhealthy_threshold = each.value.unhealthy_threshold
    timeout             = each.value.health_check_timeout
    interval            = each.value.health_check_interval
    path                = each.value.health_check_path
    matcher             = each.value.health_check_matcher
    port                = each.value.health_check_port
    protocol            = each.value.health_check_protocol
  }

  dynamic "stickiness" {
    for_each = each.value.stickiness_enabled ? [1] : []
    content {
      enabled         = true
      type            = each.value.stickiness_type
      cookie_duration = each.value.stickiness_duration
    }
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-${each.value.name}"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# ===================================
# LISTENERS
# ===================================
resource "aws_lb_listener" "this" {
  for_each = var.create_load_balancer ? var.listeners : {}

  load_balancer_arn = aws_lb.main[0].arn
  port              = each.value.port
  protocol          = each.value.protocol
  ssl_policy        = each.value.protocol == "HTTPS" ? each.value.ssl_policy : null
  certificate_arn   = each.value.protocol == "HTTPS" ? each.value.certificate_arn : null

  default_action {
    type = each.value.default_action_type

    dynamic "target_group_arn" {
      for_each = each.value.default_action_type == "forward" ? [each.value.default_target_group] : []
      content {
        target_group_arn = aws_lb_target_group.this[target_group_arn.value].arn
      }
    }

    dynamic "fixed_response" {
      for_each = each.value.default_action_type == "fixed-response" ? [each.value.fixed_response] : []
      content {
        content_type = fixed_response.value.content_type
        message_body = fixed_response.value.message_body
        status_code  = fixed_response.value.status_code
      }
    }

    dynamic "redirect" {
      for_each = each.value.default_action_type == "redirect" ? [each.value.redirect] : []
      content {
        host        = redirect.value.host
        path        = redirect.value.path
        port        = redirect.value.port
        protocol    = redirect.value.protocol
        query       = redirect.value.query
        status_code = redirect.value.status_code
      }
    }
  }

  tags = var.tags
}

# ===================================
# LISTENER RULES
# ===================================
resource "aws_lb_listener_rule" "this" {
  for_each = var.create_load_balancer ? var.listener_rules : {}

  listener_arn = aws_lb_listener.this[each.value.listener_key].arn
  priority     = each.value.priority

  action {
    type = each.value.action_type

    dynamic "target_group_arn" {
      for_each = each.value.action_type == "forward" ? [each.value.target_group_key] : []
      content {
        target_group_arn = aws_lb_target_group.this[target_group_arn.value].arn
      }
    }

    dynamic "fixed_response" {
      for_each = each.value.action_type == "fixed-response" ? [each.value.fixed_response] : []
      content {
        content_type = fixed_response.value.content_type
        message_body = fixed_response.value.message_body
        status_code  = fixed_response.value.status_code
      }
    }

    dynamic "redirect" {
      for_each = each.value.action_type == "redirect" ? [each.value.redirect] : []
      content {
        host        = redirect.value.host
        path        = redirect.value.path
        port        = redirect.value.port
        protocol    = redirect.value.protocol
        query       = redirect.value.query
        status_code = redirect.value.status_code
      }
    }
  }

  dynamic "condition" {
    for_each = each.value.conditions
    content {
      dynamic "path_pattern" {
        for_each = condition.value.field == "path-pattern" ? [condition.value] : []
        content {
          values = path_pattern.value.values
        }
      }

      dynamic "host_header" {
        for_each = condition.value.field == "host-header" ? [condition.value] : []
        content {
          values = host_header.value.values
        }
      }

      dynamic "http_header" {
        for_each = condition.value.field == "http-header" ? [condition.value] : []
        content {
          http_header_name = http_header.value.values[0]
          values          = slice(http_header.value.values, 1, length(http_header.value.values))
        }
      }

      dynamic "query_string" {
        for_each = condition.value.field == "query-string" ? [condition.value] : []
        content {
          key   = query_string.value.values[0]
          value = length(query_string.value.values) > 1 ? query_string.value.values[1] : ""
        }
      }
    }
  }

  tags = var.tags
}

# ===================================
# LAUNCH TEMPLATES
# ===================================
resource "aws_launch_template" "this" {
  for_each = var.launch_templates

  name_prefix   = "${var.name_prefix}-${each.value.name_prefix}"
  image_id      = each.value.image_id
  instance_type = each.value.instance_type
  key_name      = each.value.key_name != "" ? each.value.key_name : null

  vpc_security_group_ids = each.value.security_group_ids

  # User data handling - support both file and direct base64
  user_data = each.value.user_data_base64 != "" ? each.value.user_data_base64 : (
    each.value.user_data_file != "" ? base64encode(templatefile(each.value.user_data_file, each.value.user_data_vars)) : null
  )

  # IAM instance profile
  dynamic "iam_instance_profile" {
    for_each = each.value.iam_instance_profile != "" ? [each.value.iam_instance_profile] : []
    content {
      name = iam_instance_profile.value
    }
  }

  # Monitoring
  monitoring {
    enabled = each.value.monitoring_enabled
  }

  # EBS optimization
  ebs_optimized = each.value.ebs_optimized

  # Block device mappings
  dynamic "block_device_mappings" {
    for_each = each.value.block_device_mappings
    content {
      device_name = block_device_mappings.value.device_name
      ebs {
        volume_size           = block_device_mappings.value.ebs.volume_size
        volume_type           = block_device_mappings.value.ebs.volume_type
        iops                  = block_device_mappings.value.ebs.iops
        throughput            = block_device_mappings.value.ebs.throughput
        encrypted             = block_device_mappings.value.ebs.encrypted
        delete_on_termination = block_device_mappings.value.ebs.delete_on_termination
      }
    }
  }

  # Network interfaces
  dynamic "network_interfaces" {
    for_each = each.value.network_interfaces
    content {
      device_index                = network_interfaces.value.device_index
      associate_public_ip_address = network_interfaces.value.associate_public_ip_address
      delete_on_termination       = network_interfaces.value.delete_on_termination
      security_groups             = network_interfaces.value.security_groups
    }
  }

  # Placement
  dynamic "placement" {
    for_each = each.value.placement != null ? [each.value.placement] : []
    content {
      availability_zone = placement.value.availability_zone
      tenancy          = placement.value.tenancy
    }
  }

  # Metadata options
  metadata_options {
    http_endpoint               = each.value.metadata_options.http_endpoint
    http_tokens                 = each.value.metadata_options.http_tokens
    http_put_response_hop_limit = each.value.metadata_options.http_put_response_hop_limit
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge(var.tags, {
      Name = "${var.name_prefix}-${each.key}-instance"
    })
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ===================================
# AUTO SCALING GROUPS
# ===================================
resource "aws_autoscaling_group" "this" {
  for_each = var.auto_scaling_groups

  name                = "${var.name_prefix}-${each.value.name}"
  vpc_zone_identifier = each.value.subnet_ids
  
  # Target group ARNs
  target_group_arns = [
    for tg_key in each.value.target_group_keys : aws_lb_target_group.this[tg_key].arn
  ]

  health_check_type         = each.value.health_check_type
  health_check_grace_period = each.value.health_check_grace_period

  min_size         = each.value.min_size
  max_size         = each.value.max_size
  desired_capacity = each.value.desired_capacity

  default_cooldown     = each.value.default_cooldown
  termination_policies = each.value.termination_policies
  enabled_metrics      = each.value.enabled_metrics

  launch_template {
    id      = aws_launch_template.this[each.value.launch_template_key].id
    version = "$Latest"
  }

  # Instance refresh configuration
  dynamic "instance_refresh" {
    for_each = each.value.instance_refresh != null ? [each.value.instance_refresh] : []
    content {
      strategy = instance_refresh.value.strategy
      
      dynamic "preferences" {
        for_each = instance_refresh.value.preferences != null ? [instance_refresh.value.preferences] : []
        content {
          instance_warmup        = preferences.value.instance_warmup
          min_healthy_percentage = preferences.value.min_healthy_percentage
        }
      }
      
      triggers = instance_refresh.value.triggers
    }
  }

  # Warm pool configuration
  dynamic "warm_pool" {
    for_each = each.value.warm_pool != null ? [each.value.warm_pool] : []
    content {
      pool_state                  = warm_pool.value.pool_state
      min_size                   = warm_pool.value.min_size
      max_group_prepared_capacity = warm_pool.value.max_group_prepared_capacity
    }
  }

  tag {
    key                 = "Name"
    value               = "${var.name_prefix}-${each.value.name}"
    propagate_at_launch = false
  }

  dynamic "tag" {
    for_each = var.tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ===================================
# AUTO SCALING POLICIES
# ===================================
resource "aws_autoscaling_policy" "this" {
  for_each = var.scaling_policies

  name                   = "${var.name_prefix}-${each.value.name}"
  autoscaling_group_name = aws_autoscaling_group.this[each.value.asg_key].name
  adjustment_type        = each.value.adjustment_type
  policy_type            = each.value.policy_type
  cooldown               = each.value.cooldown
  scaling_adjustment     = each.value.scaling_adjustment

  # Target tracking scaling policy
  dynamic "target_tracking_configuration" {
    for_each = each.value.target_tracking_configuration != null ? [each.value.target_tracking_configuration] : []
    content {
      target_value     = target_tracking_configuration.value.target_value
      disable_scale_in = target_tracking_configuration.value.disable_scale_in

      dynamic "predefined_metric_specification" {
        for_each = target_tracking_configuration.value.predefined_metric_specification != null ? [target_tracking_configuration.value.predefined_metric_specification] : []
        content {
          predefined_metric_type = predefined_metric_specification.value.predefined_metric_type
          resource_label        = predefined_metric_specification.value.resource_label
        }
      }

      dynamic "customized_metric_specification" {
        for_each = target_tracking_configuration.value.customized_metric_specification != null ? [target_tracking_configuration.value.customized_metric_specification] : []
        content {
          metric_name = customized_metric_specification.value.metric_name
          namespace   = customized_metric_specification.value.namespace
          statistic   = customized_metric_specification.value.statistic
          unit        = customized_metric_specification.value.unit
          
          dynamic "metric_dimension" {
            for_each = customized_metric_specification.value.dimensions
            content {
              name  = metric_dimension.key
              value = metric_dimension.value
            }
          }
        }
      }
    }
  }

  # Step scaling policy
  dynamic "step_adjustment" {
    for_each = each.value.step_adjustments
    content {
      scaling_adjustment          = step_adjustment.value.scaling_adjustment
      metric_interval_lower_bound = step_adjustment.value.metric_interval_lower_bound
      metric_interval_upper_bound = step_adjustment.value.metric_interval_upper_bound
    }
  }
}

# ===================================
# CLOUDWATCH ALARMS
# ===================================
resource "aws_cloudwatch_metric_alarm" "this" {
  for_each = var.cloudwatch_alarms

  alarm_name          = "${var.name_prefix}-${each.value.name}"
  comparison_operator = each.value.comparison_operator
  evaluation_periods  = each.value.evaluation_periods
  metric_name         = each.value.metric_name
  namespace           = each.value.namespace
  period              = each.value.period
  statistic           = each.value.statistic
  threshold           = each.value.threshold
  alarm_description   = each.value.alarm_description
  treat_missing_data  = each.value.treat_missing_data

  alarm_actions = each.value.alarm_actions
  ok_actions    = each.value.ok_actions

  dimensions = each.value.dimensions

  tags = var.tags
}

# Composite alarms for complex conditions
resource "aws_cloudwatch_composite_alarm" "this" {
  for_each = {
    for k, v in var.cloudwatch_alarms : k => v
    if v.alarm_rule != ""
  }

  alarm_name        = "${var.name_prefix}-${each.value.name}-composite"
  alarm_description = each.value.alarm_description
  alarm_rule        = each.value.alarm_rule

  alarm_actions = each.value.alarm_actions
  ok_actions    = each.value.ok_actions

  tags = var.tags
}

# ===================================
# AUTO SCALING NOTIFICATIONS
# ===================================
resource "aws_autoscaling_notification" "this" {
  count = var.autoscaling_notifications.enabled ? 1 : 0

  group_names = [
    for asg_key in var.autoscaling_notifications.asg_keys : aws_autoscaling_group.this[asg_key].name
  ]

  notifications = var.autoscaling_notifications.notifications
  topic_arn     = var.autoscaling_notifications.topic_arn
}