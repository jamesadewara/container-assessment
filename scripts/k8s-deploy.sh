#!/bin/bash
set -e

echo "=== Creating Kind Cluster (if not exists) ==="
sudo kind create cluster --name muchtodo || echo "Cluster already exists"

echo ""
echo "=== Loading Docker Image into Kind ==="
sudo kind load docker-image muchtodo-backend:latest --name muchtodo

echo ""
echo "=== Deploying to Kubernetes ==="

# Apply in order: namespace first, then configs, then workloads
sudo kubectl apply -f kubernetes/namespace.yaml

# MongoDB resources
sudo kubectl apply -f kubernetes/mongodb/mongodb-secret.yaml
sudo kubectl apply -f kubernetes/mongodb/mongodb-configmap.yaml
sudo kubectl apply -f kubernetes/mongodb/mongodb-pvc.yaml
sudo kubectl apply -f kubernetes/mongodb/mongodb-deployment.yaml
sudo kubectl apply -f kubernetes/mongodb/mongodb-service.yaml

# Backend resources
sudo kubectl apply -f kubernetes/backend/backend-secret.yaml
sudo kubectl apply -f kubernetes/backend/backend-configmap.yaml
sudo kubectl apply -f kubernetes/backend/backend-deployment.yaml
sudo kubectl apply -f kubernetes/backend/backend-service.yaml

# Ingress
sudo kubectl apply -f kubernetes/ingress.yaml

echo ""
echo "=== Deployment Complete ==="
echo ""
echo "Check pods: sudo kubectl get pods -n muchtodo"
echo "Check services: sudo kubectl get svc -n muchtodo"
echo "Access app: http://localhost:30080 (NodePort)"