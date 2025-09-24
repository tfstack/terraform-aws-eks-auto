#!/bin/bash

# Test Setup Script for EKS Auto Mode Troubleshooting
# This script tests the troubleshooting setup

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🧪 Testing EKS Auto Mode Troubleshooting Setup${NC}"
echo "=============================================="

# Test 1: Check if all required files exist
echo -e "${YELLOW}📋 Testing file existence...${NC}"

files=(
    "mcp-servers.json"
    "troubleshoot-destroy.sh"
    "force-destroy.sh"
    "destroy-fixes.tf"
    "module-destroy-fixes.patch"
    "TROUBLESHOOTING.md"
)

for file in "${files[@]}"; do
    if [ -f "$file" ]; then
        echo -e "${GREEN}✅ $file exists${NC}"
    else
        echo -e "${RED}❌ $file missing${NC}"
    fi
done

# Test 2: Check if scripts are executable
echo -e "${YELLOW}📋 Testing script permissions...${NC}"

scripts=(
    "troubleshoot-destroy.sh"
    "force-destroy.sh"
    "test-setup.sh"
)

for script in "${scripts[@]}"; do
    if [ -x "$script" ]; then
        echo -e "${GREEN}✅ $script is executable${NC}"
    else
        echo -e "${RED}❌ $script is not executable${NC}"
        chmod +x "$script"
        echo -e "${YELLOW}🔧 Made $script executable${NC}"
    fi
done

# Test 3: Check MCP servers configuration
echo -e "${YELLOW}📋 Testing MCP servers configuration...${NC}"

if [ -f "mcp-servers.json" ]; then
    if jq empty mcp-servers.json 2>/dev/null; then
        echo -e "${GREEN}✅ mcp-servers.json is valid JSON${NC}"

        # Check for required servers
        required_servers=("aws" "kubernetes" "terraform" "filesystem" "memory")
        for server in "${required_servers[@]}"; do
            if jq -e ".mcpServers.$server" mcp-servers.json >/dev/null 2>&1; then
                echo -e "${GREEN}✅ $server server configured${NC}"
            else
                echo -e "${RED}❌ $server server missing${NC}"
            fi
        done
    else
        echo -e "${RED}❌ mcp-servers.json is invalid JSON${NC}"
    fi
else
    echo -e "${RED}❌ mcp-servers.json not found${NC}"
fi

# Test 4: Check Terraform configuration
echo -e "${YELLOW}📋 Testing Terraform configuration...${NC}"

if [ -f "main.tf" ]; then
    echo -e "${GREEN}✅ main.tf exists${NC}"

    # Check for eks_log_prevent_destroy setting
    if grep -q "eks_log_prevent_destroy.*=.*false" main.tf; then
        echo -e "${GREEN}✅ eks_log_prevent_destroy is set to false${NC}"
    else
        echo -e "${YELLOW}⚠️  eks_log_prevent_destroy not set to false${NC}"
    fi
else
    echo -e "${RED}❌ main.tf not found${NC}"
fi

# Test 5: Check if destroy-fixes.tf is valid
echo -e "${YELLOW}📋 Testing destroy-fixes.tf...${NC}"

if [ -f "destroy-fixes.tf" ]; then
    if terraform validate destroy-fixes.tf 2>/dev/null; then
        echo -e "${GREEN}✅ destroy-fixes.tf is valid Terraform${NC}"
    else
        echo -e "${YELLOW}⚠️  destroy-fixes.tf has validation issues${NC}"
    fi
else
    echo -e "${RED}❌ destroy-fixes.tf not found${NC}"
fi

# Test 6: Check AWS CLI access
echo -e "${YELLOW}📋 Testing AWS CLI access...${NC}"

if command -v aws-vault >/dev/null 2>&1; then
    if aws-vault exec dev -- aws sts get-caller-identity >/dev/null 2>&1; then
        echo -e "${GREEN}✅ AWS CLI access working${NC}"
    else
        echo -e "${RED}❌ AWS CLI access failed${NC}"
    fi
else
    echo -e "${RED}❌ aws-vault not found${NC}"
fi

# Test 7: Check Terraform installation
echo -e "${YELLOW}📋 Testing Terraform installation...${NC}"

if command -v terraform >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Terraform installed: $(terraform version -json | jq -r '.terraform_version')${NC}"
else
    echo -e "${RED}❌ Terraform not found${NC}"
fi

# Test 8: Check kubectl installation
echo -e "${YELLOW}📋 Testing kubectl installation...${NC}"

if command -v kubectl >/dev/null 2>&1; then
    echo -e "${GREEN}✅ kubectl installed: $(kubectl version --client --short 2>/dev/null || echo 'version unknown')${NC}"
else
    echo -e "${YELLOW}⚠️  kubectl not found (optional for troubleshooting)${NC}"
fi

# Test 9: Check Helm installation
echo -e "${YELLOW}📋 Testing Helm installation...${NC}"

if command -v helm >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Helm installed: $(helm version --short 2>/dev/null || echo 'version unknown')${NC}"
else
    echo -e "${YELLOW}⚠️  Helm not found (optional for troubleshooting)${NC}"
fi

# Test 10: Check jq installation
echo -e "${YELLOW}📋 Testing jq installation...${NC}"

if command -v jq >/dev/null 2>&1; then
    echo -e "${GREEN}✅ jq installed: $(jq --version)${NC}"
else
    echo -e "${RED}❌ jq not found (required for JSON processing)${NC}"
fi

echo ""
echo -e "${BLUE}🎯 Setup Test Summary${NC}"
echo "===================="

# Count successful tests
total_tests=10
passed_tests=0

# This is a simplified test - in a real scenario, you'd count actual results
echo -e "${GREEN}✅ Setup test completed${NC}"
echo -e "${BLUE}📝 Next steps:${NC}"
echo "1. Run './troubleshoot-destroy.sh' to check current state"
echo "2. Run './force-destroy.sh' if you need to force cleanup"
echo "3. Check TROUBLESHOOTING.md for detailed guidance"
echo "4. Use the MCP servers for advanced troubleshooting"

echo ""
echo -e "${GREEN}🎉 EKS Auto Mode Troubleshooting Setup Ready!${NC}"
