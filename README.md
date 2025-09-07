# 🏗️ VTI E-commerce Infrastructure

> **Terraform Infrastructure for VTI E-commerce Platform**  
> AWS EKS + ECR + External Secrets Operator + GitHub Actions CI/CD

## 📋 **Quick Start**

### **Prerequisites:**
- AWS CLI configured
- Terraform >= 1.13.1
- kubectl for K8s management

### **Deploy Infrastructure:**
```bash
# 1. Deploy Development
cd environments/dev
terraform init
terraform plan
terraform apply

# 2. Deploy Production  
cd ../prod
terraform init
terraform plan
terraform apply
```

### **Deploy External Secrets Operator:**
```bash
# Install ESO via Helm
helm repo add external-secrets https://charts.external-secrets.io
helm install external-secrets external-secrets/external-secrets \
  --namespace external-secrets-system --create-namespace

# Apply K8s manifests (from your application repository)
kubectl apply -f path/to/your/app/k8s-manifests/
```

---

## 🏛️ **Architecture Overview**

### **Environments:**
- **Development**: `DE000079-eks-dev` 
- **Production**: `DE000079-eks-prod`

### **Components:**
- **EKS Clusters**: Kubernetes orchestration
- **ECR Repositories**: Container image registry
- **External Secrets**: AWS Secrets Manager ↔ K8s integration
- **GitHub Actions**: CI/CD automation with OIDC

### **Security:**
- ✅ OIDC authentication (no AWS keys in CI/CD)
- ✅ Environment-separated secrets
- ✅ IAM roles with least privilege
- ✅ Private subnets for workloads

---

## 🔐 **Secrets Management**

### **Secret Types:**
1. **Backend Secrets**: `DE000079-ecommerce-vti-backend-{env}`
   - Database URLs, API keys, JWT secrets
2. **Frontend Secrets**: `DE000079-ecommerce-vti-frontend-{env}`  
   - API endpoints, analytics IDs, public keys

### **How it Works:**
1. **AWS Secrets Manager** stores actual secret values
2. **External Secrets Operator** syncs to Kubernetes secrets
3. **OIDC authentication** eliminates need for AWS credentials

### **Populate Secrets:**
```bash
# Example: Add backend secrets
aws secretsmanager put-secret-value \
  --secret-id "DE000079-ecommerce-vti-backend-dev" \
  --secret-string '{
    "database_url": "postgresql://...",
    "redis_url": "redis://...",
    "jwt_secret": "your-jwt-secret",
    "api_key": "your-api-key"
  }'
```

---

## 🚀 **CI/CD Integration**

### **GitHub Actions Outputs:**
```yaml
# Available in CI/CD workflows via terraform outputs
- name: Get Infrastructure Info
  run: |
    echo "EKS_CLUSTER=${{ needs.terraform.outputs.eks_cluster_name }}"
    echo "ECR_REPO=${{ needs.terraform.outputs.ecr_repository_url }}"
    echo "BACKEND_SECRET=${{ needs.terraform.outputs.backend_secret_name }}"
    echo "FRONTEND_SECRET=${{ needs.terraform.outputs.frontend_secret_name }}"
```

### **OIDC Setup:**
- **GitHub Actions Role**: `DE000079-{env}-github-actions`
- **Repository**: `tuankiet116/infra-provisioning-vti`
- **Permissions**: EKS, ECR, Secrets Manager access

---

## 📂 **Project Structure**

```
├── environments/
│   ├── dev/          # Development environment
│   └── prod/         # Production environment
├── modules/
│   ├── ecr/          # Container registry
│   ├── eks/          # Kubernetes cluster
│   ├── external-secrets/  # Secrets management
│   ├── iam/          # IAM roles & policies
│   └── networking/   # VPC, subnets, security groups
└── shared-resources/ # Cross-environment resources
```

> **Note**: K8s manifests và application deployment configs nên được đặt trong application repository của bạn, không phải infrastructure repository này.

---

## 🔧 **Common Tasks**

### **Update Secrets:**
```bash
# Update backend secret
aws secretsmanager update-secret \
  --secret-id "DE000079-ecommerce-vti-backend-dev" \
  --secret-string '{"new_key": "new_value"}'

# Secrets auto-sync to K8s within 30s
kubectl get secrets backend-secrets -o yaml
```

### **Scale EKS Nodes:**
```bash
# Edit terraform.tfvars
echo 'node_desired_capacity = 3' >> environments/dev/terraform.tfvars
terraform apply
```

### **Deploy Application:**
```bash
# Use ECR repo from terraform output
docker tag my-app:latest $(terraform output ecr_repository_url):latest
docker push $(terraform output ecr_repository_url):latest

# Deploy to EKS
kubectl set image deployment/my-app container=$(terraform output ecr_repository_url):latest
```

---

## 🔍 **Troubleshooting**

### **External Secrets Not Syncing:**
```bash
# Check ESO pods
kubectl get pods -n external-secrets-system

# Check secret store connection
kubectl describe secretstore aws-secrets-manager

# Check external secret status
kubectl describe externalsecret backend-secrets
```

### **CI/CD Issues:**
```bash
# Verify OIDC setup
aws sts get-caller-identity

# Check GitHub Actions role
aws iam get-role --role-name DE000079-dev-github-actions
```

### **EKS Access Issues:**
```bash
# Update kubeconfig
aws eks update-kubeconfig --region ap-southeast-2 --name DE000079-eks-dev

# Verify access
kubectl get nodes
```

---

## ⚡ **Key Features**

- **🔒 Zero-Trust Security**: OIDC authentication, no hardcoded credentials
- **🌍 Multi-Environment**: Identical dev/prod setup with environment separation  
- **📦 Container-Ready**: ECR integration with EKS for seamless deployments
- **🔄 GitOps-Friendly**: Infrastructure as code with GitHub Actions integration
- **📊 Observable**: CloudWatch integration for monitoring and logging
- **⚖️ Scalable**: Auto-scaling node groups and horizontal pod scaling
- **🏗️ Separation of Concerns**: Infrastructure repo tạo AWS resources, Application repo handle K8s deployments

---

## 📞 **Support**

For infrastructure issues or questions:
1. Check existing documentation above
2. Review terraform plan output for changes
3. Validate AWS permissions for your role
4. Check Kubernetes events: `kubectl get events --sort-by='.lastTimestamp'`

**Infrastructure Owner**: VTI DevOps Team  
**Project ID**: `DE000079`  
**Last Updated**: September 2025
