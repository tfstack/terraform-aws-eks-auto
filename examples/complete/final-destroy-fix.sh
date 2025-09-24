#!/bin/bash

# Final Destroy Fix for EKS Auto Mode
# This script handles the specific issue where Kubernetes resources can't be reached after cluster deletion

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔧 Final Destroy Fix for EKS Auto Mode${NC}"
echo "=============================================="

# Function to remove Kubernetes resources from state
remove_kubernetes_resources_from_state() {
    echo -e "${YELLOW}🧹 Removing Kubernetes resources from Terraform state...${NC}"

    # Remove namespaces from state since cluster is deleted
    terraform state rm 'module.eks_auto.module.namespaces.kubernetes_namespace.this["aws-observability"]' 2>/dev/null || true
    terraform state rm 'module.eks_auto.module.namespaces.kubernetes_namespace.this["prometheus"]' 2>/dev/null || true

    # Remove other Kubernetes resources that might be in state
    terraform state list | grep "kubernetes_" | while read resource; do
        echo "Removing $resource from state"
        terraform state rm "$resource" 2>/dev/null || true
    done

    echo -e "${GREEN}✅ Kubernetes resources removed from state${NC}"
}

# Function to remove EKS cluster from state
remove_eks_cluster_from_state() {
    echo -e "${YELLOW}🧹 Removing EKS cluster from Terraform state...${NC}"

    # Remove EKS cluster and related resources
    terraform state rm 'module.eks_auto.module.cluster.aws_eks_cluster.this' 2>/dev/null || true
    terraform state rm 'module.eks_auto.module.cluster.aws_eks_access_entry.terraform_executor' 2>/dev/null || true
    terraform state rm 'module.eks_auto.module.cluster.aws_eks_access_policy_association.terraform_executor' 2>/dev/null || true
    terraform state rm 'module.eks_auto.module.cluster.aws_iam_openid_connect_provider.this[0]' 2>/dev/null || true

    echo -e "${GREEN}✅ EKS cluster resources removed from state${NC}"
}

# Function to clean up remaining AWS resources
cleanup_remaining_aws_resources() {
    echo -e "${YELLOW}🧹 Cleaning up remaining AWS resources...${NC}"

    # Get VPC ID
    VPC_ID=$(aws ec2 describe-vpcs --region ap-southeast-2 --filters "Name=tag:Name,Values=*cltest*" --query 'Vpcs[0].VpcId' --output text 2>/dev/null || echo "")

    if [ -n "$VPC_ID" ] && [ "$VPC_ID" != "None" ]; then
        echo "Found VPC: $VPC_ID"

        # Delete NAT Gateway
        NAT_GATEWAY=$(aws ec2 describe-nat-gateways --region ap-southeast-2 --filter "Name=vpc-id,Values=$VPC_ID" --query 'NatGateways[?State==`available`].NatGatewayId' --output text 2>/dev/null || echo "")
        if [ -n "$NAT_GATEWAY" ]; then
            echo "Deleting NAT Gateway: $NAT_GATEWAY"
            aws ec2 delete-nat-gateway --region ap-southeast-2 --nat-gateway-id "$NAT_GATEWAY" || true
        fi

        # Wait for NAT Gateway to be deleted
        if [ -n "$NAT_GATEWAY" ]; then
            echo "Waiting for NAT Gateway to be deleted..."
            while aws ec2 describe-nat-gateways --region ap-southeast-2 --nat-gateway-ids "$NAT_GATEWAY" --query 'NatGateways[0].State' --output text 2>/dev/null | grep -q "available"; do
                echo "Still deleting NAT Gateway..."
                sleep 10
            done
        fi

        # Delete Internet Gateway
        IGW_ID=$(aws ec2 describe-internet-gateways --region ap-southeast-2 --filters "Name=attachment.vpc-id,Values=$VPC_ID" --query 'InternetGateways[0].InternetGatewayId' --output text 2>/dev/null || echo "")
        if [ -n "$IGW_ID" ] && [ "$IGW_ID" != "None" ]; then
            echo "Detaching and deleting Internet Gateway: $IGW_ID"
            aws ec2 detach-internet-gateway --region ap-southeast-2 --internet-gateway-id "$IGW_ID" --vpc-id "$VPC_ID" || true
            aws ec2 delete-internet-gateway --region ap-southeast-2 --internet-gateway-id "$IGW_ID" || true
        fi

        # Delete VPC
        echo "Deleting VPC: $VPC_ID"
        aws ec2 delete-vpc --region ap-southeast-2 --vpc-id "$VPC_ID" || true
    fi

    echo -e "${GREEN}✅ AWS resources cleaned up${NC}"
}

# Function to run final terraform destroy
run_final_terraform_destroy() {
    echo -e "${YELLOW}🚀 Running final terraform destroy...${NC}"

    if terraform destroy -auto-approve; then
        echo -e "${GREEN}✅ Final terraform destroy completed successfully${NC}"
        return 0
    else
        echo -e "${RED}❌ Final terraform destroy failed${NC}"
        return 1
    fi
}

# Main execution
main() {
    echo -e "${BLUE}🚀 Starting final destroy fix...${NC}"

    # Step 1: Remove Kubernetes resources from state
    remove_kubernetes_resources_from_state

    # Step 2: Remove EKS cluster from state
    remove_eks_cluster_from_state

    # Step 3: Clean up remaining AWS resources
    cleanup_remaining_aws_resources

    # Step 4: Run final terraform destroy
    run_final_terraform_destroy

    echo -e "${GREEN}🎉 Final destroy fix completed!${NC}"
}

# Run main function
main "$@"
