# EKS Application Deployment Setup

## Status: ✅ DEV Ready | ⚠️ PROD Pending

### What's been configured:
- **EKS Clusters**: DE000079-eks-dev ✅, DE000079-eks-prod ⚠️
- **IAM Role**: `DE000079-dev-github-actions-deploy` mapped to EKS ✅
- **RBAC Permissions**: Deploy, manage apps, services, configmaps, secrets ✅
- **aws-auth ConfigMap**: Applied to DEV ✅, PROD pending ⚠️

### Current Status:
**✅ DEV Environment Ready**
- aws-auth ConfigMap applied successfully
- Application team can use: `arn:aws:iam::234139188789:role/DE000079-dev-github-actions-deploy`

**⚠️ PROD Environment Pending**  
- aws-auth ConfigMap needs to be applied via GitHub Actions with terraform_admin role
- Local kubectl cannot access PROD cluster (credentials issue)

### For Application Team (DEV):
Role ready to use in GitHub Actions:
```yaml
- name: Configure AWS credentials  
  uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: arn:aws:iam::234139188789:role/DE000079-dev-github-actions-deploy
    aws-region: ap-southeast-2

- name: Deploy to EKS DEV
  run: |
    aws eks update-kubeconfig --name DE000079-eks-dev
    kubectl apply -f k8s/ -n your-namespace
```

### Next Step (Infrastructure Team):
Apply aws-auth to PROD cluster via GitHub Actions workflow with terraform_admin role.
