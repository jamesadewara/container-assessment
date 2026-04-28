# MuchTodo - Container Assessment

Containerized deployment of the MuchTodo Golang backend API with MongoDB and Redis. This project is optimized for speed and security using multi-stage builds and Docker BuildKit.

## Build Optimization Note
This project uses **Docker BuildKit cache mounts** to drastically reduce build times. The first build will populate the cache; subsequent builds where only source code changes will finish in seconds.

## Prerequisites

- Docker & Docker Compose (BuildKit enabled)
- kubectl (Kubernetes CLI)
- Kind (Kubernetes in Docker)
- go version 1.24+ (for local development)

## Project Structure

```
container-assessment/
├── MuchToDo/              # Application source code
├── Dockerfile             # Optimized multi-stage build
├── docker-compose.yml     # Local dev setup with health checks
├── .dockerignore          # Excluded files
├── kind-config.yaml       # Kind cluster port mapping config
├── kubernetes/            # K8s manifests
│   ├── namespace.yaml     # Dedicated 'muchtodo' namespace
│   ├── mongodb/           # MongoDB resources (PVC, Secret, ConfigMap)
│   └── backend/           # Backend resources (Replicas, Probes, Limits)
├── scripts/               # Automation scripts
└── README.md
```

---

## Phase 1: Docker Setup (Local Development)

### 1. Build the Optimized Image
```bash
sudo chmod +x scripts/docker-build.sh
./scripts/docker-build.sh
```

### 2. Run with Docker Compose
```bash
sudo chmod +x scripts/docker-run.sh
./scripts/docker-run.sh
```
The backend will wait for MongoDB and Redis to be healthy before starting.

### 3. Verify
- Health check: `curl http://localhost:8080/health`
- Status: `docker compose ps`

---

## Phase 2: Kubernetes Deployment (Kind)

### 1. Create Cluster and Deploy
```bash
sudo kind load docker-image muchtodo-backend:latest --name muchtodo
sudo ./scripts/k8s-deploy.sh
```
This script will:
1. Create a Kind cluster named `muchtodo`.
2. Load your local image into the cluster.
3. Apply all manifests in the correct order.

### 2. Verify Kubernetes Resources
```bash
# Check all resources in the namespace
kubectl get all -n muchtodo

# Show only Deployments
sudo kubectl get deployments -n muchtodo

# Check Pod status (to see if they are Running)
sudo kubectl get pod,svc,ing,deploy -n muchtodo

# Test via NodePort
curl http://localhost:30080/health
```

### 3. Access the Application

#### NodePort (Direct Access)
The backend service is exposed on NodePort `30080`.
```bash
curl http://localhost:30080/health
```
---

## Cleanup
```bash
sudo chmod +x scripts/k8s-cleanup.sh
./scripts/k8s-cleanup.sh
```