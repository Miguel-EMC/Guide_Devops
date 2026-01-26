# 8. Real-World CI/CD Examples

This section ties together the theoretical concepts and best practices discussed earlier by presenting concrete, real-world examples of CI/CD pipelines. We will explore how to build automated workflows for different application architectures, using popular tools like GitHub Actions.

## 8.1. Example 1: CI/CD for a Full-Stack Application to Kubernetes (using GitHub Actions)

This example extends the full-stack To-Do application (React frontend, Flask backend, PostgreSQL database) from the Docker guide, demonstrating a complete CI/CD pipeline that builds, tests, and deploys to a Kubernetes cluster.

### Scenario

A web application where:
*   **Frontend:** React application served by Nginx.
*   **Backend:** Python Flask API.
*   **Database:** PostgreSQL.
*   **Orchestration:** Kubernetes.
*   **CI/CD Tool:** GitHub Actions.
*   **Container Registry:** Docker Hub.

### Pipeline Overview (High-Level)

1.  **Trigger:** `push` events to the `main` branch on either `frontend/` or `backend/` directories.
2.  **Build Stage:**
    *   Build Docker images for both frontend and backend.
    *   (Optional: run unit/integration tests).
3.  **Scan Stage:**
    *   Scan newly built Docker images for vulnerabilities (e.g., using Trivy).
4.  **Push Stage:**
    *   Push tagged Docker images to Docker Hub.
5.  **Deploy Stage:**
    *   Update Kubernetes deployments with the new image tags.

### Key GitHub Actions Workflows

We'll use two separate workflows, one for the frontend and one for the backend, triggered by path changes to enable efficient monorepo-like behavior.

**`.github/workflows/backend-ci-cd.yml`**

```yaml
name: Backend CI/CD to Kubernetes

on:
  push:
    branches: [ main ]
    paths:
      - 'backend/**' # Trigger only if changes are in the backend directory

jobs:
  build-test-scan-push-deploy:
    runs-on: ubuntu-latest
    env:
      IMAGE_NAME: my-backend
      REGISTRY_USERNAME: ${{ secrets.DOCKER_HUB_USERNAME }}
      REGISTRY_TOKEN: ${{ secrets.DOCKER_HUB_ACCESS_TOKEN }}

    steps:
      - name: Checkout Repository
        uses: actions/checkout@v2

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v1

      - name: Log in to Docker Hub
        uses: docker/login-action@v1
        with:
          username: ${{ env.REGISTRY_USERNAME }}
          password: ${{ env.REGISTRY_TOKEN }}

      - name: Build backend Docker image
        id: docker_build
        uses: docker/build-push-action@v2
        with:
          context: ./backend # Path to your backend's Dockerfile context
          file: ./backend/Dockerfile
          push: false # Don't push yet, we'll scan first
          tags: ${{ env.REGISTRY_USERNAME }}/${{ env.IMAGE_NAME }}:${{ github.sha }}

      - name: Run backend tests (conceptual)
        run: |
          # Example: Install dependencies and run tests inside a temporary container
          docker run --rm ${{ env.REGISTRY_USERNAME }}/${{ env.IMAGE_NAME }}:${{ github.sha }} python -m pytest ./backend/tests/

      - name: Scan backend image for vulnerabilities
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: '${{ env.REGISTRY_USERNAME }}/${{ env.IMAGE_NAME }}:${{ github.sha }}'
          format: 'table'
          exit-code: '1' # Fail the build if CRITICAL/HIGH vulnerabilities are found
          ignore-unfixed: true
          severity: 'CRITICAL,HIGH'

      - name: Push backend Docker image
        uses: docker/build-push-action@v2
        with:
          context: ./backend
          file: ./backend/Dockerfile
          push: true
          tags: ${{ env.REGISTRY_USERNAME }}/${{ env.IMAGE_NAME }}:${{ github.sha }}
          # Also tag with 'latest' if you wish, but SHA is for immutable deployments
          # tags: ${{ env.REGISTRY_USERNAME }}/${{ env.IMAGE_NAME }}:${{ github.sha }},${{ env.REGISTRY_USERNAME }}/${{ env.IMAGE_NAME }}:latest

      - name: Deploy to Kubernetes
        uses: azure/k8s-set-context@v1 # Use a suitable action for setting K8s context
        with:
          method: kubeconfig
          kubeconfig: ${{ secrets.KUBE_CONFIG }} # Your Kubernetes kubeconfig as a secret

      - name: Update Kubernetes Deployment
        run: |
          # Replace the image tag in your Kubernetes manifest and apply it
          # This assumes your deployment.yaml has an image field to update
          # A more robust solution might use kustomize or helm
          kubectl set image deployment/backend-deployment backend=${{ env.REGISTRY_USERNAME }}/${{ env.IMAGE_NAME }}:${{ github.sha }} -n your-namespace # Replace 'your-namespace'
          kubectl rollout status deployment/backend-deployment -n your-namespace
        env:
          KUBECONFIG_FILE: ${{ runner.temp }}/kubeconfig
```

**`.github/workflows/frontend-ci-cd.yml`**
(Similar structure to backend, adapted for frontend build and Nginx image)

