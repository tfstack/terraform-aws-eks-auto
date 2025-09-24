#!/bin/bash

# Terraform EKS Auto Mode Destroy Troubleshooting Script
# This script helps identify and resolve common destroy issues

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
NAMESPACES=("aws-observability" "prometheus" "default")

echo -e "${BLUE}🔍 Starting Terraform EKS Auto Mode Destroy Troubleshooting${NC}"
echo "=================================================="

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check AWS CLI access
check_aws_access() {
    echo -e "${YELLOW}📋 Checking AWS CLI access...${NC}"
    if aws sts get-caller-identity >/dev/null 2>&1; then
        echo -e "${GREEN}✅ AWS CLI access confirmed${NC}"
        aws sts get-caller-identity
    else
        echo -e "${RED}❌ AWS CLI access failed${NC}"
        exit 1
    fi
}

# Function to check kubectl access
check_kubectl_access() {
    echo -e "${YELLOW}📋 Checking kubectl access...${NC}"
    if aws eks update-kubeconfig --region $REGION --name $CLUSTER_NAME >/dev/null 2>&1; then
        echo -e "${GREEN}✅ kubectl access confirmed${NC}"
        kubectl cluster-info
    else
        echo -e "${YELLOW}⚠️  kubectl access failed - cluster may not exist or be accessible${NC}"
    fi
}

# Function to check Terraform state
check_terraform_state() {
    echo -e "${YELLOW}📋 Checking Terraform state...${NC}"
    if [ -f "terraform.tfstate" ]; then
        echo -e "${GREEN}✅ Terraform state file exists${NC}"
        echo "State file size: $(du -h terraform.tfstate | cut -f1)"

        # Check if state is empty
        if terraform state list 2>/dev/null | grep -q .; then
            echo -e "${GREEN}✅ Terraform state contains resources${NC}"
            echo "Resources in state:"
            terraform state list
        else
            echo -e "${YELLOW}⚠️  Terraform state is empty${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  No Terraform state file found${NC}"
    fi
}

# Function to check for orphaned AWS resources
check_orphaned_resources() {
    echo -e "${YELLOW}📋 Checking for orphaned AWS resources...${NC}"

    # Check EKS clusters
    echo "Checking EKS clusters..."
    CLUSTERS=$(aws eks list-clusters --region $REGION --query 'clusters[]' --output text 2>/dev/null || echo "")
    if [ -n "$CLUSTERS" ]; then
        echo -e "${YELLOW}⚠️  Found EKS clusters: $CLUSTERS${NC}"
        for cluster in $CLUSTERS; do
            if [[ "$cluster" == *"$CLUSTER_NAME"* ]]; then
                echo -e "${RED}❌ Found cluster matching our name: $cluster${NC}"
            fi
        done
    else
        echo -e "${GREEN}✅ No EKS clusters found${NC}"
    fi

    # Check VPCs
    echo "Checking VPCs..."
    VPCS=$(aws ec2 describe-vpcs --region $REGION --filters "Name=tag:Name,Values=*$CLUSTER_NAME*" --query 'Vpcs[].VpcId' --output text 2>/dev/null || echo "")
    if [ -n "$VPCS" ]; then
        echo -e "${YELLOW}⚠️  Found VPCs: $VPCS${NC}"
    else
        echo -e "${GREEN}✅ No VPCs found with cluster name${NC}"
    fi

    # Check Load Balancers
    echo "Checking Load Balancers..."
    ALBS=$(aws elbv2 describe-load-balancers --region $REGION --query 'LoadBalancers[?contains(LoadBalancerName, `'$CLUSTER_NAME'`)].LoadBalancerName' --output text 2>/dev/null || echo "")
    if [ -n "$ALBS" ]; then
        echo -e "${YELLOW}⚠️  Found ALBs: $ALBS${NC}"
    else
        echo -e "${GREEN}✅ No ALBs found with cluster name${NC}"
    fi

    # Check CloudWatch Log Groups
    echo "Checking CloudWatch Log Groups..."
    LOG_GROUPS=$(aws logs describe-log-groups --region $REGION --log-group-name-prefix "/aws/eks/$CLUSTER_NAME" --query 'logGroups[].logGroupName' --output text 2>/dev/null || echo "")
    if [ -n "$LOG_GROUPS" ]; then
        echo -e "${YELLOW}⚠️  Found CloudWatch Log Groups: $LOG_GROUPS${NC}"
    else
        echo -e "${GREEN}✅ No CloudWatch Log Groups found${NC}"
    fi
}

# Function to check Kubernetes resources
check_kubernetes_resources() {
    echo -e "${YELLOW}📋 Checking Kubernetes resources...${NC}"

    if command_exists kubectl; then
        for namespace in "${NAMESPACES[@]}"; do
            echo "Checking namespace: $namespace"
            if kubectl get namespace "$namespace" >/dev/null 2>&1; then
                echo -e "${YELLOW}⚠️  Namespace $namespace exists${NC}"

                # Check for resources in namespace
                RESOURCES=$(kubectl api-resources --verbs=list --namespaced -o name | xargs -n 1 kubectl get --show-kind --ignore-not-found -n "$namespace" 2>/dev/null | wc -l)
                if [ "$RESOURCES" -gt 0 ]; then
                    echo -e "${YELLOW}⚠️  Found $RESOURCES resources in namespace $namespace${NC}"
                fi
            else
                echo -e "${GREEN}✅ Namespace $namespace does not exist${NC}"
            fi
        done
    else
        echo -e "${YELLOW}⚠️  kubectl not available${NC}"
    fi
}

