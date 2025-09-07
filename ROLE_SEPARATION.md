# IAM Role Separation Strategy

## Overview

Dự án đã được refactor để tách biệt vai trò IAM theo nguyên tắc **Principle of Least Privilege** và **Separation of Concerns**.

## Role Architecture

```
┌─────────────────────┐    ┌──────────────────────┐    ┌─────────────────────┐
│ Terraform Admin     │    │ GitHub Actions       │    │ External Secrets    │
│ Role                │    │ Deploy Role          │    │ IRSA Role           │
│                     │    │                      │    │                     │
│ - IAM Full Access   │    │ - ECR PowerUser      │    │ - Secrets Manager   │
│ - VPC Full Access   │    │ - EKS Read Only      │    │   Read Access       │
│ - EKS Full Access   │    │ - CloudWatch Read    │    │                     │
│ - EC2 Full Access   │    │                      │    │                     │
│ - CloudWatch Full   │    │                      │    │                     │
│ - S3 State Access   │    │                      │    │                     │
└─────────────────────┘    └──────────────────────┘    └─────────────────────┘
```

## Roles Description

### 1. Terraform Admin Role (`terraform_admin`)
**Purpose**: Infrastructure management và tạo/sửa IAM resources  
**When to use**: 
- Terraform apply cho infrastructure changes
- Tạo/sửa IAM roles, policies
- VPC, EKS cluster provisioning

**Permissions**:
- `IAMFullAccess`
- `AmazonVPCFullAccess` 
- `AmazonEKSClusterPolicy`
- `AmazonEC2FullAccess`
- `CloudWatchFullAccess`
- Custom S3 state access

**GitHub Condition**: Chỉ main/master branch
```json
{
  "StringLike": {
    "token.actions.githubusercontent.com:sub": [
      "repo:org/repo:ref:refs/heads/master",
      "repo:org/repo:ref:refs/heads/main"
    ]
  }
}
```

### 2. GitHub Actions Deploy Role (`github_actions_deploy`)
**Purpose**: Application deployment only  
**When to use**:
- Build và push Docker images
- Deploy applications lên EKS
- CI/CD workflows

**Permissions**:
- `AmazonEC2ContainerRegistryPowerUser`
- EKS describe/list permissions only
- `CloudWatchReadOnlyAccess`

**GitHub Condition**: Tất cả branches và PRs
```json
{
  "StringLike": {
    "token.actions.githubusercontent.com:sub": "repo:org/repo:*"
  }
}
```

### 3. External Secrets IRSA Role (`external_secrets_irsa`)
**Purpose**: Cho External Secrets Operator truy cập AWS Secrets Manager  
**When to use**: Tự động được assume bởi ServiceAccount trong EKS

**Permissions**:
- `secretsmanager:GetSecretValue`
- `secretsmanager:DescribeSecret`
- `secretsmanager:ListSecrets`

**Trust Policy**: EKS OIDC provider với ServiceAccount specific

## Usage Guide

### For Infrastructure Changes
```bash
# Sử dụng terraform_admin_role_arn
export AWS_ROLE_ARN=$(terraform output -raw terraform_admin_role_arn)
# Chạy terraform apply
```

### For Application Deployment
```bash
# Sử dụng github_actions_deploy_role_arn  
export AWS_ROLE_ARN=$(terraform output -raw github_actions_deploy_role_arn)
# Chạy docker build, push, kubectl apply
```

### For External Secrets ServiceAccount
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: external-secrets-sa
  namespace: ecommerce-vti-dev
  annotations:
    eks.amazonaws.com/role-arn: <external_secrets_role_arn>
```

## Migration Steps

1. **Deploy new roles**: `terraform apply` sẽ tạo các role mới
2. **Update CI/CD workflows**: Thay đổi role ARN trong GitHub Actions
3. **Update ServiceAccount**: Sử dụng `external_secrets_role_arn` cho annotation
4. **Test permissions**: Verify từng role hoạt động đúng scope
5. **Remove old role**: Sau khi confirm, có thể xóa role cũ

## Security Benefits

✅ **Least Privilege**: Mỗi role chỉ có quyền cần thiết  
✅ **Blast Radius Reduction**: Lỗi ở một role không ảnh hưởng toàn bộ  
✅ **Branch Protection**: Admin role chỉ dùng cho main branch  
✅ **Audit Trail**: Dễ track ai làm gì qua role name  
✅ **Compliance**: Tuân thủ AWS security best practices  

## Troubleshooting

### Role không có quyền
```bash
# Check role permissions
aws iam list-attached-role-policies --role-name <role-name>
aws iam list-role-policies --role-name <role-name>
```

### ServiceAccount không assume được role
```bash
# Check trust policy
aws iam get-role --role-name <role-name> --query 'Role.AssumeRolePolicyDocument'

# Check ServiceAccount annotation
kubectl get sa external-secrets-sa -o yaml
```

### GitHub Actions không thể assume role
- Verify repository name trong trust policy
- Check branch condition nếu dùng admin role
- Confirm OIDC provider exists và đúng thumbprint
