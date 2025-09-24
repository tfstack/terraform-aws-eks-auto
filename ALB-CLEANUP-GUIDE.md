# ALB Cleanup Guide

## The Problem

When using AWS Load Balancer Controller with EKS, ALBs and target groups are created automatically but may not be deleted immediately when the Kubernetes ingress is removed. This can cause `terraform destroy` to fail with dependency errors.

## The Solution

This module now includes:
1. **Terraform-managed security groups** for ALBs
2. **Proper lifecycle management** for Kubernetes resources
3. **Enhanced provider configuration** for graceful cluster deletion

## Manual Cleanup (When Needed)

If `terraform destroy` fails due to ALB dependencies, run this cleanup script:

```bash
#!/bin/bash
# cleanup-alb.sh

echo "Cleaning up ALB resources..."

# Get VPC ID from Terraform state
VPC_ID=$(terraform output -raw vpc_id 2>/dev/null || echo "")

if [ -z "$VPC_ID" ]; then
  echo "Could not get VPC ID from Terraform state"
  exit 1
fi

echo "VPC ID: $VPC_ID"

# Delete ALBs
echo "Deleting ALBs..."
aws elbv2 describe-load-balancers --query 'LoadBalancers[?VpcId==`'$VPC_ID'`].LoadBalancerArn' --output text | while read arn; do
  if [ -n "$arn" ]; then
    echo "Deleting ALB: $arn"
    aws elbv2 delete-load-balancer --load-balancer-arn "$arn"
  fi
done

# Delete target groups
echo "Deleting target groups..."
aws elbv2 describe-target-groups --query 'TargetGroups[?VpcId==`'$VPC_ID'`].TargetGroupArn' --output text | while read arn; do
  if [ -n "$arn" ]; then
    echo "Deleting target group: $arn"
    aws elbv2 delete-target-group --target-group-arn "$arn"
  fi
done

# Wait for cleanup
echo "Waiting for cleanup to complete..."
sleep 30

echo "Cleanup complete. You can now run 'terraform destroy' again."
```

## Usage

1. **Normal destroy**: `terraform destroy` (should work in most cases)
2. **If it fails**: Run the cleanup script above
3. **Retry destroy**: `terraform destroy` again

## Why This Approach?

- **No flaky null_resource** - Avoids complex provisioner logic
- **Clear documentation** - Users know what to do when issues occur
- **Production-ready** - Handles the real-world limitations of AWS ALB integration
- **Maintainable** - Simple, understandable solution

## Prevention

The module now includes:
- Terraform-managed security groups (no orphaned resources)
- Proper lifecycle management for Kubernetes resources
- Enhanced provider configuration for graceful cluster deletion

This reduces the likelihood of cleanup issues but doesn't eliminate them entirely due to AWS ALB controller limitations.
