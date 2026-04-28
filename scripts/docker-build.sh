#!/bin/bash
set -e

echo "=== Building MuchTodo Backend Docker Image ==="
export DOCKER_BUILDKIT=1
sudo docker build -t muchtodo-backend:latest .
echo "=== Build Complete ==="
echo ""
echo "Image: muchtodo-backend:latest"
echo "Run 'docker images | grep muchtodo' to verify"