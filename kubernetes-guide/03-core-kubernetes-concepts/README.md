# 3. Core Kubernetes Concepts

Kubernetes manages your applications by using a set of well-defined API objects. Understanding these core concepts is fundamental to effectively deploying, managing, and troubleshooting applications within a Kubernetes cluster. This section breaks down these building blocks, illustrating their purpose and interrelationships.

## 3.1. The Kubernetes Object Model

At its heart, Kubernetes is a system built around managing API Objects. These objects are persistent entities in the Kubernetes cluster that represent the state of your cluster. When you create an object, you are effectively telling the Kubernetes control plane what you want your cluster's workload to look like.

*   **Everything is an API Object:** From Pods and Deployments to Services and Namespaces, every entity you interact with in Kubernetes is an API object.
*   **Declarative vs. Imperative Management:**
    *   **Declarative:** You define the *desired state* of your objects (e.g., in YAML files), and Kubernetes works to achieve and maintain that state. This is the preferred and most common method.
    *   **Imperative:** You issue commands to perform specific actions (e.g., `kubectl run`, `kubectl expose`). While useful for quick, ad-hoc tasks, declarative management is more robust for production.

## 3.2. Pods

A **Pod** is the smallest deployable unit in Kubernetes. It represents a single instance of a running process in your cluster.

*   **Container Grouping:**
    *   **1-to-1 Mapping:** In most cases, a Pod contains a single container.
    *   **Multi-Container Pods (Sidecars):** A Pod can contain multiple containers that are tightly coupled and share the same network namespace, IP address, and storage. A common pattern is the "sidecar" container, which extends or enhances the primary container (e.g., a logging agent, a proxy).
*   **Lifecycle:** Pods are ephemeral. If a Pod dies, Kubernetes replaces it with a new one. They are not designed to be restarted or reused.
*   **Health Checks:**
    *   **Liveness Probe:** Checks if the application inside the container is running and healthy. If it fails, Kubernetes restarts the container.
    *   **Readiness Probe:** Checks if the application is ready to serve traffic. If it fails, the Pod is removed from Service endpoints until it becomes ready.
    *   **Startup Probe:** (Introduced for slow-starting applications) Checks if the application within the container has started up successfully.

## 3.3. Controllers

Controllers are control loops that watch the state of your cluster and make changes to move the current state towards the desired state. They manage Pods, providing self-healing and scalability.

*   **ReplicaSet:**
    *   **Purpose:** Ensures a stable set of replica Pods running at any given time. If a Pod fails, the ReplicaSet creates a new one.
    *   **Direct Usage:** Rarely used directly; usually managed by Deployments.
*   **Deployment:**
    *   **Purpose:** Provides declarative updates for Pods and ReplicaSets. It describes the desired state of your application, and the Deployment Controller changes the actual state to the desired state at a controlled rate.
    *   **Key Features:** Automated rollouts, rollbacks, pause/resume updates. This is the primary way to manage stateless applications.
*   **StatefulSet:**
    *   **Purpose:** Manages the deployment and scaling of a set of Pods, and provides guarantees about the ordering and uniqueness of these Pods. Used for stateful applications like databases.
    *   **Key Features:** Stable, unique network identifiers, stable persistent storage, ordered graceful deployment and scaling.
*   **DaemonSet:**
    *   **Purpose:** Ensures that all (or some) nodes in a cluster run a copy of a Pod.
    *   **Use Cases:** Running cluster-level tools like logging agents (Fluentd), monitoring agents (Prometheus Node Exporter), or network proxies (kube-proxy) on every node.
*   **Job / CronJob:**
    *   **Job:** Creates one or more Pods and ensures that a specified number of them successfully terminate. Used for batch processing.
    *   **CronJob:** Creates Jobs on a repeating schedule. Used for scheduled tasks (e.g., backups, report generation).

## 3.4. Services

A **Service** is an abstract way to expose an application running on a set of Pods as a network service. Services decouple your application Pods from network access, providing a stable IP address and DNS name.

