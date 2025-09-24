#!/bin/bash

# Force Destroy Script for EKS Auto Mode
# This script handles the specific destroy issues identified in the module

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
CLUSTER_NAME="cltest"
REGION="ap-southeast-2"
NAMESPACES=("aws-observability" "prometheus" "default" "kube-system")

echo -e "${BLUE}🔥 Force Destroy Script for EKS Auto Mode${NC}"
echo "=============================================="

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to wait for resource deletion
wait_for_deletion() {
    local resource_type="$1"
    local resource_name="$2"
    local max_attempts=30
    local attempt=0

    echo -e "${YELLOW}⏳ Waiting for $resource_type '$resource_name' to be deleted...${NC}"

    while [ $attempt -lt $max_attempts ]; do
        if ! aws $resource_type describe-$resource_type --region $REGION --$resource_type-ids "$resource_name" >/dev/null 2>&1; then
            echo -e "${GREEN}✅ $resource_type '$resource_name' deleted successfully${NC}"
            return 0
        fi

        echo -e "${YELLOW}⏳ Still waiting... (attempt $((attempt + 1))/$max_attempts)${NC}"
        sleep 10
        ((attempt++))
    done

    echo -e "${RED}❌ Timeout waiting for $resource_type '$resource_name' to be deleted${NC}"
    return 1
}

# Function to clean up Kubernetes resources
cleanup_kubernetes_resources() {
    echo -e "${YELLOW}🧹 Cleaning up Kubernetes resources...${NC}"

    # Update kubeconfig
    if aws eks update-kubeconfig --region $REGION --name $CLUSTER_NAME >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Kubeconfig updated${NC}"

        # Delete workloads first
        echo "Deleting workloads..."
        kubectl delete deployment hello-world --namespace default --ignore-not-found=true --timeout=60s || true
        kubectl delete service hello-world --namespace default --ignore-not-found=true --timeout=60s || true
        kubectl delete ingress hello-world --namespace default --ignore-not-found=true --timeout=60s || true

        # Delete Helm releases
        echo "Deleting Helm releases..."
        helm uninstall aws-load-balancer-controller --namespace kube-system --timeout=60s 2>/dev/null || true
        helm uninstall fluent-bit --namespace aws-observability --timeout=60s 2>/dev/null || true
        helm uninstall aws-ebs-csi-driver --namespace kube-system --timeout=60s 2>/dev/null || true

        # Delete namespaces
        echo "Deleting namespaces..."
        for namespace in "${NAMESPACES[@]}"; do
            if kubectl get namespace "$namespace" >/dev/null 2>&1; then
                echo "Deleting namespace: $namespace"
                kubectl delete namespace "$namespace" --ignore-not-found=true --timeout=60s || true
            fi
        done

        # Wait for finalizers to complete
        echo "Waiting for finalizers to complete..."
        sleep 30

    else
        echo -e "${YELLOW}⚠️  Could not update kubeconfig - cluster may not exist${NC}"
    fi
}

# Function to clean up AWS Load Balancers
cleanup_load_balancers() {
    echo -e "${YELLOW}🧹 Cleaning up AWS Load Balancers...${NC}"

    # Get all ALBs with cluster name
    ALBS=$(aws elbv2 describe-load-balancers --region $REGION --query "LoadBalancers[?contains(LoadBalancerName, '$CLUSTER_NAME')].LoadBalancerArn" --output text 2>/dev/null || echo "")

    if [ -n "$ALBS" ]; then
        echo "Found ALBs: $ALBS"
        for alb in $ALBS; do
            echo "Deleting ALB: $alb"
            aws elbv2 delete-load-balancer --region $REGION --load-balancer-arn "$alb" || true
        done

        # Wait for ALBs to be deleted
        for alb in $ALBS; do
            wait_for_deletion "elbv2" "$alb" || true
        done
    else
        echo -e "${GREEN}✅ No ALBs found with cluster name${NC}"
    fi
}

# Function to clean up CloudWatch Log Groups
cleanup_cloudwatch_logs() {
    echo -e "${YELLOW}🧹 Cleaning up CloudWatch Log Groups...${NC}"

    # Get all log groups with cluster name
    LOG_GROUPS=$(aws logs describe-log-groups --region $REGION --log-group-name-prefix "/aws/eks/$CLUSTER_NAME" --query 'logGroups[].logGroupName' --output text 2>/dev/null || echo "")

    if [ -n "$LOG_GROUPS" ]; then
        echo "Found log groups: $LOG_GROUPS"
        for log_group in $LOG_GROUPS; do
            echo "Deleting log group: $log_group"
            aws logs delete-log-group --region $REGION --log-group-name "$log_group" || true
        done
    else
        echo -e "${GREEN}✅ No CloudWatch log groups found${NC}"
    fi
}

