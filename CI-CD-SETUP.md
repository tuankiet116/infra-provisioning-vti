# GitHub Actions CI/CD Setup Guide

This repository contains GitHub Actions workflows for automated Terraform infrastructure management.

## 🚀 Workflows Overview

### 1. Terraform Plan & Apply (`terraform-plan-apply.yml`)

**Triggers:**
- **Pull Request**: Runs `terraform plan` when PR is opened/updated
- **Push to main/master**: Runs `terraform apply` when PR is merged

**Features:**
- ✅ Detects changes in specific environments (dev/prod)
- ✅ Runs parallel plans for changed environments
- ✅ Posts plan output as PR comments
- ✅ Format checking and validation
- ✅ Separate AWS credentials for dev/prod
- ✅ Auto-apply on merge to main branch

### 2. Terraform Destroy (`terraform-destroy.yml`)

**Triggers:**
- **Manual execution only** via GitHub Actions UI

**Features:**
- ✅ Environment selection (dev/prod)
- ✅ Confirmation requirement ("destroy" keyword)
- ✅ Manual approval step with detailed destroy plan
- ✅ Safety checks and notifications

## 🔧 Setup Instructions

### 1. GitHub Repository Secrets

Configure the following secrets in your GitHub repository settings (`Settings > Secrets and variables > Actions`):

#### For Dev Environment:
```
AWS_ACCESS_KEY_ID         # AWS Access Key for Dev
AWS_SECRET_ACCESS_KEY     # AWS Secret Key for Dev
```

#### For Prod Environment:
```
AWS_ACCESS_KEY_ID_PROD    # AWS Access Key for Prod
AWS_SECRET_ACCESS_KEY_PROD # AWS Secret Key for Prod
```

### 2. GitHub Environments

Create the following environments in your repository (`Settings > Environments`):

- `dev` - For development deployments
- `prod` - For production deployments  
- `dev-destroy` - For development destroy operations
- `prod-destroy` - For production destroy operations

**Recommended Protection Rules:**
- **prod**: Require reviewers (at least 1)
- **prod-destroy**: Require reviewers (at least 2)

### 3. AWS IAM Setup

Create IAM users/roles with appropriate permissions for Terraform operations:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:*",
        "eks:*",
        "iam:*",
        "ecr:*",
        "vpc:*",
        "s3:*",
        "dynamodb:*"
      ],
      "Resource": "*"
    }
  ]
}
```

## 📝 Usage Guide

### Normal Development Workflow

1. **Create a feature branch:**
   ```bash
   git checkout -b feature/new-infrastructure
   ```

2. **Make changes to Terraform files:**
   - Modify files in `environments/dev/` or `environments/prod/`
   - Update modules in `modules/`

3. **Create Pull Request:**
   - GitHub Actions will automatically run `terraform plan`
   - Plan output will be posted as PR comment
   - Review the plan carefully

4. **Merge to main:**
   - After PR approval, merge to main/master
   - GitHub Actions will automatically run `terraform apply`

### Emergency Destroy Workflow

1. **Go to Actions tab** in GitHub repository

2. **Select "Terraform Destroy" workflow**

3. **Click "Run workflow"**

4. **Select environment** (dev/prod)

5. **Type "destroy"** in confirmation field

6. **Wait for manual approval** (will create an issue)

7. **Approve the issue** to proceed with destroy

## 🎯 Workflow Features

### Change Detection
- Only runs plans/applies for environments with actual changes
- Monitors both environment configs and shared modules

### Security Features
- Separate AWS credentials for each environment
- Environment protection rules
- Manual approval for destroy operations
- Confirmation keywords required

### PR Integration
- Automatic plan comments on pull requests
- Plan output truncation for large outputs
- Status checks prevent merging on plan failures

## 🛠 Customization

### Terraform Version
Update `TF_VERSION` in workflow files:
```yaml
env:
  TF_VERSION: '1.5.0'  # Change this version
```

### AWS Region
Update `AWS_REGION` in workflow files:
```yaml
env:
  AWS_REGION: 'ap-southeast-2'  # Change this region
```

### Branch Protection
Modify trigger branches in workflow files:
```yaml
on:
  pull_request:
    branches: [ main, master ]  # Add/remove branches
  push:
    branches: [ main, master ]  # Add/remove branches
```

## 🚨 Important Notes

### Destroy Workflow Safety
- **IRREVERSIBLE**: Destroy operations cannot be undone
- **Manual Approval**: Always required for destroy operations
- **Confirmation**: Must type "destroy" exactly
- **Review**: Always review destroy plan before approval

### State Management
- Ensure Terraform state is properly configured with remote backend
- State files should be stored in S3 with DynamoDB locking
- Never commit `.tfstate` files to repository

### Environment Variables
- Use environment-specific `.tfvars` files
- Store sensitive values in GitHub Secrets
- Never commit sensitive information to repository

## 📞 Troubleshooting

### Common Issues

1. **Authentication Errors:**
   - Verify AWS credentials in GitHub Secrets
   - Check IAM permissions for Terraform operations

2. **Plan Failures:**
   - Check Terraform syntax and formatting
   - Verify module dependencies
   - Review AWS resource limits

3. **Apply Failures:**
   - Check AWS service limits
   - Verify resource naming conflicts
   - Review Terraform state consistency

### Getting Help

- Check workflow logs in GitHub Actions tab
- Review Terraform plan output in PR comments
- Verify AWS resource status in AWS Console
