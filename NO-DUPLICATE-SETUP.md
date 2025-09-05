# 🚀 Final Setup Guide - No Duplicate Roles

## ✅ **Giải pháp hoàn chỉnh cho vấn đề duplicate:**

### 🏗️ **Cấu trúc mới:**

```
📁 shared-resources/          # ← OIDC Provider (1 lần duy nhất)
   ├── main.tf               # GitHub OIDC Provider
   └── provider.tf           # Terraform backend config

📁 environments/
   ├── dev/                  # ← IAM Role riêng cho dev
   └── prod/                 # ← IAM Role riêng cho prod

📁 modules/iam/               # ← Chỉ tạo roles, không tạo OIDC provider
```

### 🔄 **Quy trình deploy:**

1. **Shared Resources** (1 lần) → OIDC Provider
2. **Dev Environment** → IAM Role cho dev
3. **Prod Environment** → IAM Role cho prod

## 🚫 **Không còn duplicate vì:**

- ✅ **OIDC Provider**: Chỉ tạo 1 lần trong `shared-resources/`
- ✅ **IAM Roles**: Mỗi environment có role riêng với tên khác nhau:
  - Dev: `${vti_id}-dev-github-actions` 
  - Prod: `${vti_id}-prod-github-actions`
- ✅ **ECR Module**: Vẫn hoạt động bình thường với `module.iam.github_actions_role_arn`

## 🎯 **Deployment Steps:**

### **Option 1: Tự động (Recommended)**
```bash
./deploy-infrastructure.sh
```

### **Option 2: Thủ công**
```bash
# 1. Deploy shared resources first
cd shared-resources
terraform init && terraform apply

# 2. Deploy dev environment
cd ../environments/dev  
terraform init && terraform apply

# 3. Deploy prod environment
cd ../environments/prod
terraform init && terraform apply
```

## 📋 **Lấy Role ARNs:**

```bash
# Dev environment
cd environments/dev
terraform output github_actions_role_arn

# Prod environment  
cd environments/prod
terraform output github_actions_role_arn
```

## ⚙️ **GitHub Secrets:**

```bash
# Thay thế secrets cũ bằng:
AWS_ROLE_ARN_DEV=arn:aws:iam::ACCOUNT:role/DE000079-dev-github-actions
AWS_ROLE_ARN_PROD=arn:aws:iam::ACCOUNT:role/DE000079-prod-github-actions
```

## 🔍 **Kiểm tra không duplicate:**

### **OIDC Provider** (chỉ có 1):
```bash
aws iam list-open-id-connect-providers
```

### **IAM Roles** (2 roles khác tên):
```bash
aws iam list-roles --query 'Roles[?contains(RoleName, `github-actions`)]'
```

## 🎉 **Kết quả:**

- ✅ **ECR Module**: Không bị ảnh hưởng, vẫn hoạt động
- ✅ **No Duplicate**: OIDC Provider chỉ tạo 1 lần
- ✅ **Secure**: Mỗi environment có role riêng với permissions phù hợp
- ✅ **GitHub Actions**: Sử dụng OIDC authentication an toàn
- ✅ **Scalable**: Dễ thêm environments mới (staging, test, ...)

## 🚨 **Migration từ setup cũ:**

1. **Xóa `iam-roles/` directory** (không cần nữa)
2. **Deploy shared-resources** trước
3. **Re-deploy environments** để update roles
4. **Update GitHub Secrets** với ARNs mới
5. **Test GitHub Actions workflows**

**Hoàn tất! Không còn lo về duplicate roles.** 🎯
