# Migration Guide: ECR Module với OIDC Authentication

## 🚨 **Vấn đề hiện tại:**

Module ECR của bạn đang sử dụng IAM role từ `modules/iam/` nhưng role này chưa được cấu hình đúng cho OIDC authentication.

## ✅ **Đã fix:**

1. **Cập nhật module IAM** để hỗ trợ OIDC đúng cách
2. **Thêm OIDC provider** trong module IAM
3. **Cập nhật assume role policy** với điều kiện đúng

## 🔄 **Migration Options:**

### **Option 1: Sử dụng module IAM đã cập nhật (RECOMMENDED)**

Giữ nguyên cấu trúc hiện tại, module ECR vẫn sử dụng `module.iam.github_actions_role_arn`:

```terraform
# environments/dev/main.tf
module "iam" {
  source      = "../../modules/iam"
  vti_id      = var.vti_id
  environment = var.environment
  account_id  = data.aws_caller_identity.current.account_id
  github_org  = var.github_org
  github_repo = var.github_repo
  
  # Tạo OIDC provider mới trong module này
  use_existing_oidc_provider = false
}

module "ecr" {
  source      = "../../modules/ecr"
  vti_id      = var.vti_id
  environment = var.environment
  read_write_arns = [
    module.iam.github_actions_role_arn  # ✅ Vẫn hoạt động
  ]
}
```

### **Option 2: Sử dụng IAM roles mới từ iam-roles/**

Cập nhật ECR module để sử dụng roles mới:

```terraform
# environments/dev/main.tf
module "ecr" {
  source      = "../../modules/ecr"
  vti_id      = var.vti_id
  environment = var.environment
  read_write_arns = [
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/github-actions-terraform-dev"
  ]
}
```

## 🎯 **Recommended Approach:**

**Sử dụng Option 1** vì:
- ✅ Không phá vỡ cấu trúc hiện có
- ✅ Module ECR không cần thay đổi
- ✅ Dễ quản lý và maintain
- ✅ Tách biệt concerns (CI/CD roles vs Application roles)

## 📋 **Steps để migration:**

### 1. **Deploy lại infrastructure:**
```bash
cd environments/dev
terraform plan
terraform apply
```

### 2. **Update GitHub Secrets:**
```bash
# Thay vì sử dụng IAM roles từ iam-roles/
# Sử dụng roles từ module IAM:
AWS_ROLE_ARN_DEV: <output từ module.iam.github_actions_role_arn>
```

### 3. **Cập nhật workflows:**
Workflows đã được cập nhật để sử dụng OIDC, chỉ cần:
- Thay `AWS_ROLE_ARN_DEV` bằng ARN từ module IAM
- Thay `AWS_ROLE_ARN_PROD` bằng ARN từ module IAM (prod)

## 🔍 **Kiểm tra sau migration:**

1. **ECR permissions:**
```bash
aws ecr describe-repositories --repository-names ${VTI_ID}-ecr-repo-${ENV}
```

2. **GitHub Actions authentication:**
- Tạo một test PR
- Xem workflow có chạy thành công không
- Kiểm tra có lỗi authentication không

## 🚨 **Lưu ý quan trọng:**

1. **Xóa iam-roles/ directory** nếu không sử dụng
2. **Module IAM hiện tại** đã được cập nhật để support OIDC
3. **ECR module không bị ảnh hưởng** - vẫn hoạt động bình thường
4. **Workflows đã được cập nhật** để sử dụng OIDC authentication
