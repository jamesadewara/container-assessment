#!/bin/bash
set -e

echo "=== Cleaning Up Kubernetes Resources ==="
sudo kubectl delete namespace muchtodo || true

echo ""
echo "=== Deleting Kind Cluster ==="
sudo kind delete cluster --name muchtodo || true

echo ""
echo "=== Cleanup Complete ==="