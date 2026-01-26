# 12. Real-World Kubernetes Examples

This section brings together all the concepts learned throughout this guide and demonstrates how they are applied in practical, real-world scenarios. We will walk through several common application patterns, providing a blueprint for deploying and managing them effectively on Kubernetes.

## 12.1. Introduction: Bridging Theory and Practice

Successfully operating applications on Kubernetes requires more than just understanding individual components; it demands the ability to combine them into cohesive, resilient, and scalable systems. These examples aim to illustrate common architectures and best practices.

## 12.2. Example 1: Full-Stack To-Do Application (Revisited and Enhanced)

We will revisit the full-stack To-Do application (React frontend, Flask backend, PostgreSQL database) previously discussed in the Docker and CI/CD guides. Here, we'll demonstrate its deployment using proper Kubernetes manifests and introduce Helm for packaging.

### Scenario

*   **Frontend:** React application served by Nginx.
*   **Backend:** Python Flask API.
*   **Database:** PostgreSQL.
*   **Tools:** Kubernetes manifests, Helm Chart.

### Components Recap

*   **Frontend:**
    *   `Deployment`: Manages Pods running Nginx with React static files.
    *   `Service (ClusterIP)`: Internal service for frontend.
    *   `Ingress`: Exposes frontend externally.
*   **Backend:**
    *   `Deployment`: Manages Pods running Flask API.
    *   `Service (ClusterIP)`: Internal service for backend.
    *   `ConfigMap`: For backend configuration (e.g., API keys, non-sensitive settings).
    *   `Secret`: For sensitive backend configuration (e.g., database credentials).
*   **PostgreSQL Database:**
    *   `StatefulSet`: Manages a single-instance PostgreSQL Pod, ensuring stable identity and ordered lifecycle.
    *   `Service (ClusterIP)`: Internal service for PostgreSQL.
    *   `PersistentVolumeClaim (PVC)`: Requests persistent storage for PostgreSQL data.
    *   `ConfigMap`/`Secret`: For PostgreSQL configuration and credentials.

### Deployment using Helm Chart

Instead of applying individual YAML files, we package all these Kubernetes resources into a **Helm Chart**, which offers templating, versioning, and easier management.

**Helm Chart Structure (Conceptual):**

```
my-todo-app/
├── Chart.yaml                  # Chart metadata
├── values.yaml                 # Default configuration values
├── templates/
│   ├── _helpers.tpl            # Helm utility functions
│   ├── frontend-deployment.yaml
│   ├── frontend-service.yaml
│   ├── frontend-ingress.yaml
│   ├── backend-deployment.yaml
│   ├── backend-service.yaml
│   ├── backend-configmap.yaml
│   ├── backend-secret.yaml
│   ├── postgres-statefulset.yaml
│   ├── postgres-service.yaml
│   └── postgres-pvc.yaml
└── Chart.lock
```

You would define your application's configuration in `values.yaml` and use Go templating in the `.yaml` files under `templates/` to make them dynamic.

**Basic Helm Commands:**

```bash
# Install the chart
helm install my-todo-release ./my-todo-app

# Upgrade the release with new values
helm upgrade my-todo-release ./my-todo-app --values new-values.yaml

# Rollback to a previous revision
helm rollback my-todo-release 1
```

### CI/CD Integration (Conceptual)

The CI/CD pipeline (as discussed in the CI/CD guide) would:

1.  Build and push frontend and backend Docker images (using unique tags like Git SHA).
2.  Update the Helm Chart's `values.yaml` (e.g., `image.tag=GIT_SHA`) or pass these values during `helm upgrade`.
3.  Execute `helm upgrade --install` to deploy the application to Kubernetes.

## 12.3. Example 2: Deploying a Message Queue (Kafka/RabbitMQ) with StatefulSets

Message queues are inherently stateful and often require specific deployment patterns.

### Scenario

Deploying a highly available **Apache Kafka** cluster (or RabbitMQ) using Kubernetes.

### Components

