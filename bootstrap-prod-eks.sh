#!/bin/bash

# Bootstrap PROD EKS cluster aws-auth ConfigMap
# This script adds terraform-admin role to EKS cluster so it can manage aws-auth ConfigMap

set -e

REGION="ap-southeast-2"
CLUSTER_NAME="DE000079-eks-prod"
TERRAFORM_ADMIN_ROLE="arn:aws:iam::234139188789:role/DE000079-prod-terraform-admin"
GITHUB_ACTIONS_DEPLOY_ROLE="arn:aws:iam::234139188789:role/DE000079-prod-github-actions-deploy"

echo "=== Bootstrap EKS PROD aws-auth ConfigMap ==="
echo "Cluster: $CLUSTER_NAME"
echo "Region: $REGION"

# Get cluster creator identity
echo "=== Current AWS identity ==="
aws sts get-caller-identity

# Update kubeconfig with cluster creator permissions
echo "=== Updating kubeconfig ==="
aws eks update-kubeconfig --region $REGION --name $CLUSTER_NAME

# Check if we can access the cluster
echo "=== Testing cluster access ==="
kubectl get nodes || {
    echo "ERROR: Cannot access cluster. Make sure you're using cluster creator credentials"
    exit 1
}

# Get node role ARN for existing aws-auth
NODE_ROLE=$(aws eks describe-nodegroup --cluster-name $CLUSTER_NAME --nodegroup-name DE000079-node-group-prod --region $REGION --query 'nodegroup.nodeRole' --output text)
echo "Node role ARN: $NODE_ROLE"

# Create aws-auth ConfigMap
echo "=== Creating aws-auth ConfigMap ==="
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
data:
  mapRoles: |
    - rolearn: $NODE_ROLE
      username: system:node:{{EC2PrivateDNSName}}
      groups:
        - system:bootstrappers
        - system:nodes
    - rolearn: $TERRAFORM_ADMIN_ROLE
      username: github-actions-terraform-admin
      groups:
        - system:masters
    - rolearn: $GITHUB_ACTIONS_DEPLOY_ROLE
      username: github-actions-deploy
      groups:
        - system:authenticated
EOF

echo "=== Verifying aws-auth ConfigMap ==="
kubectl get configmap aws-auth -n kube-system -o yaml

echo "=== Bootstrap completed successfully! ==="
echo "Terraform-admin role can now manage EKS cluster via CI/CD"