```yaml
name: Frontend CI/CD to Kubernetes

on:
  push:
    branches: [ main ]
    paths:
      - 'frontend/**' # Trigger only if changes are in the frontend directory

jobs:
  build-scan-push-deploy:
    runs-on: ubuntu-latest
    env:
      IMAGE_NAME: my-frontend
      REGISTRY_USERNAME: ${{ secrets.DOCKER_HUB_USERNAME }}
      REGISTRY_TOKEN: ${{ secrets.DOCKER_HUB_ACCESS_TOKEN }}

    steps:
      - name: Checkout Repository
        uses: actions/checkout@v2

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v1

      - name: Log in to Docker Hub
        uses: docker/login-action@v1
        with:
          username: ${{ env.REGISTRY_USERNAME }}
          password: ${{ env.REGISTRY_TOKEN }}

      - name: Build and push frontend Docker image (multi-stage)
        uses: docker/build-push-action@v2
        with:
          context: ./frontend # Path to your frontend's Dockerfile context
          file: ./frontend/Dockerfile
          push: true # Push directly after build, as scanning for Nginx is less critical
          tags: ${{ env.REGISTRY_USERNAME }}/${{ env.IMAGE_NAME }}:${{ github.sha }}
          # tags: ${{ env.REGISTRY_USERNAME }}/${{ env.IMAGE_NAME }}:${{ github.sha }},${{ env.REGISTRY_USERNAME }}/${{ env.IMAGE_NAME }}:latest

      - name: Deploy to Kubernetes
        uses: azure/k8s-set-context@v1
        with:
          method: kubeconfig
          kubeconfig: ${{ secrets.KUBE_CONFIG }} # Your Kubernetes kubeconfig as a secret

      - name: Update Kubernetes Deployment
        run: |
          kubectl set image deployment/frontend-deployment frontend=${{ env.REGISTRY_USERNAME }}/${{ env.IMAGE_NAME }}:${{ github.sha }} -n your-namespace # Replace 'your-namespace'
          kubectl rollout status deployment/frontend-deployment -n your-namespace
        env:
          KUBECONFIG_FILE: ${{ runner.temp }}/kubeconfig
```

## 8.2. Example 2: CI/CD for a Serverless API (using AWS SAM/Serverless Framework and GitHub Actions)

This example focuses on automating the deployment of a serverless REST API using AWS Lambda and API Gateway.

### Scenario

A simple Python REST API deployed as an AWS Lambda function, exposed via AWS API Gateway.
*   **Tools:** AWS Serverless Application Model (SAM) CLI (or Serverless Framework), GitHub Actions.
*   **Language:** Python.

### Pipeline Overview

1.  **Trigger:** `push` events to the `main` branch.
2.  **Build & Test Stage:**
    *   Install dependencies.
    *   Run unit tests.
3.  **Deploy Stage:**
    *   Package the serverless application (e.g., `sam build`).
    *   Deploy the application to AWS (e.g., `sam deploy`).
4.  **Post-Deployment Tests:**
    *   Run integration/API tests against the newly deployed endpoint.

### Key GitHub Actions Workflow

**`.github/workflows/serverless-deploy.yml`**

```yaml
name: Serverless API CI/CD

on:
  push:
    branches:
      - main

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v2

      - name: Set up Python
        uses: actions/setup-python@v2
        with:
          python-version: '3.8' # Or your desired Python version

      - name: Install dependencies
        run: |
          python -m pip install --upgrade pip
          pip install -r requirements.txt # Assuming your Lambda dependencies

      - name: Run unit tests
        run: |
          pytest # Assuming you have tests in a 'tests/' directory

      - name: Install AWS SAM CLI
        run: pip install aws-sam-cli

      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v1
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-east-1 # Change to your desired AWS region

      - name: Build Serverless Application
        run: sam build --use-container # If your SAM app uses layers or specific runtimes

      - name: Deploy Serverless Application
        run: sam deploy --no-confirm-changeset --no-disable-rollback --stack-name your-serverless-app-stack --s3-bucket your-sam-deployment-bucket --capabilities CAPABILITY_IAM # Adjust stack name and S3 bucket
```

## 8.3. Example 3: CI/CD with Monorepo (Conceptual)

Managing CI/CD in a monorepo (a single repository containing multiple independent projects) presents unique challenges.

### Challenges

*   **Unnecessary Builds:** Running the full pipeline for all projects even if only one changed.
*   **Slow Feedback:** Long pipeline execution times.
*   **Complex Configuration:** Managing triggers and dependencies between projects.

### Solutions and Techniques

*   **Path-Based Triggers:** As shown in the full-stack example, configure your CI/CD tool to trigger pipelines only when changes occur in specific directories (e.g., `on.push.paths` in GitHub Actions).
*   **Dedicated Tools:**
    *   **Nx:** A powerful build system for monorepos (especially JavaScript/TypeScript) that intelligently analyzes the dependency graph to run commands only on affected projects.
    *   **Lerna:** A tool for managing JavaScript projects with multiple packages.
*   **Build Caching:** Leverage distributed caching to reuse build outputs across different pipeline runs and even different projects.
*   **Dependency Graph Analysis:** Implement custom logic to determine which projects are affected by a change and only run pipelines for those.

By implementing these real-world examples, you gain practical experience in building and optimizing CI/CD pipelines for diverse application types and deployment environments.
