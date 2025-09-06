#!/bin/bash

# Script để setup infrastructure cho AWS account mới
# Usage: ./setup-new-aws-account.sh <environment>

set -e

ENVIRONMENT=${1:-dev}

echo "🚀 Setting up infrastructure for NEW AWS account..."
echo "Environment: $ENVIRONMENT"

# Step 1: Setup shared resources (OIDC Provider)
echo "📦 Step 1: Creating shared resources (OIDC Provider)..."
cd shared-resources
terraform init
terraform apply -auto-approve

# Step 2: Setup environment infrastructure  
echo "🏗️  Step 2: Creating $ENVIRONMENT environment..."
cd ../environments/$ENVIRONMENT
terraform init
terraform apply -auto-approve

echo "✅ Setup completed successfully!"
echo "🎯 GitHub Actions can now deploy to this AWS account"

# Step 3: Display important information
echo ""
echo "📋 Important Information:"
echo "========================="
echo "🔑 Add these secrets to GitHub repository:"
echo "AWS_ROLE_ARN_${ENVIRONMENT^^}: $(terraform output -raw github_actions_role_arn)"
echo "🏷️  ECR Repository: $(terraform output -raw ecr_repository_url)"
echo "🎪 EKS Cluster: $(terraform output -raw eks_cluster_name)"
