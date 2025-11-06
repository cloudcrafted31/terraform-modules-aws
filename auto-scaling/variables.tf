# ===================================
# CORE CONFIGURATION
# ===================================
variable "name_prefix" {
  description = "Name prefix for resources"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for ALB and public-facing resources"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for backend resources"
  type        = list(string)
}

variable "tags" {
  description = "A map of tags to assign to all resources"
  type        = map(string)
  default     = {}
}

# ===================================
# LOAD BALANCER CONFIGURATION
# ===================================
variable "create_load_balancer" {
  description = "Whether to create an Application Load Balancer"
  type        = bool
  default     = true
}

variable "load_balancer_type" {
  description = "Type of load balancer (application, network, gateway)"
  type        = string
  default     = "application"
  validation {
    condition     = contains(["application", "network", "gateway"], var.load_balancer_type)
    error_message = "Load balancer type must be application, network, or gateway."
  }
}

variable "load_balancer_internal" {
  description = "Whether the load balancer is internal (true) or internet-facing (false)"
  type        = bool
  default     = false
}

variable "load_balancer_security_groups" {
  description = "List of security group IDs to attach to the load balancer"
  type        = list(string)
  default     = []
}

variable "load_balancer_subnets" {
  description = "List of subnet IDs for the load balancer. If empty, uses public_subnet_ids for external or private_subnet_ids for internal"
  type        = list(string)
  default     = []
}

variable "enable_deletion_protection" {
  description = "Enable deletion protection for ALB"
  type        = bool
  default     = false
}

variable "load_balancer_idle_timeout" {
  description = "The time in seconds that the connection is allowed to be idle"
  type        = number
  default     = 60
}

# ===================================
# TARGET GROUP CONFIGURATION
# ===================================
variable "target_groups" {
  description = "Map of target group configurations"
  type = map(object({
    name                 = string
    port                 = number
    protocol             = string
    target_type          = optional(string, "instance")
    health_check_enabled = optional(bool, true)
    health_check_path    = optional(string, "/")
    health_check_port    = optional(string, "traffic-port")
    health_check_protocol = optional(string, "HTTP")
    health_check_matcher = optional(string, "200")
    health_check_interval = optional(number, 30)
    health_check_timeout = optional(number, 5)
    healthy_threshold    = optional(number, 2)
    unhealthy_threshold  = optional(number, 2)
    stickiness_enabled   = optional(bool, false)
    stickiness_type      = optional(string, "lb_cookie")
    stickiness_duration  = optional(number, 86400)
  }))
  default = {}
}

# ===================================
# LISTENER CONFIGURATION
# ===================================
variable "listeners" {
  description = "Map of listener configurations"
  type = map(object({
    port                = number
    protocol            = string
    ssl_policy          = optional(string, "ELBSecurityPolicy-TLS-1-2-2017-01")
    certificate_arn     = optional(string, "")
    default_action_type = string
    default_target_group = optional(string, "")
    fixed_response = optional(object({
      content_type = string
      message_body = optional(string, "")
      status_code  = string
    }), null)
    redirect = optional(object({
      host        = optional(string, "#{host}")
      path        = optional(string, "/#{path}")
      port        = optional(string, "#{port}")
      protocol    = optional(string, "#{protocol}")
      query       = optional(string, "#{query}")
      status_code = string
    }), null)
  }))
  default = {}
}

variable "listener_rules" {
  description = "Map of listener rule configurations"
  type = map(object({
    listener_key        = string
    priority           = number
    action_type        = string
    target_group_key   = optional(string, "")
    conditions = list(object({
      field  = string
      values = list(string)
    }))
    fixed_response = optional(object({
      content_type = string
      message_body = optional(string, "")
      status_code  = string
    }), null)
    redirect = optional(object({
      host        = optional(string, "#{host}")
      path        = optional(string, "/#{path}")
      port        = optional(string, "#{port}")
      protocol    = optional(string, "#{protocol}")
      query       = optional(string, "#{query}")
      status_code = string
    }), null)
  }))
  default = {}
}

