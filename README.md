# MuchTodo - Container Assessment

Containerized deployment of the MuchTodo Golang backend API with MongoDB and Redis.

## Prerequisites

- Docker & Docker Compose
- kubectl (Kubernetes CLI)
- Kind (Kubernetes in Docker)
- go version go1.26.2 linux/amd64 (for local development)

## Project Structure

```
container-assessment/
├── MuchToDo/              # Application source code (provided)
│   ├── docker-compose.yaml
│   ├── Makefile
│   └── ...
├── Dockerfile             # Multi-stage Docker build for Go backend
├── docker-compose.yml     # Assessment: runs containerized backend + MongoDB + Redis
├── .dockerignore          # Files excluded from Docker build context
├── kubernetes/            # Kubernetes manifests
│   ├── namespace.yaml
│   ├── mongodb/
│   │   ├── mongodb-secret.yaml
│   │   ├── mongodb-configmap.yaml
│   │   ├── mongodb-pvc.yaml
│   │   ├── mongodb-deployment.yaml
│   │   └── mongodb-service.yaml
│   ├── backend/
│   │   ├── backend-secret.yaml
│   │   ├── backend-configmap.yaml
│   │   ├── backend-deployment.yaml
│   │   └── backend-service.yaml
│   └── ingress.yaml
├── scripts/               # Automation scripts
│   ├── docker-build.sh
│   ├── docker-run.sh
│   ├── k8s-deploy.sh
│   └── k8s-cleanup.sh
└── README.md              # This file
```

---

## Phase 1: Docker Setup

### 1. Generate MongoDB Keyfile

MongoDB replica sets require a keyfile for internal authentication.

```bash
cd MuchToDo
sudo bash -c 'openssl rand -base64 756 > mongodb.key'
sudo chmod 400 mongodb.key
cd ..
```

### 2. Build the Docker Image

```bash
sudo chmod +x scripts/docker-build.sh
sudo ./scripts/docker-build.sh
```

This creates a multi-stage build:
- **Stage 1 (builder):** Compiles the Go binary with dependencies cached
- **Stage 2 (runtime):** Minimal distroless image running as non-root user

### 3. Run with Docker Compose

```bash
sudo docker stop mongodb && sudo docker rm mongodb # stops and removes the /MuchTodo docker mongodb
sudo docker stop redis && sudo docker rm redis # same
sudo chmod +x scripts/docker-run.sh
sudo ./scripts/docker-run.sh
```

### 4. Verify

```bash
# Check all containers are running
sudo docker compose ps

# Test health endpoint
curl http://localhost:8080/health

# View backend logs
sudo docker compose logs -f backend

# Stop everything
sudo docker compose down
```

### Services Exposed

| Service | URL / Port | Purpose |
|---------|-----------|---------|
| Backend API | http://localhost:8080 | Golang application |
| MongoDB | localhost:27017 | Database |
| Redis | localhost:6379 | Cache |

---

## Phase 2: Kubernetes Deployment (Kind)

### 1. Create Kind Cluster

```bash
kind create cluster --name muchtodo
```

### 2. Build and Load Image into Kind

Kind clusters run inside Docker and cannot see images built on your host directly.

```bash
# Build the image
./scripts/docker-build.sh

# Load it into the Kind cluster
kind load docker-image muchtodo-backend:latest --name muchtodo
```

### 3. Deploy All Resources

```bash
chmod +x scripts/k8s-deploy.sh
./scripts/k8s-deploy.sh
```

### 4. Verify Deployment

```bash
# View all resources in the namespace
kubectl get all -n muchtodo

# Check pod status
kubectl get pods -n muchtodo

# Describe a pod for troubleshooting
kubectl describe pod <pod-name> -n muchtodo

# View backend logs
kubectl logs -f deployment/backend -n muchtodo

# View MongoDB logs
kubectl logs -f deployment/mongodb -n muchtodo
```

### 5. Access the Application

**Option A: NodePort (Simplest)**
The backend service is exposed on NodePort `30080`:
```bash
curl http://localhost:30080/health
```

**Option B: Port Forward (For debugging)**
```bash
kubectl port-forward svc/backend 8080:8080 -n muchtodo
# Then: curl http://localhost:8080/health
```

**Option C: Ingress (Requires ingress controller)**
```bash
# Add to /etc/hosts: 127.0.0.1 muchtodo.local
# Install nginx ingress controller on Kind:
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
# Wait for it to be ready, then:
curl http://muchtodo.local/health
```

### 6. Initialize MongoDB Replica Set (One-time)

After MongoDB pod is running, initialize the replica set:

```bash
kubectl exec -it deployment/mongodb -n muchtodo -- mongosh -u root -p example --authenticationDatabase admin --eval 'rs.initiate({_id: "rs0", members: [{_id: 0, host: "mongodb:27017"}]})'
```

### 7. Cleanup

```bash
chmod +x scripts/k8s-cleanup.sh
./scripts/k8s-cleanup.sh
```

This deletes the `muchtodo` namespace and the Kind cluster.

---

## Key Commands Reference

### Docker

| Command | Description |
|---------|-------------|
| `docker images` | List built images |
| `docker-compose ps` | List running containers |
| `docker-compose logs -f <service>` | Follow service logs |
| `docker-compose down -v` | Stop and remove volumes |

### Kubernetes

| Command | Description |
|---------|-------------|
| `kubectl get pods -n muchtodo` | List pods |
| `kubectl get svc -n muchtodo` | List services |
| `kubectl get ingress -n muchtodo` | List ingress rules |
| `kubectl describe pod <name> -n muchtodo` | Detailed pod info |
| `kubectl logs <pod-name> -n muchtodo` | View pod logs |
| `kubectl exec -it <pod> -n muchtodo -- /bin/sh` | Shell into pod |
| `kind get clusters` | List Kind clusters |

---

## Troubleshooting

### Pod stuck in `Pending`
```bash
kubectl describe pod <name> -n muchtodo
```
Usually caused by PVC not being bound. Check `kubectl get pvc -n muchtodo`.

### Pod shows `ImagePullBackOff`
The cluster cannot find the Docker image. Ensure you ran `kind load docker-image`.

### Backend pod keeps restarting
Check logs:
```bash
kubectl logs deployment/backend -n muchtodo
```
Common causes: cannot connect to MongoDB, missing environment variables, or failing health checks.

### MongoDB connection errors
Ensure the replica set is initialized (see Step 6 above). The backend requires a replica set connection.

### Health check fails
Verify your Go app exposes `GET /health` and returns HTTP 200.