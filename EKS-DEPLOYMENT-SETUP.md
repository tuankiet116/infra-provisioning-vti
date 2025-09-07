# EKS GitHub Actions Deployment Setup

## Tóm tắt Setup

Đã setup thành công EKS cluster với GitHub Actions integration để cho phép:

1. **Infrastructure team** quản lý EKS cluster qua terraform
2. **Application team** deploy applications qua GitHub Actions CI/CD

## Kiến trúc IAM Roles

### Infrastructure Roles
- `DE000079-dev-terraform-admin` - Full admin access cho terraform (system:masters)
- `DE000079-prod-terraform-admin` - Full admin access cho terraform (system:masters)

### Application Deployment Roles  
- `DE000079-dev-github-actions-deploy` - Deploy apps to dev cluster
- `DE000079-prod-github-actions-deploy` - Deploy apps to prod cluster

## Current Status

### ✅ Completed
- IAM roles với proper trust policies
- EKS clusters (dev & prod) 
- aws-auth ConfigMap files generated
- RBAC ClusterRole permissions defined

### ⚠️ Pending
- aws-auth ConfigMap cần apply lên clusters
- Test GitHub Actions deployment workflow

## Setup Steps

### 1. Apply aws-auth ConfigMap (Infrastructure Team)

Chạy script manual để apply aws-auth:

```bash
# For prod environment
./apply-aws-auth.sh prod

# For dev environment  
./apply-aws-auth.sh dev
```

**Note:** Script này cần được chạy bởi user có permission assume terraform admin role (thường là qua GitHub Actions)

### 2. Configure GitHub Secrets (Application Team)

Trong application repository, thêm secrets:

```
GITHUB_ACTIONS_DEPLOY_ROLE_ARN_DEV=arn:aws:iam::234139188789:role/DE000079-dev-github-actions-deploy
GITHUB_ACTIONS_DEPLOY_ROLE_ARN_PROD=arn:aws:iam::234139188789:role/DE000079-prod-github-actions-deploy
```

### 3. Add GitHub Actions Workflow

Copy `example-app-deployment.yml` vào `.github/workflows/` trong application repo.

## Testing Deployment

Sau khi setup xong, application team có thể:

1. **Deploy via GitHub Actions**: Push code → automatic deployment
2. **Manual kubectl access**: Assume deploy role để debug
3. **Namespace access**: Deploy vào namespaces như `ecommerce-vti-dev`, `ecommerce-vti-prod`

## RBAC Permissions

GitHub Actions deploy role có quyền:

- ✅ Create/update/delete pods, services, deployments
- ✅ Manage configmaps và secrets  
- ✅ Create ingresses
- ✅ View logs và events
- ✅ Manage HPA (horizontal pod autoscaler)
- ❌ No cluster-admin access (security)

## Troubleshooting

### "Server has asked for client to provide credentials"

Có nghĩa là aws-auth ConfigMap chưa được apply. Chạy script `apply-aws-auth.sh`.

### "User cannot access EKS cluster"

Check:
1. IAM role trust policy có include repo không
2. aws-auth ConfigMap có map role đúng không  
3. GitHub Actions workflow có assume đúng role không

## Next Steps

1. **Infrastructure team**: Chạy `./apply-aws-auth.sh prod` để complete setup
2. **Application team**: Test deployment với GitHub Actions workflow
3. **Monitor**: Check CloudWatch logs cho EKS cluster access