# ===================================
# LAUNCH TEMPLATE CONFIGURATION
# ===================================
variable "launch_templates" {
  description = "Map of launch template configurations"
  type = map(object({
    name_prefix          = string
    image_id            = string
    instance_type       = string
    key_name            = optional(string, "")
    security_group_ids  = list(string)
    user_data_file      = optional(string, "")
    user_data_vars      = optional(map(string), {})
    user_data_base64    = optional(string, "")
    iam_instance_profile = optional(string, "")
    monitoring_enabled   = optional(bool, true)
    ebs_optimized       = optional(bool, false)
    
    block_device_mappings = optional(list(object({
      device_name = string
      ebs = object({
        volume_size           = number
        volume_type          = optional(string, "gp3")
        iops                 = optional(number, null)
        throughput           = optional(number, null)
        encrypted            = optional(bool, true)
        delete_on_termination = optional(bool, true)
      })
    })), [])
    
    network_interfaces = optional(list(object({
      device_index                = number
      associate_public_ip_address = optional(bool, false)
      delete_on_termination       = optional(bool, true)
      security_groups            = optional(list(string), [])
    })), [])
    
    placement = optional(object({
      availability_zone = optional(string, "")
      tenancy          = optional(string, "default")
    }), null)
    
    metadata_options = optional(object({
      http_endpoint = optional(string, "enabled")
      http_tokens   = optional(string, "required")
      http_put_response_hop_limit = optional(number, 1)
    }), {})
  }))
  default = {}
}

# ===================================
# AUTO SCALING GROUP CONFIGURATION
# ===================================
variable "auto_scaling_groups" {
  description = "Map of Auto Scaling Group configurations"
  type = map(object({
    name                = string
    launch_template_key = string
    target_group_keys   = optional(list(string), [])
    
    # Capacity settings
    min_size         = number
    max_size         = number
    desired_capacity = number
    
    # Subnet configuration
    subnet_ids = list(string)
    
    # Health check settings
    health_check_type         = optional(string, "EC2")
    health_check_grace_period = optional(number, 300)
    
    # Instance settings
    default_cooldown          = optional(number, 300)
    termination_policies      = optional(list(string), ["Default"])
    enabled_metrics          = optional(list(string), [])
    
    # Instance refresh settings
    instance_refresh = optional(object({
      strategy = string
      preferences = optional(object({
        instance_warmup        = optional(number, 300)
        min_healthy_percentage = optional(number, 90)
      }), {})
      triggers = optional(list(string), [])
    }), null)
    
    # Warm pool settings
    warm_pool = optional(object({
      pool_state                  = optional(string, "Stopped")
      min_size                   = optional(number, 0)
      max_group_prepared_capacity = optional(number, null)
    }), null)
  }))
  default = {}
}

# ===================================
# AUTO SCALING POLICIES
# ===================================
variable "scaling_policies" {
  description = "Map of Auto Scaling Policy configurations"
  type = map(object({
    name                   = string
    asg_key               = string
    adjustment_type       = optional(string, "ChangeInCapacity")
    policy_type           = optional(string, "SimpleScaling")
    cooldown              = optional(number, 300)
    scaling_adjustment    = optional(number, null)
    
    # Target tracking scaling policy
    target_tracking_configuration = optional(object({
      target_value = number
      predefined_metric_specification = optional(object({
        predefined_metric_type = string
        resource_label        = optional(string, "")
      }), null)
      customized_metric_specification = optional(object({
        metric_name = string
        namespace   = string
        statistic   = string
        unit        = optional(string, "")
        dimensions = optional(map(string), {})
      }), null)
      disable_scale_in = optional(bool, false)
    }), null)
    
    # Step scaling policy
    step_adjustments = optional(list(object({
      scaling_adjustment          = number
      metric_interval_lower_bound = optional(number, null)
      metric_interval_upper_bound = optional(number, null)
    })), [])
  }))
  default = {}
}

# ===================================
# CLOUDWATCH ALARMS
# ===================================
variable "cloudwatch_alarms" {
  description = "Map of CloudWatch Alarm configurations"
  type = map(object({
    name                = string
    comparison_operator = string
    evaluation_periods  = number
    metric_name         = string
    namespace           = string
    period              = number
    statistic           = string
    threshold           = number
    alarm_description   = optional(string, "")
    alarm_actions       = optional(list(string), [])
    ok_actions          = optional(list(string), [])
    treat_missing_data  = optional(string, "missing")
    
    dimensions = optional(map(string), {})
    
    # For composite alarms
    alarm_rule = optional(string, "")
  }))
  default = {}
}

# ===================================
# NOTIFICATIONS
# ===================================
variable "autoscaling_notifications" {
  description = "Auto Scaling notification configurations"
  type = object({
    enabled = optional(bool, false)
    topic_arn = optional(string, "")
    notifications = optional(list(string), [
      "autoscaling:EC2_INSTANCE_LAUNCH",
      "autoscaling:EC2_INSTANCE_TERMINATE",
      "autoscaling:EC2_INSTANCE_LAUNCH_ERROR",
      "autoscaling:EC2_INSTANCE_TERMINATE_ERROR"
    ])
    asg_keys = optional(list(string), [])
  })
  default = {}
}