#!/bin/bash

# Deploy IAM Roles for GitHub Actions OIDC
# This script sets up the necessary IAM roles for secure GitHub Actions authentication

set -e

echo "🚀 Setting up IAM Roles for GitHub Actions OIDC..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if AWS CLI is configured
if ! aws sts get-caller-identity &> /dev/null; then
    echo -e "${RED}❌ AWS CLI is not configured or credentials are invalid${NC}"
    echo "Please run 'aws configure' first"
    exit 1
fi

echo -e "${GREEN}✅ AWS CLI is configured${NC}"

# Get current AWS account info
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
CURRENT_REGION=$(aws configure get region || echo "ap-southeast-2")

echo -e "${BLUE}📋 Current AWS Account: ${ACCOUNT_ID}${NC}"
echo -e "${BLUE}📋 Current Region: ${CURRENT_REGION}${NC}"

# Navigate to iam-roles directory
cd "$(dirname "$0")/iam-roles"

# Initialize Terraform
echo -e "${YELLOW}🔧 Initializing Terraform...${NC}"
terraform init

# Plan the deployment
echo -e "${YELLOW}📋 Planning Terraform deployment...${NC}"
terraform plan \
    -var="aws_region=${CURRENT_REGION}" \
    -var="github_org=tuankiet116" \
    -var="github_repo=infra-provisioning-vti" \
    -var="terraform_state_bucket=terraform-state-vti-infra-${ACCOUNT_ID}"

# Ask for confirmation
echo -e "${YELLOW}❓ Do you want to apply these changes? (y/N)${NC}"
read -r response

if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    echo -e "${YELLOW}🚀 Applying Terraform configuration...${NC}"
    terraform apply \
        -var="aws_region=${CURRENT_REGION}" \
        -var="github_org=tuankiet116" \
        -var="github_repo=infra-provisioning-vti" \
        -var="terraform_state_bucket=terraform-state-vti-infra-${ACCOUNT_ID}" \
        -auto-approve
    
    echo -e "${GREEN}✅ IAM Roles created successfully!${NC}"
    
    # Get the role ARNs
    DEV_ROLE_ARN=$(terraform output -raw github_actions_dev_role_arn)
    PROD_ROLE_ARN=$(terraform output -raw github_actions_prod_role_arn)
    OIDC_PROVIDER_ARN=$(terraform output -raw oidc_provider_arn)
    
    echo -e "${GREEN}📋 Role ARNs created:${NC}"
    echo -e "${BLUE}Dev Role ARN:  ${DEV_ROLE_ARN}${NC}"
    echo -e "${BLUE}Prod Role ARN: ${PROD_ROLE_ARN}${NC}"
    echo -e "${BLUE}OIDC Provider: ${OIDC_PROVIDER_ARN}${NC}"
    
    echo ""
    echo -e "${YELLOW}📝 Next Steps:${NC}"
    echo "1. Go to your GitHub repository settings"
    echo "2. Navigate to Settings > Secrets and variables > Actions"
    echo "3. Add these secrets:"
    echo "   - AWS_ROLE_ARN_DEV: ${DEV_ROLE_ARN}"
    echo "   - AWS_ROLE_ARN_PROD: ${PROD_ROLE_ARN}"
    echo "4. Remove old secrets (if they exist):"
    echo "   - AWS_ACCESS_KEY_ID"
    echo "   - AWS_SECRET_ACCESS_KEY"
    echo "   - AWS_ACCESS_KEY_ID_PROD"
    echo "   - AWS_SECRET_ACCESS_KEY_PROD"
    echo ""
    echo -e "${GREEN}🎉 Setup complete! Your GitHub Actions will now use secure OIDC authentication.${NC}"
    
else
    echo -e "${YELLOW}❌ Deployment cancelled${NC}"
    exit 0
fi
