#!/bin/bash
# cleanup-alb.sh - Clean up ALB resources that may prevent terraform destroy

set -e

echo "🧹 ALB Cleanup Script"
echo "===================="

# Get VPC ID from Terraform state
echo "📋 Getting VPC ID from Terraform state..."
VPC_ID=$(terraform output -raw vpc_id 2>/dev/null || echo "")

if [ -z "$VPC_ID" ]; then
  echo "❌ Could not get VPC ID from Terraform state"
  echo "   Make sure you're in the correct directory and terraform state exists"
  exit 1
fi

echo "✅ VPC ID: $VPC_ID"

# Delete ALBs
echo "🔄 Deleting ALBs..."
ALB_ARNS=$(aws elbv2 describe-load-balancers --query 'LoadBalancers[?VpcId==`'$VPC_ID'`].LoadBalancerArn' --output text 2>/dev/null || echo "")

if [ -n "$ALB_ARNS" ]; then
  echo "$ALB_ARNS" | while read arn; do
    if [ -n "$arn" ]; then
      echo "  🗑️  Deleting ALB: $arn"
      aws elbv2 delete-load-balancer --load-balancer-arn "$arn" || echo "    ⚠️  Failed to delete ALB: $arn"
    fi
  done
else
  echo "  ✅ No ALBs found"
fi

# Delete target groups
echo "🔄 Deleting target groups..."
TG_ARNS=$(aws elbv2 describe-target-groups --query 'TargetGroups[?VpcId==`'$VPC_ID'`].TargetGroupArn' --output text 2>/dev/null || echo "")

if [ -n "$TG_ARNS" ]; then
  echo "$TG_ARNS" | while read arn; do
    if [ -n "$arn" ]; then
      echo "  🗑️  Deleting target group: $arn"
      aws elbv2 delete-target-group --target-group-arn "$arn" || echo "    ⚠️  Failed to delete target group: $arn"
    fi
  done
else
  echo "  ✅ No target groups found"
fi

# Wait for cleanup
echo "⏳ Waiting for cleanup to complete..."
sleep 30

echo "✅ Cleanup complete!"
echo "   You can now run 'terraform destroy' again"
