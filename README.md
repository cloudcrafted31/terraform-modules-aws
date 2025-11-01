# Terraform AWS Modules

A collection of reusable Terraform modules for AWS infrastructure.

## Available Modules

- **[vpc](./vpc/)** - VPC with public/private subnets, NAT gateways, and routing
- **[security-groups](./security-groups/)** - Security groups for multi-tier applications
- **[auto-scaling](./auto-scaling/)** - Auto Scaling Groups with ALB and launch templates
- **[eks](./eks/)** - Production-ready EKS cluster with managed node groups
- **[monitoring](./monitoring/)** - CloudWatch monitoring and SNS notifications

## Usage

```hcl
module "vpc" {
  source = "github.com/cloudcrafted31/terraform-modules-aws//vpc?ref=v1.0.0"
  
  name_prefix = "my-app"
  vpc_cidr    = "10.0.0.0/16"
  # ... other variables
}
```

## Module Standards

All modules follow these standards:
- Comprehensive variable validation
- Detailed outputs
- README documentation
- Example usage
- Semantic versioning

## Contributing

1. Follow Terraform best practices
2. Include comprehensive documentation
3. Add examples for each module
4. Test modules before submitting PRs

## License

MIT License - see LICENSE file for details.
