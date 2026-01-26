# Container Orchestration with Kubernetes

While Docker Compose is excellent for local development and simple multi-container applications, the industry standard for managing containerized applications in production is **Kubernetes (K8s)**. Kubernetes is a powerful, extensible, open-source platform for automating the deployment, scaling, and management of containerized applications.

## 1. Why Kubernetes?

*   **High Availability:** Kubernetes can automatically restart containers that fail and reschedule them on healthy nodes.
*   **Scalability:** You can scale your application up or down with a single command or automatically based on CPU usage.
*   **Self-Healing:** Kubernetes constantly monitors the state of your cluster and makes sure it matches your desired state.
*   **Service Discovery and Load Balancing:** Kubernetes gives containers their own IP addresses and a single DNS name for a set of containers, and can load-balance across them.
*   **Automated Rollouts and Rollbacks:** You can describe the desired state for your deployed containers, and Kubernetes will change the actual state to the desired state at a controlled rate.

## 2. Core Kubernetes Concepts

*   **Cluster:** A set of nodes that run containerized applications. A cluster has at least one master node and several worker nodes.
*   **Node:** A worker machine in Kubernetes, which can be a VM or a physical machine.
*   **Pod:** The smallest and simplest unit in the Kubernetes object model that you create or deploy. A Pod represents a running process on your cluster and can contain one or more containers.
*   **Service:** An abstract way to expose an application running on a set of Pods. Kubernetes Services provide a stable endpoint (IP address and port) for a set of Pods.
*   **Deployment:** A controller that manages the lifecycle of Pods. You describe a desired state in a Deployment, and the Deployment Controller changes the actual state to the desired state at a controlled rate.
*   **Ingress:** An API object that manages external access to the services in a cluster, typically HTTP. Ingress can provide load balancing, SSL termination, and name-based virtual hosting.
*   **ConfigMap:** An API object used to store non-confidential data in key-value pairs. Pods can consume ConfigMaps as environment variables, command-line arguments, or as configuration files in a volume.
*   **Secret:** Similar to a ConfigMap, but intended for sensitive data like passwords, OAuth tokens, and ssh keys.
*   **PersistentVolume (PV) and PersistentVolumeClaim (PVC):** A framework for abstracting storage. A `PersistentVolume` is a piece of storage in the cluster, and a `PersistentVolumeClaim` is a request for storage by a user.

## 3. Setting up a Local Kubernetes Cluster

For development and learning, you can set up a single-node Kubernetes cluster on your local machine.

*   **Docker Desktop:** The easiest way to get a local Kubernetes cluster on Windows and macOS. Simply enable Kubernetes in the Docker Desktop settings.
*   **Minikube:** A tool that runs a single-node Kubernetes cluster inside a VM on your local machine. It's a great option for Linux, macOS, and Windows.
*   **kind (Kubernetes in Docker):** A tool for running local Kubernetes clusters using Docker containers as "nodes."

For this guide, we assume you are using the Kubernetes cluster provided by **Docker Desktop**.

## 4. Deploying Our Full-Stack Application to Kubernetes

We will now deploy the same full-stack To-Do application from the "Real-world Projects" section to Kubernetes. Instead of a single `docker-compose.yml` file, we will create separate YAML manifest files for each Kubernetes object.

**Recommended Directory Structure:**

```
.
├── backend-deployment.yaml
├── frontend-deployment.yaml
├── postgres-deployment.yaml
├── ingress.yaml
└── ... (your application source code)
```

### Manifest Files:

Here are example manifest files for our application. You would create these files in a new `kubernetes/` directory within your project.

**`postgres-deployment.yaml`**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
        - name: postgres
          image: postgres:13
          ports:
            - containerPort: 5432
          env:
            - name: POSTGRES_DB
              value: "mydatabase"
            - name: POSTGRES_USER
              value: "user"
            - name: POSTGRES_PASSWORD
              value: "password"
          volumeMounts:
            - name: postgres-storage
              mountPath: /var/lib/postgresql/data
      volumes:
        - name: postgres-storage
          persistentVolumeClaim:
            claimName: postgres-pvc
---
apiVersion: v1
kind: Service
metadata:
  name: postgres-service
spec:
  selector:
    app: postgres
  ports:
    - protocol: TCP
      port: 5432
      targetPort: 5432
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
```

**`backend-deployment.yaml`**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      containers:
        - name: backend
          image: your-docker-hub-username/your-backend-image:latest # <-- IMPORTANT: Use your own image from a registry
          ports:
            - containerPort: 5000
          env:
            - name: DATABASE_URL
              value: "postgresql://user:password@postgres-service:5432/mydatabase"
---
apiVersion: v1
kind: Service
metadata:
  name: backend-service
spec:
  selector:
    app: backend
  ports:
    - protocol: TCP
      port: 5000
      targetPort: 5000
```

**`frontend-deployment.yaml`**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
        - name: frontend
          image: your-docker-hub-username/your-frontend-image:latest # <-- IMPORTANT: Use your own image from a registry
          ports:
            - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: frontend-service
spec:
  selector:
    app: frontend
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
```

**`ingress.yaml`**
(Requires an Ingress Controller to be running in your cluster, which is included with Docker Desktop's Kubernetes.)
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app-ingress
spec:
  rules:
    - http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: frontend-service
                port:
                  number: 80
          - path: /api
            pathType: Prefix
            backend:
              service:
                name: backend-service
                port:
                  number: 5000
```

### Deployment Steps:

1.  **Build and Push Your Images:**
    Unlike Docker Compose, Kubernetes pulls images from a container registry. You must first build your frontend and backend images and push them to a registry like Docker Hub, GitHub Container Registry, or a private registry.
    ```bash
    docker build -t your-username/my-backend:latest ./backend
    docker push your-username/my-backend:latest

    docker build -t your-username/my-frontend:latest ./frontend
    docker push your-username/my-frontend:latest
    ```

2.  **Apply the Manifests:**
    Navigate to the directory containing your `.yaml` files and apply them to your cluster.
    ```bash
    kubectl apply -f postgres-deployment.yaml
    kubectl apply -f backend-deployment.yaml
    kubectl apply -f frontend-deployment.yaml
    kubectl apply -f ingress.yaml
    ```

3.  **Check the Status:**
    You can check the status of your deployments and pods:
    ```bash
    kubectl get deployments
    kubectl get pods
    kubectl get services
    kubectl get ingress
    ```

4.  **Access Your Application:**
    If you are using Docker Desktop, you should be able to access your application at `http://localhost`. The Ingress will route traffic to the appropriate services.

This section provides a high-level overview of deploying a multi-container application to Kubernetes. It's a significant step up from Docker Compose and is a critical skill for modern cloud-native development.