*   **ClusterIP:**
    *   **Purpose:** Exposes the Service on an internal IP address within the cluster.
    *   **Access:** Only reachable from within the cluster. Default Service type.
    *   **Use Cases:** Internal communication between microservices.
*   **NodePort:**
    *   **Purpose:** Exposes the Service on each Node's IP at a static port (the NodePort).
    *   **Access:** Accessible from outside the cluster via `<NodeIP>:<NodePort>`.
    *   **Use Cases:** Simple external access for testing or small-scale applications.
*   **LoadBalancer:**
    *   **Purpose:** Exposes the Service externally using a cloud provider's load balancer.
    *   **Access:** Provides an external IP address that acts as the entry point to your Service.
    *   **Use Cases:** Exposing web applications or APIs to the internet in a cloud environment.
*   **ExternalName:**
    *   **Purpose:** Maps a Service to an arbitrary DNS name.
    *   **Use Cases:** For services external to the cluster (e.g., a database hosted outside Kubernetes).

## 3.5. Volumes

Containers are ephemeral, and any data written inside them is lost when the container is terminated. **Volumes** provide a way to persist data, allowing containers to share data and ensuring data integrity across Pod restarts.

*   **`emptyDir`:** A simple, ephemeral volume that is created when a Pod is assigned to a node and exists as long as that Pod is running on that node. Data is lost if the Pod dies or the node is restarted.
*   **`hostPath`:** Mounts a file or directory from the host node's filesystem into a Pod.
    *   **Use Cases:** Used for system-level functions (e.g., mounting `/var/log` for a logging agent).
    *   **Caveats:** Not recommended for general data persistence due to lack of portability and potential security risks.
*   **PersistentVolume (PV) and PersistentVolumeClaim (PVC):**
    *   **PV:** A piece of storage in the cluster that has been provisioned by an administrator or dynamically provisioned using a StorageClass. It represents the actual physical storage.
    *   **PVC:** A request for storage by a user. Pods consume PVCs. PVCs abstract the details of the underlying storage from Pods, allowing them to request storage resources without knowing the specifics of the storage infrastructure.

## 3.6. ConfigMaps and Secrets

These objects are used to decouple configuration data and sensitive information from application code and Docker images.

*   **ConfigMaps:**
    *   **Purpose:** Store non-confidential configuration data in key-value pairs.
    *   **Consumption:** Can be consumed as environment variables, command-line arguments, or as files mounted into Pods.
*   **Secrets:**
    *   **Purpose:** Store sensitive information (passwords, API keys, tokens, SSH keys) more securely.
    *   **Security:** Base64 encoded by default (not encrypted at rest without additional configuration), but Kubernetes restricts access.
    *   **Consumption:** Similar to ConfigMaps (environment variables, mounted files).

## 3.7. Namespaces

**Namespaces** provide a mechanism for isolating groups of resources within a single Kubernetes cluster. They are like virtual clusters inside a physical cluster.

*   **Purpose:**
    *   Logical isolation for different teams, projects, or environments (dev, staging, prod).
    *   Resource quotas can be applied per Namespace.
    *   Avoids naming collisions between resources.
*   **Default Namespaces:** `default`, `kube-system`, `kube-public`, `kube-node-lease`.

## 3.8. Labels and Selectors

**Labels** are key/value pairs that are attached to Kubernetes objects (Pods, Deployments, Services, etc.). They are used to organize and select subsets of objects.

*   **Purpose:**
    *   Organizing objects: `app: my-app`, `env: production`, `tier: frontend`.
    *   Targeting resources: Services use label selectors to identify the Pods they should route traffic to. Deployments use label selectors to manage their Pods.

## 3.9. Annotations

**Annotations** are also key/value pairs, similar to Labels, but are used to attach arbitrary non-identifying metadata to objects.

*   **Purpose:** Used for tools and libraries to store their own metadata, or for human-readable notes.
*   **Key Difference from Labels:** Labels are for identifying and selecting objects; annotations are for non-identifying metadata.

Understanding these core concepts is essential for navigating and effectively operating within a Kubernetes environment. In the next sections, we will explore how to interact with these objects using `kubectl` and dive into more specialized topics.
