# Hello World Self-Contained Example

This example demonstrates a **completely self-contained** hello-world application that manages its own:

- **VPC and networking** (using terraform-aws-modules/vpc/aws)
- **EKS cluster** (using terraform-aws-modules/eks/aws)
- **ALB security groups** (managed by Terraform)
- **AWS Load Balancer Controller** (with proper IAM roles)
- **Hello World application** (deployment, service, ingress)

## Key Benefits

✅ **No external dependencies** - Everything is managed by Terraform
✅ **No orphaned resources** - All ALB security groups are Terraform-managed
✅ **Clean destroy** - No manual cleanup required
✅ **Self-contained** - Single module handles everything
✅ **Production-ready** - Uses proven AWS modules

## Usage

```bash
# Initialize
terraform init

# Plan
terraform plan

# Apply
terraform apply

# Get ALB URL
terraform output alb_url

# Update kubeconfig
eval $(terraform output kubeconfig_command)

# Check the application
kubectl get ingress
kubectl get pods

# Destroy (should work cleanly)
terraform destroy
```

## What's Different

This approach eliminates the destroy issues by:

1. **Self-contained module** - Everything is in one place
2. **Terraform-managed security groups** - No orphaned ALB resources
3. **Proper dependency management** - Resources are created in the right order
4. **Clean separation** - No shared state between different workloads

## Architecture

```
┌─────────────────────────────────────┐
│ Hello World Module                  │
├─────────────────────────────────────┤
│ • VPC (terraform-aws-modules/vpc)   │
│ • EKS (terraform-aws-modules/eks)   │
│ • ALB Security Groups               │
│ • AWS Load Balancer Controller      │
│ • Hello World App (K8s resources)   │
└─────────────────────────────────────┘
```

## Resources Created

- **VPC** with public/private subnets
- **EKS cluster** with managed node group
- **ALB security groups** (Terraform-managed)
- **AWS Load Balancer Controller** with IAM roles
- **Hello World application** (deployment, service, ingress)
- **Application Load Balancer** (created by the controller)

## Destroy Process

The destroy process should work cleanly because:

1. **All resources are Terraform-managed** - No orphaned resources
2. **Proper dependency order** - Resources are destroyed in the right sequence
3. **Self-contained state** - No shared dependencies with other modules
4. **Terraform-managed security groups** - ALB cleanup is handled automatically
