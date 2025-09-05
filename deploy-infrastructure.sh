#!/bin/bash

# Deploy Infrastructure - Proper Order
# This script ensures shared resources are deployed first, then environment-specific resources

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Infrastructure Deployment Script${NC}"
echo -e "${BLUE}====================================${NC}"

# Check if AWS CLI is configured
if ! aws sts get-caller-identity &> /dev/null; then
    echo -e "${RED}❌ AWS CLI is not configured or credentials are invalid${NC}"
    echo "Please run 'aws configure' first"
    exit 1
fi

# Get current AWS account info
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
CURRENT_REGION=$(aws configure get region || echo "ap-southeast-2")

echo -e "${GREEN}✅ AWS Account: ${ACCOUNT_ID}${NC}"
echo -e "${GREEN}✅ Region: ${CURRENT_REGION}${NC}"

# Function to deploy terraform
deploy_terraform() {
    local dir=$1
    local name=$2
    
    echo -e "${YELLOW}📁 Deploying ${name}...${NC}"
    cd "$dir"
    
    echo "🔧 Terraform init..."
    terraform init
    
    echo "📋 Terraform plan..."
    terraform plan
    
    echo -e "${YELLOW}❓ Do you want to apply ${name}? (y/N)${NC}"
    read -r response
    
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        echo "🚀 Applying ${name}..."
        terraform apply -auto-approve
        echo -e "${GREEN}✅ ${name} deployed successfully!${NC}"
    else
        echo -e "${YELLOW}⏭️  Skipping ${name}${NC}"
        return 1
    fi
    
    cd - > /dev/null
}

# Step 1: Deploy Shared Resources (OIDC Provider)
echo -e "${BLUE}Step 1: Deploying Shared Resources${NC}"
if deploy_terraform "shared-resources" "Shared Resources (OIDC Provider)"; then
    echo -e "${GREEN}✅ Shared resources deployed${NC}"
else
    echo -e "${RED}❌ Shared resources deployment failed or skipped${NC}"
    exit 1
fi

# Step 2: Deploy Dev Environment
echo -e "${BLUE}Step 2: Deploying Dev Environment${NC}"
if deploy_terraform "environments/dev" "Dev Environment"; then
    echo -e "${GREEN}✅ Dev environment deployed${NC}"
    
    # Get dev role ARN
    cd environments/dev
    DEV_ROLE_ARN=$(terraform output -raw github_actions_role_arn 2>/dev/null || echo "Not available")
    cd - > /dev/null
else
    echo -e "${YELLOW}⏭️  Dev environment skipped${NC}"
fi

# Step 3: Deploy Prod Environment
echo -e "${BLUE}Step 3: Deploying Prod Environment${NC}"
if deploy_terraform "environments/prod" "Prod Environment"; then
    echo -e "${GREEN}✅ Prod environment deployed${NC}"
    
    # Get prod role ARN
    cd environments/prod
    PROD_ROLE_ARN=$(terraform output -raw github_actions_role_arn 2>/dev/null || echo "Not available")
    cd - > /dev/null
else
    echo -e "${YELLOW}⏭️  Prod environment skipped${NC}"
fi

# Summary
echo -e "${GREEN}🎉 Deployment Summary${NC}"
echo -e "${GREEN}===================${NC}"
echo -e "${BLUE}Shared Resources: ✅ Deployed${NC}"
echo -e "${BLUE}Dev Environment: ${DEV_ROLE_ARN:+✅}${DEV_ROLE_ARN:-❌} ${DEV_ROLE_ARN:-Not deployed}${NC}"
echo -e "${BLUE}Prod Environment: ${PROD_ROLE_ARN:+✅}${PROD_ROLE_ARN:-❌} ${PROD_ROLE_ARN:-Not deployed}${NC}"

if [[ -n "$DEV_ROLE_ARN" && "$DEV_ROLE_ARN" != "Not available" ]]; then
    echo ""
    echo -e "${YELLOW}📝 GitHub Secrets to add:${NC}"
    echo "AWS_ROLE_ARN_DEV: $DEV_ROLE_ARN"
fi

if [[ -n "$PROD_ROLE_ARN" && "$PROD_ROLE_ARN" != "Not available" ]]; then
    echo "AWS_ROLE_ARN_PROD: $PROD_ROLE_ARN"
fi

echo ""
echo -e "${GREEN}✅ All done! Your infrastructure is ready for GitHub Actions with OIDC.${NC}"
