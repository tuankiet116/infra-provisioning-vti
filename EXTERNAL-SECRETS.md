# 🔐 External Secrets Setup

## **Quick Deploy:**
```bash
# 1. Apply terraform (creates AWS secrets)
cd environments/dev && terraform apply

# 2. Install External Secrets Operator
helm repo add external-secrets https://charts.external-secrets.io
helm install external-secrets external-secrets/external-secrets \
  --namespace external-secrets-system --create-namespace

# 3. Deploy your app configs (from app repository)
kubectl apply -f path/to/your/app/manifests/
```

## **Secrets Created:**
- **Backend**: `DE000079-ecommerce-vti-backend-{env}`
- **Frontend**: `DE000079-ecommerce-vti-frontend-{env}`

## **Populate Secrets:**
```bash
aws secretsmanager put-secret-value \
  --secret-id "DE000079-ecommerce-vti-backend-dev" \
  --secret-string '{
    "database_url": "postgresql://...",
    "redis_url": "redis://...",
    "jwt_secret": "your-secret"
  }'
```

## **Verify:**
```bash
kubectl get secrets | grep -E "(backend|frontend)"
kubectl describe externalsecret backend-secrets
```
