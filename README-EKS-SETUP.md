# EKS Application Deployment Setup

## Status: ✅ Ready for Application Team

### What's been configured:
- **EKS Clusters**: DE000079-eks-dev, DE000079-eks-prod  
- **IAM Role**: `DE000079-dev-github-actions-deploy` mapped to EKS
- **RBAC Permissions**: Deploy, manage apps, services, configmaps, secrets
- **aws-auth ConfigMap**: Generated automatically by terraform

### Next Step (Infrastructure Team):
Apply the generated aws-auth ConfigMap to enable application access:

```bash
# Apply to DEV cluster
aws eks update-kubeconfig --region ap-southeast-2 --name DE000079-eks-dev
kubectl apply -f modules/eks/aws-auth-dev.yaml
kubectl apply -f modules/eks/github-actions-rbac.yaml

# Apply to PROD cluster  
aws eks update-kubeconfig --region ap-southeast-2 --name DE000079-eks-prod
kubectl apply -f modules/eks/aws-auth-prod.yaml
kubectl apply -f modules/eks/github-actions-rbac.yaml
```

### For Application Team:
After aws-auth is applied, use this role in GitHub Actions:
- **Dev**: `arn:aws:iam::234139188789:role/DE000079-dev-github-actions-deploy`
- **Prod**: `arn:aws:iam::234139188789:role/DE000079-prod-github-actions-deploy`

Example workflow:
```yaml
- name: Configure AWS credentials
  uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: ${{ secrets.GITHUB_ACTIONS_DEPLOY_ROLE_ARN_DEV }}
    aws-region: ap-southeast-2

- name: Deploy to EKS
  run: |
    aws eks update-kubeconfig --name DE000079-eks-dev
    kubectl apply -f k8s/ -n your-namespace
```
