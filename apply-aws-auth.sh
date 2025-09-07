#!/bin/bash

# Script to manually apply aws-auth ConfigMap for EKS cluster
# This script should be run by someone who has permission to assume terraform admin role

set -e

ENVIRONMENT="${1:-prod}"
CLUSTER_NAME="DE000079-eks-${ENVIRONMENT}"
REGION="ap-southeast-2"
TERRAFORM_ADMIN_ROLE="arn:aws:iam::234139188789:role/DE000079-${ENVIRONMENT}-terraform-admin"

echo "=== Applying aws-auth ConfigMap for ${ENVIRONMENT} environment ==="
echo "Cluster: ${CLUSTER_NAME}"
echo "Region: ${REGION}"
echo "Using role: ${TERRAFORM_ADMIN_ROLE}"
echo

# Check if aws-auth file exists
AUTH_FILE="modules/eks/aws-auth-${ENVIRONMENT}.yaml"
RBAC_FILE="modules/eks/github-actions-rbac.yaml"

if [[ ! -f "$AUTH_FILE" ]]; then
    echo "Error: aws-auth file not found: $AUTH_FILE"
    echo "Please run terraform plan first to generate the file"
    exit 1
fi

if [[ ! -f "$RBAC_FILE" ]]; then
    echo "Error: RBAC file not found: $RBAC_FILE"
    exit 1
fi

echo "=== Assuming terraform admin role ==="
CREDS=$(aws sts assume-role \
    --role-arn "$TERRAFORM_ADMIN_ROLE" \
    --role-session-name "manual-aws-auth-setup" \
    --output json)

if [[ $? -ne 0 ]]; then
    echo "Error: Failed to assume terraform admin role"
    echo "Make sure your user has permission to assume: $TERRAFORM_ADMIN_ROLE"
    exit 1
fi

echo "✓ Successfully assumed terraform admin role"

# Export credentials
export AWS_ACCESS_KEY_ID=$(echo "$CREDS" | jq -r '.Credentials.AccessKeyId')
export AWS_SECRET_ACCESS_KEY=$(echo "$CREDS" | jq -r '.Credentials.SecretAccessKey')
export AWS_SESSION_TOKEN=$(echo "$CREDS" | jq -r '.Credentials.SessionToken')

echo "=== Updating kubeconfig ==="
aws eks update-kubeconfig --region "$REGION" --name "$CLUSTER_NAME"
echo "✓ Updated kubeconfig for cluster: $CLUSTER_NAME"

echo "=== Applying aws-auth ConfigMap ==="
kubectl apply -f "$AUTH_FILE"
echo "✓ Applied aws-auth ConfigMap"

echo "=== Applying GitHub Actions RBAC ==="
kubectl apply -f "$RBAC_FILE"
echo "✓ Applied GitHub Actions RBAC"

echo "=== Verification ==="
echo "Checking aws-auth ConfigMap:"
kubectl get configmap aws-auth -n kube-system -o yaml

echo
echo "Checking RBAC resources:"
kubectl get clusterrole github-actions-deploy
kubectl get clusterrolebinding github-actions-deploy

echo
echo "=== Setup Complete! ==="
echo "GitHub Actions can now deploy to EKS cluster using role:"
echo "arn:aws:iam::234139188789:role/DE000079-${ENVIRONMENT}-github-actions-deploy"
