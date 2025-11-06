# VPC Module

Creates a VPC with public and private subnets across multiple availability zones.

## Features

- Multi-AZ VPC with configurable CIDR
- Public and private subnets
- Internet Gateway and NAT Gateways
- Route tables and associations
- DNS support and hostnames

## Usage

```hcl
module "vpc" {
  source = "github.com/cloudcrafted31/terraform-modules-aws//vpc?ref=v1.0.0"

  name_prefix = "my-app"
  vpc_cidr    = "10.0.0.0/16"
  
  availability_zones       = ["us-west-2a", "us-west-2b", "us-west-2c"]
  public_subnet_cidrs      = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnet_cidrs     = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
  
  enable_nat_gateway   = true
  single_nat_gateway   = false
  
  tags = {
    Environment = "prod"
    Project     = "my-app"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | ~> 5.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| name_prefix | Name prefix for resources | `string` | n/a | yes |
| vpc_cidr | CIDR block for VPC | `string` | n/a | yes |
| availability_zones | List of availability zones | `list(string)` | n/a | yes |
| public_subnet_cidrs | List of public subnet CIDR blocks | `list(string)` | n/a | yes |
| private_subnet_cidrs | List of private subnet CIDR blocks | `list(string)` | n/a | yes |
| enable_nat_gateway | Enable NAT Gateway for private subnets | `bool` | `true` | no |
| single_nat_gateway | Use single NAT Gateway for all private subnets | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| vpc_id | ID of the VPC |
| vpc_cidr_block | CIDR block of the VPC |
| public_subnet_ids | IDs of the public subnets |
| private_subnet_ids | IDs of the private subnets |
| internet_gateway_id | ID of the Internet Gateway |
| nat_gateway_ids | IDs of the NAT Gateways |