*   **`StatefulSet`:** For each Kafka broker (or RabbitMQ node). Ensures stable network identity and ordered operations.
*   **`Headless Service`:** For direct Pod-to-Pod communication within the Kafka cluster and stable DNS names for each broker.
*   **`PersistentVolumeClaim (PVC)`:** Each broker gets its own dedicated PVC for persistent storage of logs/data.
*   **`ConfigMap`:** For Kafka broker configuration.
*   **`Service (ClusterIP)`:** For internal client access to the Kafka cluster.
*   **`Service (NodePort`/`LoadBalancer`/`Ingress)`:** For external client access (if needed).

### Key Considerations

*   **Persistent Storage:** Each broker's data must persist across restarts.
*   **Network Identity:** Kafka brokers rely on stable network identities.
*   **Ordered Operations:** StatefulSets ensure that Pods are started, scaled, and deleted in a predictable order, crucial for clustered applications.
*   **Zookeeper (for Kafka):** Often deployed as a separate StatefulSet or managed service.

## 12.4. Example 3: Deploying a Microservices Application

A common real-world use case involves deploying multiple interconnected microservices.

### Scenario

An e-commerce application with separate services for `Product Catalog`, `Order Processing`, `User Authentication`, and a central `API Gateway`.

### Components

*   **Multiple `Deployments`:** One for each microservice.
*   **Multiple `Services (ClusterIP)`:** For internal communication between microservices.
*   **`Ingress`:** For external access, routing requests to the appropriate microservice via the `API Gateway`.
*   **`ConfigMaps`/`Secrets`:** For microservice configurations and credentials.
*   **`Network Policies`:** To restrict communication between microservices to only necessary paths.
*   **Service Mesh (e.g., Istio):** For advanced traffic management (retry logic, circuit breaking, request routing), mTLS encryption, and distributed tracing.

### Key Considerations

*   **Service Discovery:** Microservices find each other via Kubernetes DNS.
*   **Inter-Service Communication:** Typically HTTP/gRPC.
*   **Observability:** Comprehensive logging, monitoring, and distributed tracing (e.g., using Jaeger) are critical for debugging.
*   **Network Security:** Fine-grained control over which services can talk to each other.

## 12.5. Example 4: Batch Processing with Jobs/CronJobs

Kubernetes is also well-suited for running batch workloads.

### Scenario

*   **Job:** A one-off data processing task that runs to completion (e.g., a data migration script).
*   **CronJob:** A scheduled task that runs periodically (e.g., daily database backup, report generation).

### Components

*   **`Job` Manifest:** Defines the Pod(s) that run the task, how many completions are needed, and retry policies.
*   **`CronJob` Manifest:** Defines a `Job` to be run on a schedule (like cron syntax).

### Key Considerations

*   **Retries:** Configure `restartPolicy` and `backoffLimit` for robust job execution.
*   **Parallelism:** Jobs can run multiple Pods in parallel for faster processing.
*   **Resource Limits:** Define appropriate CPU/memory requests and limits to prevent resource exhaustion.
*   **Output Handling:** Where logs go, how results are stored.

## 12.6. Future Trends in Real-World Usage (up to 2026)

*   **Operators:** Custom controllers that extend Kubernetes to manage complex applications (like databases, message queues) as native Kubernetes objects, encapsulating operational knowledge. More applications will come with robust Operators.
*   **Serverless Workloads on K8s (Knative):** Running event-driven functions and applications directly on Kubernetes, leveraging its scaling capabilities while offering a serverless-like developer experience.
*   **GitOps (Revisited):** The deployment methodology of choice for most production Kubernetes clusters, ensuring declarative, auditable, and automated deployments.
*   **Platform Engineering:** Internal developer platforms will simplify the interaction with complex Kubernetes deployments, providing self-service capabilities for developers.

These real-world examples illustrate the flexibility and power of Kubernetes in managing diverse application types, from stateless web services to highly available stateful clusters and batch jobs. They emphasize combining various Kubernetes primitives and tools to build robust and efficient systems.
