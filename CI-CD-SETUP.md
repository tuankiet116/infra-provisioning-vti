# 🚀 CI/CD Setup Guide

## **GitHub Actions Integration**

### **1. OIDC Role Created:**
- **Dev**: `DE000079-dev-github-actions`
- **Prod**: `DE000079-prod-github-actions`

### **2. Repository Configuration:**
- **Repo**: `tuankiet116/infra-provisioning-vti`
- **Branch**: `master`

### **3. Workflow Example:**
```yaml
name: Deploy
on:
  push:
    branches: [master]

jobs:
  deploy:
    runs-on: ubuntu-latest
    permissions:
      id-token: write
      contents: read
    steps:
    - uses: actions/checkout@v4
    
    - name: Configure AWS
      uses: aws-actions/configure-aws-credentials@v4
      with:
        role-to-assume: arn:aws:iam::234139188789:role/DE000079-dev-github-actions
        aws-region: ap-southeast-2
    
    - name: Deploy to EKS
      run: |
        aws eks update-kubeconfig --name DE000079-eks-dev
        # Apply your application's K8s manifests
        kubectl apply -f path/to/your/app/manifests/
```

### **4. Available Outputs:**
- `eks_cluster_name`: EKS cluster for deployment
- `ecr_repository_url`: Container registry URL  
- `backend_secret_name`: Backend secrets reference
- `frontend_secret_name`: Frontend secrets reference
