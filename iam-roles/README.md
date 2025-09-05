# IAM Roles Setup for GitHub Actions

This directory contains Terraform configuration to set up IAM roles for GitHub Actions with OIDC authentication.

## 🚀 Setup Steps

### 1. Deploy IAM Roles
```bash
cd iam-roles
terraform init
terraform plan
terraform apply
```

### 2. Get Role ARNs
After applying, note the output ARNs:
```bash
terraform output github_actions_dev_role_arn
terraform output github_actions_prod_role_arn
```

### 3. Update GitHub Secrets
Replace AWS access keys with these role ARNs in GitHub repository secrets:
- Remove: `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`
- Add: `AWS_ROLE_ARN_DEV`, `AWS_ROLE_ARN_PROD`

## 🔧 What This Creates

1. **GitHub OIDC Provider** - Allows GitHub Actions to authenticate with AWS
2. **Dev IAM Role** - For development deployments (allows any branch)
3. **Prod IAM Role** - For production deployments (only main branch)
4. **Terraform Permissions Policy** - Full permissions for infrastructure management

## 🛡️ Security Features

- **No long-term credentials** - Uses temporary tokens
- **Branch restrictions** - Prod role only works from main branch
- **Repository restrictions** - Only your specific repo can assume roles
- **Principle of least privilege** - Scoped permissions for Terraform operations

## 📝 Variables

| Variable | Description | Default |
|----------|-------------|---------|
| aws_region | AWS region | ap-southeast-2 |
| github_org | GitHub organization | tuankiet116 |
| github_repo | GitHub repository | infra-provisioning-vti |
| terraform_state_bucket | S3 bucket for state | terraform-state-vti-infra |
