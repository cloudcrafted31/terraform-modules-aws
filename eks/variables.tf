variable "name_prefix" {
  description = "Name prefix for resources"
  type        = string
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.28"
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the EKS cluster"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for the EKS node group"
  type        = list(string)
}

# Cluster configuration
variable "endpoint_private_access" {
  description = "Enable private API server endpoint"
  type        = bool
  default     = true
}

variable "endpoint_public_access" {
  description = "Enable public API server endpoint"
  type        = bool
  default     = true
}

variable "public_access_cidrs" {
  description = "List of CIDR blocks that can access the public API server endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "additional_security_group_ids" {
  description = "List of additional security group IDs to attach to the EKS cluster"
  type        = list(string)
  default     = []
}

variable "cluster_log_types" {
  description = "List of control plane logging to enable"
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

variable "kms_key_arn" {
  description = "ARN of KMS key for envelope encryption"
  type        = string
  default     = ""
}

# Node group configuration
variable "node_instance_types" {
  description = "List of instance types for the EKS node group"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_desired_capacity" {
  description = "Desired number of nodes in the EKS node group"
  type        = number
  default     = 2
}

variable "node_max_capacity" {
  description = "Maximum number of nodes in the EKS node group"
  type        = number
  default     = 4
}

variable "node_min_capacity" {
  description = "Minimum number of nodes in the EKS node group"
  type        = number
  default     = 1
}

variable "node_disk_size" {
  description = "Disk size in GiB for worker nodes"
  type        = number
  default     = 50
}

variable "capacity_type" {
  description = "Type of capacity associated with the EKS Node Group. Valid values: ON_DEMAND, SPOT"
  type        = string
  default     = "ON_DEMAND"
}

variable "max_unavailable_percentage" {
  description = "Maximum percentage of nodes unavailable during update"
  type        = number
  default     = 25
}

variable "ec2_ssh_key" {
  description = "EC2 Key Pair name for SSH access to worker nodes"
  type        = string
  default     = ""
}

variable "source_security_group_ids" {
  description = "Set of EC2 Security Group IDs to allow SSH access from"
  type        = list(string)
  default     = []
}

variable "launch_template_id" {
  description = "ID of the EC2 Launch Template to use"
  type        = string
  default     = ""
}

variable "launch_template_version" {
  description = "EC2 Launch Template version to use"
  type        = string
  default     = "$Latest"
}

variable "node_labels" {
  description = "Key-value map of Kubernetes labels"
  type        = map(string)
  default     = {}
}

# Add-ons configuration
variable "enable_vpc_cni_addon" {
  description = "Enable VPC CNI add-on"
  type        = bool
  default     = true
}

variable "vpc_cni_addon_version" {
  description = "Version of the VPC CNI add-on"
  type        = string
  default     = null
}

variable "vpc_cni_service_account_role_arn" {
  description = "ARN of IAM role for VPC CNI service account"
  type        = string
  default     = ""
}

variable "enable_coredns_addon" {
  description = "Enable CoreDNS add-on"
  type        = bool
  default     = true
}

variable "coredns_addon_version" {
  description = "Version of the CoreDNS add-on"
  type        = string
  default     = null
}

variable "enable_kube_proxy_addon" {
  description = "Enable kube-proxy add-on"
  type        = bool
  default     = true
}

variable "kube_proxy_addon_version" {
  description = "Version of the kube-proxy add-on"
  type        = string
  default     = null
}

variable "enable_ebs_csi_addon" {
  description = "Enable EBS CSI driver add-on"
  type        = bool
  default     = true
}

variable "ebs_csi_addon_version" {
  description = "Version of the EBS CSI driver add-on"
  type        = string
  default     = null
}

variable "ebs_csi_service_account_role_arn" {
  description = "ARN of IAM role for EBS CSI service account"
  type        = string
  default     = ""
}

variable "enable_irsa" {
  description = "Enable IAM Roles for Service Accounts"
  type        = bool
  default     = true
}

variable "tags" {
  description = "A map of tags to assign to the resource"
  type        = map(string)
  default     = {}
}