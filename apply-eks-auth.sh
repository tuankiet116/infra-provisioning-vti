#!/bin/bash

# Script to apply aws-auth ConfigMap for EKS clusters
# This enables application team to access EKS using github-actions-deploy role

set -e

echo "=== Applying aws-auth ConfigMap to EKS clusters ==="

# Apply to DEV cluster
echo "Applying to DEV cluster..."
aws eks update-kubeconfig --region ap-southeast-2 --name DE000079-eks-dev
kubectl apply -f modules/eks/aws-auth-dev.yaml
kubectl apply -f modules/eks/github-actions-rbac.yaml
echo "✅ DEV cluster configured"

# Apply to PROD cluster  
echo "Applying to PROD cluster..."
aws eks update-kubeconfig --region ap-southeast-2 --name DE000079-eks-prod
kubectl apply -f modules/eks/aws-auth-prod.yaml
kubectl apply -f modules/eks/github-actions-rbac.yaml
echo "✅ PROD cluster configured"

echo ""
echo "=== Verification ==="
echo "Checking aws-auth ConfigMap on DEV:"
kubectl get configmap aws-auth -n kube-system --context=arn:aws:eks:ap-southeast-2:234139188789:cluster/DE000079-eks-dev

echo ""
echo "Checking aws-auth ConfigMap on PROD:"
kubectl get configmap aws-auth -n kube-system --context=arn:aws:eks:ap-southeast-2:234139188789:cluster/DE000079-eks-prod

echo ""
echo "🎉 Setup complete! Application team can now use these roles:"
echo "DEV: arn:aws:iam::234139188789:role/DE000079-dev-github-actions-deploy"
echo "PROD: arn:aws:iam::234139188789:role/DE000079-prod-github-actions-deploy"
