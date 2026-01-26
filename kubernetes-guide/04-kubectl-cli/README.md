# 4. kubectl: The Kubernetes Command-Line Tool

`kubectl` is the primary command-line tool for interacting with a Kubernetes cluster. It allows you to run commands against Kubernetes clusters, including deploying applications, inspecting and managing cluster resources, and viewing logs. Mastering `kubectl` is essential for anyone working with Kubernetes, from developers to cluster administrators.

## 4.1. Introduction to `kubectl`

*   **Role:** `kubectl` communicates with the Kubernetes API server, which is the front-end of the Kubernetes control plane. All operations in Kubernetes are performed through the API server.
*   **`kubeconfig` file:** `kubectl` uses a configuration file (by default, `~/.kube/config`) to find the cluster and authenticate to it. This file contains cluster connection details, user authentication information, and contexts (combinations of cluster, user, and namespace).

## 4.2. Installation and Configuration

`kubectl` is a standalone binary that needs to be installed on your local machine.

### a. Installation

*   **Linux:**
    ```bash
    # Download the latest stable release
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    # Install
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    ```
*   **macOS:**
    ```bash
    # Using Homebrew
    brew install kubectl
    ```
*   **Windows:**
    ```bash
    # Using Chocolatey
    choco install kubernetes-cli
    # Or Winget
    winget install Kubernetes.kubectl
    ```

### b. Configuration (`kubeconfig` Context Management)

Your `kubeconfig` file allows you to switch between multiple clusters, users, and namespaces.

*   **View current config:** `kubectl config view`
*   **Get current context:** `kubectl config current-context`
*   **List contexts:** `kubectl config get-contexts`
*   **Switch context:** `kubectl config use-context <context-name>` (e.g., `minikube`, `docker-desktop`, or a cloud cluster context)
*   **Rename context:** `kubectl config rename-context old-name new-name`

## 4.3. Essential `kubectl` Commands

This section covers the most frequently used `kubectl` commands.

### a. Resource Management

The preferred way to manage Kubernetes resources is **declaratively** using YAML or JSON manifest files.

*   **`kubectl apply -f <file.yaml>`:**
    *   **Purpose:** Creates resources if they don't exist or updates them if they do. This is the primary command for declarative management.
    *   **Example:** `kubectl apply -f my-deployment.yaml`
*   **`kubectl delete -f <file.yaml>`:**
    *   **Purpose:** Deletes resources defined in the specified file.
    *   **Example:** `kubectl delete -f my-deployment.yaml`
*   **`kubectl create -f <file.yaml>`:** (Imperative, use with caution)
    *   **Purpose:** Creates resources. If the resource already exists, it will fail. Less suitable for updates.
*   **`kubectl run <name> --image=<image> --port=<port>`:** (Imperative, for quick tests)
    *   **Purpose:** Creates a Deployment or Pod directly from the command line. Often used for quick ephemeral Pods.
    *   **Example:** `kubectl run my-nginx --image=nginx --port=80`

### b. Inspecting Resources

Understanding the state of your cluster and its resources is vital.

*   **`kubectl get <resource-type> [name] [-n <namespace>] [-o <output-format>]`:**
    *   **Purpose:** Lists resources of a specific type.
    *   **Examples:**
        *   `kubectl get pods`: List all pods in the current namespace.
        *   `kubectl get deployments -n my-namespace`: List deployments in `my-namespace`.
        *   `kubectl get services -o wide`: List services with extra information.
        *   `kubectl get pod my-pod -o yaml`: Get YAML definition of a specific pod.
*   **`kubectl describe <resource-type> <name> [-n <namespace>]`:**
    *   **Purpose:** Shows detailed information about a specific resource, including events, conditions, and associated resources.
    *   **Example:** `kubectl describe pod my-app-pod-xyz`
