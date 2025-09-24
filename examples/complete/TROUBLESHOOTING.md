# EKS Auto Mode Destroy Troubleshooting Guide

This guide helps troubleshoot and resolve common destroy issues with the EKS Auto Mode Terraform module.

## Common Destroy Issues

### 1. CloudWatch Log Groups with prevent_destroy
**Issue**: Log groups are created with `prevent_destroy = true` by default, preventing cluster destruction.

**Solution**: Set `eks_log_prevent_destroy = false` in your configuration.

### 2. Kubernetes Resources Not Cleaned Up
**Issue**: Helm releases and Kubernetes resources remain after terraform destroy.

**Solution**: Use the provided cleanup scripts to manually remove resources.

### 3. AWS Load Balancer Controller Issues
**Issue**: ALBs and target groups remain after controller removal.

**Solution**: Ensure ALBs are deleted before the controller is removed.

### 4. EBS CSI Controller Dependencies
**Issue**: EBS volumes prevent controller removal.

**Solution**: Detach volumes before removing the controller.

### 5. Container Insights Cleanup
**Issue**: Fluent Bit and log groups prevent proper cleanup.

**Solution**: Remove Fluent Bit before deleting log groups.

## Troubleshooting Tools

### 1. MCP Servers Configuration
The `mcp-servers.json` file contains configurations for various MCP servers to help with troubleshooting:

- **AWS Server**: For AWS resource management
- **Kubernetes Server**: For Kubernetes resource management
- **Terraform Server**: For Terraform state management
- **Filesystem Server**: For file operations
- **Memory Server**: For persistent memory
- **Search Servers**: For web searches and documentation

### 2. Troubleshoot Script
Run `./troubleshoot-destroy.sh` to:
- Check AWS CLI access
- Verify Terraform state
- Identify orphaned resources
- Check Kubernetes resources
- Check Helm releases
- Generate troubleshooting report

### 3. Force Destroy Script
Run `./force-destroy.sh` to:
- Clean up Kubernetes resources
- Remove AWS Load Balancers
- Delete CloudWatch Log Groups
- Remove EKS cluster
- Clean up VPC resources
- Run terraform destroy with retries

## Step-by-Step Troubleshooting

### Step 1: Check Current State
```bash
# Check if resources exist
aws-vault exec dev -- aws eks list-clusters --region ap-southeast-2
aws-vault exec dev -- aws ec2 describe-vpcs --region ap-southeast-2 --filters "Name=tag:Name,Values=*cltest*"
```

### Step 2: Clean Up Kubernetes Resources
```bash
# Update kubeconfig
aws-vault exec dev -- aws eks update-kubeconfig --region ap-southeast-2 --name cltest

# Delete workloads
kubectl delete deployment hello-world --namespace default --ignore-not-found=true
kubectl delete service hello-world --namespace default --ignore-not-found=true
kubectl delete ingress hello-world --namespace default --ignore-not-found=true

# Delete Helm releases
helm uninstall aws-load-balancer-controller --namespace kube-system
helm uninstall fluent-bit --namespace aws-observability
helm uninstall aws-ebs-csi-driver --namespace kube-system

# Delete namespaces
kubectl delete namespace aws-observability --ignore-not-found=true
kubectl delete namespace prometheus --ignore-not-found=true
```

### Step 3: Clean Up AWS Resources
```bash
# Delete ALBs
aws-vault exec dev -- aws elbv2 describe-load-balancers --region ap-southeast-2 --query "LoadBalancers[?contains(LoadBalancerName, 'cltest')].LoadBalancerArn" --output text | xargs -I {} aws-vault exec dev -- aws elbv2 delete-load-balancer --region ap-southeast-2 --load-balancer-arn {}

# Delete CloudWatch Log Groups
aws-vault exec dev -- aws logs describe-log-groups --region ap-southeast-2 --log-group-name-prefix "/aws/eks/cltest" --query 'logGroups[].logGroupName' --output text | xargs -I {} aws-vault exec dev -- aws logs delete-log-group --region ap-southeast-2 --log-group-name {}
```

### Step 4: Run Terraform Destroy
```bash
# Run destroy with debugging
TF_LOG=DEBUG aws-vault exec dev -- terraform destroy -auto-approve
```

## Configuration Fixes

### 1. Update main.tf
Add these settings to your `main.tf`:

```hcl
module "eks_auto" {
  # ... existing configuration ...

  # CRITICAL: Disable prevent_destroy for log groups
  eks_log_prevent_destroy = false
  eks_log_retention_days  = 1

  # ... rest of configuration ...
}
```

### 2. Add Destroy Cleanup
Add the `destroy-fixes.tf` file to your configuration for additional cleanup.

### 3. Use Force Destroy Script
For stubborn resources, use the `force-destroy.sh` script.

## Prevention

### 1. Always Set eks_log_prevent_destroy = false
This prevents log groups from blocking cluster destruction.

### 2. Use Proper Resource Dependencies
Ensure resources are destroyed in the correct order.

### 3. Add Timeout Configurations
Add appropriate timeouts for resource creation and destruction.

### 4. Monitor Resource Cleanup
Use the troubleshooting scripts to monitor resource cleanup.

## Emergency Cleanup

If all else fails, use the emergency cleanup commands:

```bash
# Delete everything with cluster name
aws-vault exec dev -- aws resourcegroupstaggingapi get-resources --region ap-southeast-2 --tag-filters Key=Name,Values=*cltest* --query 'ResourceTagMappingList[].ResourceARN' --output text | xargs -I {} aws-vault exec dev -- aws resourcegroupstaggingapi untag-resources --region ap-southeast-2 --resource-arn-list {} --tag-keys Name

# Force delete EKS cluster
aws-vault exec dev -- aws eks delete-cluster --region ap-southeast-2 --name cltest --force

# Delete VPC and all resources
VPC_ID=$(aws-vault exec dev -- aws ec2 describe-vpcs --region ap-southeast-2 --filters "Name=tag:Name,Values=*cltest*" --query 'Vpcs[0].VpcId' --output text)
aws-vault exec dev -- aws ec2 delete-vpc --region ap-southeast-2 --vpc-id $VPC_ID --force
```

## Support

If you continue to experience issues:

1. Check the troubleshooting report generated by the scripts
2. Review the Terraform debug logs
3. Check AWS CloudTrail for API errors
4. Verify IAM permissions for destroy operations
5. Check for resource dependencies in the AWS console

## Files in This Directory

- `mcp-servers.json`: MCP server configurations
- `troubleshoot-destroy.sh`: Comprehensive troubleshooting script
- `force-destroy.sh`: Force destroy script for stubborn resources
- `destroy-fixes.tf`: Additional Terraform configuration for destroy fixes
- `module-destroy-fixes.patch`: Patch file with module fixes
- `TROUBLESHOOTING.md`: This troubleshooting guide