# Function to check Helm releases
check_helm_releases() {
    echo -e "${YELLOW}📋 Checking Helm releases...${NC}"

    if command_exists helm; then
        RELEASES=$(helm list --all-namespaces --output json 2>/dev/null | jq -r '.[].name' 2>/dev/null || echo "")
        if [ -n "$RELEASES" ]; then
            echo -e "${YELLOW}⚠️  Found Helm releases: $RELEASES${NC}"
            helm list --all-namespaces
        else
            echo -e "${GREEN}✅ No Helm releases found${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  Helm not available${NC}"
    fi
}

# Function to attempt cleanup
attempt_cleanup() {
    echo -e "${YELLOW}🧹 Attempting cleanup...${NC}"

    # Try to clean up Kubernetes resources first
    if command_exists kubectl; then
        echo "Cleaning up Kubernetes resources..."
        for namespace in "${NAMESPACES[@]}"; do
            if kubectl get namespace "$namespace" >/dev/null 2>&1; then
                echo "Deleting namespace: $namespace"
                kubectl delete namespace "$namespace" --timeout=60s || echo "Failed to delete namespace $namespace"
            fi
        done
    fi

    # Try to clean up Helm releases
    if command_exists helm; then
        echo "Cleaning up Helm releases..."
        helm list --all-namespaces --output json 2>/dev/null | jq -r '.[].name' | while read release; do
            if [ -n "$release" ]; then
                echo "Deleting Helm release: $release"
                helm uninstall "$release" --all-namespaces || echo "Failed to delete Helm release $release"
            fi
        done
    fi
}

# Function to run terraform destroy with debugging
run_terraform_destroy() {
    echo -e "${YELLOW}🚀 Running terraform destroy with debugging...${NC}"

    # Set Terraform debug logging
    export TF_LOG=DEBUG
    export TF_LOG_PATH=terraform-debug.log

    echo "Starting terraform destroy..."
    if terraform destroy -auto-approve; then
        echo -e "${GREEN}✅ Terraform destroy completed successfully${NC}"
    else
        echo -e "${RED}❌ Terraform destroy failed${NC}"
        echo "Check terraform-debug.log for details"
        return 1
    fi
}

# Function to generate troubleshooting report
generate_report() {
    echo -e "${BLUE}📊 Generating troubleshooting report...${NC}"

    REPORT_FILE="terraform-destroy-report-$(date +%Y%m%d-%H%M%S).txt"

    {
        echo "Terraform EKS Auto Mode Destroy Troubleshooting Report"
        echo "Generated: $(date)"
        echo "=================================================="
        echo ""

        echo "AWS CLI Access:"
        aws sts get-caller-identity 2>&1 || echo "Failed"
        echo ""

        echo "Terraform State:"
        terraform state list 2>&1 || echo "Failed"
        echo ""

        echo "EKS Clusters:"
        aws eks list-clusters --region $REGION 2>&1 || echo "Failed"
        echo ""

        echo "VPCs:"
        aws ec2 describe-vpcs --region $REGION --filters "Name=tag:Name,Values=*$CLUSTER_NAME*" 2>&1 || echo "Failed"
        echo ""

        echo "Load Balancers:"
        aws elbv2 describe-load-balancers --region $REGION 2>&1 || echo "Failed"
        echo ""

        echo "CloudWatch Log Groups:"
        aws logs describe-log-groups --region $REGION --log-group-name-prefix "/aws/eks/$CLUSTER_NAME" 2>&1 || echo "Failed"
        echo ""

        echo "Kubernetes Resources:"
        kubectl get all --all-namespaces 2>&1 || echo "Failed"
        echo ""

        echo "Helm Releases:"
        helm list --all-namespaces 2>&1 || echo "Failed"

    } > "$REPORT_FILE"

    echo -e "${GREEN}✅ Report generated: $REPORT_FILE${NC}"
}

# Main execution
main() {
    echo -e "${BLUE}🚀 Starting comprehensive destroy troubleshooting...${NC}"

    # Check prerequisites
    if ! command_exists aws-vault; then
        echo -e "${RED}❌ aws-vault not found. Please install aws-vault.${NC}"
        exit 1
    fi

    if ! command_exists terraform; then
        echo -e "${RED}❌ terraform not found. Please install terraform.${NC}"
        exit 1
    fi

    # Run checks
    check_aws_access
    check_terraform_state
    check_orphaned_resources
    check_kubectl_access
    check_kubernetes_resources
    check_helm_releases

    # Ask user if they want to proceed with cleanup
    echo ""
    read -p "Do you want to attempt cleanup and destroy? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        attempt_cleanup
        run_terraform_destroy
    fi

    # Generate report
    generate_report

    echo -e "${GREEN}🎉 Troubleshooting complete!${NC}"
}

# Run main function
main "$@"