# Function to clean up EKS cluster
cleanup_eks_cluster() {
    echo -e "${YELLOW}🧹 Cleaning up EKS cluster...${NC}"

    # Check if cluster exists
    if aws eks describe-cluster --region $REGION --name $CLUSTER_NAME >/dev/null 2>&1; then
        echo "Deleting EKS cluster: $CLUSTER_NAME"
        aws eks delete-cluster --region $REGION --name $CLUSTER_NAME || true

        # Wait for cluster to be deleted
        echo "Waiting for EKS cluster to be deleted..."
        while aws eks describe-cluster --region $REGION --name $CLUSTER_NAME >/dev/null 2>&1; do
            echo -e "${YELLOW}⏳ Cluster still exists, waiting...${NC}"
            sleep 30
        done
        echo -e "${GREEN}✅ EKS cluster deleted${NC}"
    else
        echo -e "${GREEN}✅ EKS cluster does not exist${NC}"
    fi
}

# Function to clean up VPC and related resources
cleanup_vpc_resources() {
    echo -e "${YELLOW}🧹 Cleaning up VPC resources...${NC}"

    # Get VPC ID
    VPC_ID=$(aws ec2 describe-vpcs --region $REGION --filters "Name=tag:Name,Values=*$CLUSTER_NAME*" --query 'Vpcs[0].VpcId' --output text 2>/dev/null || echo "")

    if [ -n "$VPC_ID" ] && [ "$VPC_ID" != "None" ]; then
        echo "Found VPC: $VPC_ID"

        # Delete NAT Gateways
        NAT_GATEWAYS=$(aws ec2 describe-nat-gateways --region $REGION --filter "Name=vpc-id,Values=$VPC_ID" --query 'NatGateways[?State==`available`].NatGatewayId' --output text 2>/dev/null || echo "")
        if [ -n "$NAT_GATEWAYS" ]; then
            for nat in $NAT_GATEWAYS; do
                echo "Deleting NAT Gateway: $nat"
                aws ec2 delete-nat-gateway --region $REGION --nat-gateway-id "$nat" || true
            done
        fi

        # Delete Internet Gateways
        IGW_ID=$(aws ec2 describe-internet-gateways --region $REGION --filters "Name=attachment.vpc-id,Values=$VPC_ID" --query 'InternetGateways[0].InternetGatewayId' --output text 2>/dev/null || echo "")
        if [ -n "$IGW_ID" ] && [ "$IGW_ID" != "None" ]; then
            echo "Detaching and deleting Internet Gateway: $IGW_ID"
            aws ec2 detach-internet-gateway --region $REGION --internet-gateway-id "$IGW_ID" --vpc-id "$VPC_ID" || true
            aws ec2 delete-internet-gateway --region $REGION --internet-gateway-id "$IGW_ID" || true
        fi

        # Delete VPC
        echo "Deleting VPC: $VPC_ID"
        aws ec2 delete-vpc --region $REGION --vpc-id "$VPC_ID" || true
        echo -e "${GREEN}✅ VPC resources cleaned up${NC}"
    else
        echo -e "${GREEN}✅ No VPC found with cluster name${NC}"
    fi
}

# Function to run terraform destroy with retries
run_terraform_destroy() {
    echo -e "${YELLOW}🚀 Running terraform destroy...${NC}"

    local max_attempts=3
    local attempt=1

    while [ $attempt -le $max_attempts ]; do
        echo -e "${BLUE}Attempt $attempt of $max_attempts${NC}"

        if terraform destroy -auto-approve; then
            echo -e "${GREEN}✅ Terraform destroy completed successfully${NC}"
            return 0
        else
            echo -e "${RED}❌ Terraform destroy failed on attempt $attempt${NC}"

            if [ $attempt -lt $max_attempts ]; then
                echo -e "${YELLOW}🔄 Retrying in 30 seconds...${NC}"
                sleep 30
            fi
        fi

        ((attempt++))
    done

    echo -e "${RED}❌ All terraform destroy attempts failed${NC}"
    return 1
}

# Main execution
main() {
    echo -e "${BLUE}🚀 Starting force destroy process...${NC}"

    # Check prerequisites
    if ! command_exists aws-vault; then
        echo -e "${RED}❌ aws-vault not found. Please install aws-vault.${NC}"
        exit 1
    fi

    if ! command_exists terraform; then
        echo -e "${RED}❌ terraform not found. Please install terraform.${NC}"
        exit 1
    fi

    # Step 1: Clean up Kubernetes resources
    cleanup_kubernetes_resources

    # Step 2: Clean up AWS Load Balancers
    cleanup_load_balancers

    # Step 3: Clean up CloudWatch Log Groups
    cleanup_cloudwatch_logs

    # Step 4: Clean up EKS cluster
    cleanup_eks_cluster

    # Step 5: Clean up VPC resources
    cleanup_vpc_resources

    # Step 6: Run terraform destroy
    run_terraform_destroy

    echo -e "${GREEN}🎉 Force destroy process completed!${NC}"
}

# Run main function
main "$@"