*   **`kubectl logs <pod-name> [-c <container-name>] [-f]`:**
    *   **Purpose:** View logs for a container in a Pod.
    *   **Examples:**
        *   `kubectl logs my-app-pod-xyz`: View logs from the primary container.
        *   `kubectl logs my-app-pod-xyz -c sidecar-logger`: View logs from a specific sidecar container.
        *   `kubectl logs -f my-app-pod-xyz`: Follow (stream) logs.
*   **`kubectl exec -it <pod-name> [-c <container-name>] -- <command>`:**
    *   **Purpose:** Execute a command inside a running container within a Pod.
    *   **Example:** `kubectl exec -it my-app-pod-xyz -- bash` (to open a shell in the container)

### c. Updating Resources

*   **`kubectl edit <resource-type> <name>`:**
    *   **Purpose:** Opens the live definition of a resource in your default editor. Changes are applied on save. Use with caution in production.
    *   **Example:** `kubectl edit deployment my-app`
*   **`kubectl rollout status deployment/<name> [-n <namespace>]`:**
    *   **Purpose:** Watches the status of a deployment rollout until it's complete.
    *   **Example:** `kubectl rollout status deployment/my-app`
*   **`kubectl rollout undo deployment/<name>`:**
    *   **Purpose:** Rolls back a deployment to its previous revision.
    *   **Example:** `kubectl rollout undo deployment/my-app`
*   **`kubectl scale deployment/<name> --replicas=<count>`:**
    *   **Purpose:** Scales a Deployment to a desired number of replicas.
    *   **Example:** `kubectl scale deployment/my-app --replicas=3`

### d. Cluster Information

*   **`kubectl cluster-info`:** Displays information about the master and services.
*   **`kubectl get nodes`:** Lists the nodes in your cluster.
*   **`kubectl get namespaces`:** Lists all namespaces.
*   **`kubectl api-resources`:** Lists all available API resources.

### e. Advanced Operations

*   **`kubectl port-forward <pod-name> <local-port>:<remote-port>`:**
    *   **Purpose:** Forwards a local port to a port on a Pod. Useful for debugging or accessing internal services locally.
    *   **Example:** `kubectl port-forward my-database-pod 5432:5432`
*   **`kubectl top pod/node`:**
    *   **Purpose:** Displays CPU/memory usage for pods or nodes. Requires Metrics Server to be installed in the cluster.
*   **`kubectl debug` (Kubernetes 1.18+):**
    *   **Purpose:** Attach an ephemeral container to a running Pod for debugging. A powerful modern debugging tool.
*   **`kubectl diff -f <file.yaml>`:**
    *   **Purpose:** Shows a diff between the live state of a resource and the proposed changes in your local YAML file before applying. Essential for declarative workflows.

## 4.4. `kubectl` Best Practices and Tips (up to 2026 Perspective)

*   **Prioritize Declarative Management:** Always manage your resources using `kubectl apply -f` with YAML files stored in version control. Avoid `kubectl create` or `kubectl run` for anything beyond quick tests.
*   **Use Namespaces Effectively:** Organize your resources logically using namespaces for isolation and access control.
*   **Alias `k=kubectl`:** A common practice to save keystrokes: `alias k=kubectl`.
*   **Shell Autocompletion:** Enable `kubectl` autocompletion for your shell (bash, zsh) to dramatically improve efficiency.
*   **`kustomize` and `Helm`:** For managing complex and templated Kubernetes configurations across different environments, `kustomize` (built into `kubectl`) and `Helm` (the package manager for Kubernetes) are indispensable tools that extend `kubectl`'s capabilities.
*   **`kubectl explain <resource-type>.<field>`:** Get documentation directly in your terminal for API fields.
*   **`kubectl --dry-run=client -o yaml apply -f <file.yaml>`:** Generate the final YAML that would be applied *without* actually applying it. Useful for debugging manifest generation.
*   **Use JSONPath for Custom Output:** For scripting or specific data extraction, `kubectl get <resource> -o=jsonpath='{.items[*].metadata.name}'` is very powerful.

By adopting these practices, you'll be well-equipped to manage your Kubernetes clusters efficiently and safely, staying productive with the command-line interface.
