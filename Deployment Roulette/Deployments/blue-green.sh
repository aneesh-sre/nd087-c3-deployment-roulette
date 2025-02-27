#!/bin/bash

# Define namespaces and file paths
NAMESPACE="udacity"
GREEN_DEPLOYMENT_FILE="/apps/blue-green/green.yml"
GREEN_CONFIGMAP_FILE="/apps/blue-green/index_green_html.yml"
BLUE_DEPLOYMENT_FILE="/apps/blue-green/blue.yml"

# Apply Green ConfigMap for version GREEN
echo "Applying green ConfigMap..."
kubectl apply -f /apps/blue-green/index_green_html.yml -n $NAMESPACE

# Apply Green Deployment
echo "Deploying green version..."
kubectl apply -f /apps/blue-green/green.yml -n $NAMESPACE

# Wait for Green Deployment to complete
echo "Waiting for green deployment to complete..."
kubectl rollout status deployment/blue -n $NAMESPACE --timeout=300s

# Check if Green Deployment is ready
GREEN_PODS=$(kubectl get pods -n $NAMESPACE -l app=blue -o jsonpath='{.items[?(@.status.phase=="Running")].metadata.name}')
if [[ -z "$GREEN_PODS" ]]; then
  echo "Error: Green deployment pods are not running."
  exit 1
fi

echo "Green deployment is successful."
