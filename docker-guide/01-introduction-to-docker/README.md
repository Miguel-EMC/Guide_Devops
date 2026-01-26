# Introduction to Docker

Docker is an open-source platform that allows developers to package applications and their dependencies into containers, which are standardized units of software. These containers are lightweight, portable, and run consistently across any environment.

## Why Use Docker?

*   **Environment Consistency:** Eliminates the "it works on my machine" problem by ensuring your application runs identically in development, testing, and production.
*   **Isolation:** Containers isolate applications from each other and from the host system, increasing security and preventing dependency conflicts.
*   **Portability:** A Docker container can run on any system with Docker installed, whether it's a local server, a virtual machine, or the cloud.
*   **Resource Efficiency:** Containers are much lighter than virtual machines, meaning you can run more applications on the same infrastructure.
*   **Rapid Development and Deployment:** Facilitates Continuous Integration and Continuous Deployment (CI/CD) by simplifying the creation, shipping, and running of applications.

## Key Concepts

### 1. Docker Images

A Docker image is a read-only template that contains the instructions for creating a container. It includes the application code, libraries, dependencies, and environment configuration. Images are the foundation of containers.

### 2. Docker Containers

A container is an executable instance of a Docker image. When an image is run, a container is created. You can start, stop, move, or delete a container. Each container is an isolated process that runs on the host operating system.

### 3. Dockerfile

A Dockerfile is a text file that contains all the instructions needed to build a Docker image. It uses a simple, declarative syntax to define the image, step by step.

### 4. Docker Hub and Container Registries

Docker Hub is a cloud-based registry service provided by Docker for finding and sharing container images. It is the world's largest public registry. Private registries also exist for companies to securely store their own images.

### 5. Docker Engine

This is the core of the Docker system. It includes a Docker daemon (server), a REST API that interacts with the daemon, and a command-line interface (CLI). The Docker Engine manages images, containers, volumes, and networks.

## Docker Installation

To start using Docker, you must first install Docker Desktop (for Windows and macOS) or Docker Engine (for Linux). Visit the [official Docker documentation](https://docs.docker.com/get-docker/) for detailed installation instructions for your operating system.

## Getting Started: Hello Docker!

Let's run our first container to see Docker in action.

1.  **Open your terminal or command prompt.**

2.  **Run the following command:**

    ```bash
    docker run hello-world
    ```

    This command will do the following:
    *   Search for the `hello-world` image locally.
    *   If not found, download it from Docker Hub.
    *   Create a new container from that image.
    *   Execute the program inside the container, which will print a "Hello from Docker!" message.
    *   The container will stop and be automatically removed after displaying the message.

Congratulations! You've run your first Docker container. In the following sections, we will delve into how to build your own images, manage containers, and use Docker in your projects.
