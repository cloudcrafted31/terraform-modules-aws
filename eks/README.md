# EKS Module

Creates a production-ready EKS cluster with managed node groups.

## Features

- EKS cluster with configurable version
- Managed node groups with auto-scaling
- OIDC provider for IAM Roles for Service Accounts (IRSA)
- Essential add-ons (VPC CNI, CoreDNS, kube-proxy, EBS CSI)
- Proper IAM roles and policies
- Cluster logging and encryption

## Usage

```hcl
module "eks" {
  source = "github.com/cloudcrafted31/terraform-modules-aws//eks?ref=v1.0.0"

  name_prefix    = "my-app"
  cluster_name   = "my-app-cluster"
  cluster_version = "1.28"
  
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = concat(module.vpc.public_subnet_ids, module.vpc.private_subnet_ids)
  private_subnet_ids = module.vpc.private_subnet_ids
  
  node_instance_types   = ["t3.medium"]
  node_desired_capacity = 2
  node_max_capacity     = 4
  node_min_capacity     = 1
  
  tags = {
    Environment = "prod"
    Project     = "my-app"
  }
}
```

## Add-ons

The module installs essential add-ons:
- **VPC CNI**: Pod networking
- **CoreDNS**: Cluster DNS
- **kube-proxy**: Network proxy
- **EBS CSI Driver**: Persistent volumes

## Security

- Cluster endpoint access control
- Security groups for cluster and nodes
- IAM roles with least privilege
- Secrets encryption with KMS

## Outputs

| Name | Description |
|------|-------------|
| cluster_id | Name of the EKS cluster |
| cluster_arn | ARN of the EKS cluster |
| cluster_endpoint | Endpoint for EKS control plane |
| cluster_security_group_id | Security group ID attached to the EKS cluster |
| node_group_arn | ARN of the EKS node group |
