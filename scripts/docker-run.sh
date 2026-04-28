#!/bin/bash
set -e

echo "=== Starting MuchTodo with Docker Compose ==="
sudo docker compose up -d --build
echo ""
echo "=== Services Starting ==="
echo "Backend API: http://localhost:8080"
echo "MongoDB: localhost:27017"
echo "Redis: localhost:6379"
echo ""
echo "Check status: docker compose ps"
echo "View logs: docker compose logs -f backend"