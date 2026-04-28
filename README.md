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
sudo chmod +x scripts/k8s-deploy.sh
./scripts/k8s-deploy.sh
```
This script will:
1. Create a Kind cluster named `muchtodo`.
2. Load your local image into the cluster.
3. Apply all manifests in the correct order.

### 2. Verify Kubernetes Resources
```bash
# Check all resources in the namespace
kubectl get all -n muchtodo

# Test via NodePort
curl http://localhost:30080/health
```

### 3. Access via Ingress (Optional)
Add `127.0.0.1 muchtodo.local` to your `/etc/hosts` and follow Phase 2, Step 5 in the previous documentation for Nginx Ingress setup.

---

## Cleanup
```bash
sudo chmod +x scripts/k8s-cleanup.sh
./scripts/k8s-cleanup.sh
```

## Key Assessment Features
- **Optimized Dockerfile**: Multi-stage, non-root user, health check, and BuildKit caching.
- **Resilient Compose**: Dependency ordering with `service_healthy`.
- **K8s High Availability**: Backend deployment with 2 replicas and resource limits.
- **K8s Health Management**: Liveness and Readiness probes.
- **Persistence**: MongoDB uses PersistentVolumeClaims for data durability.

## Troubleshooting

### MongoDB connection errors
Ensure the replica set is initialized (see Step 6 above). The backend requires a replica set connection.

### Health check fails
Verify your Go app exposes `GET /health` and returns HTTP 200.