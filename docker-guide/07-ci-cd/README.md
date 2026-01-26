# CI/CD Pipelines for Dockerized Applications

Continuous Integration (CI) and Continuous Deployment/Delivery (CD) are practices that automate the software development and release process. When combined with Docker, CI/CD pipelines become incredibly powerful, enabling teams to build, test, and deploy applications faster and more reliably.

## 1. What is CI/CD?

*   **Continuous Integration (CI):** The practice of frequently merging all developers' working copies of code to a shared mainline. Each integration is then verified by an automated build and automated tests. The main goal of CI is to detect integration bugs early.
*   **Continuous Delivery (CD):** An extension of CI where you automatically build and test your code and prepare it for release to production.
*   **Continuous Deployment (CD):** Goes one step further than continuous delivery. With this practice, every change that passes all stages of your production pipeline is released to your customers.

## 2. A Typical CI/CD Pipeline for a Dockerized App

A common workflow for a Dockerized application looks like this:

1.  **Code Push:** A developer pushes code changes to a Git repository (e.g., on GitHub).
2.  **Trigger Pipeline:** The push event automatically triggers a CI/CD pipeline.
3.  **Run Tests:** The pipeline runs unit and integration tests.
4.  **Build Docker Image:** If tests pass, the pipeline builds a new Docker image for the application.
5.  **Push to Registry:** The newly built image is tagged and pushed to a container registry (e.g., Docker Hub, GitHub Container Registry).
6.  **Deploy:** The pipeline automatically deploys the new image to a staging or production environment (e.g., by updating a Kubernetes deployment).

## 3. Using GitHub Actions for CI/CD

GitHub Actions is a CI/CD platform that allows you to automate your build, test, and deployment pipeline. It's deeply integrated with GitHub, making it a popular choice for many projects.

To get started, you create a workflow file in your repository at `.github/workflows/your-workflow-file.yml`.

## 4. Example GitHub Actions Workflow

Let's create a workflow that automates the process for the backend service of our full-stack application. This workflow will:

1.  Trigger on a push to the `main` branch.
2.  Check out the code.
3.  Log in to Docker Hub.
4.  Build the Docker image for the backend.
5.  Push the image to Docker Hub.

**`.github/workflows/backend-ci.yml`**
(You would create the `.github/workflows` directories in the root of your project.)

```yaml
name: Backend CI

on:
  push:
    branches: [ main ]
    paths:
      - 'backend/**' # Only run this workflow if files in the backend directory change

jobs:
  build-and-push:
    runs-on: ubuntu-latest

    steps:
      - name: Check out the repo
        uses: actions/checkout@v2

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v1

      - name: Log in to Docker Hub
        uses: docker/login-action@v1
        with:
          username: ${{ secrets.DOCKER_HUB_USERNAME }}
          password: ${{ secrets.DOCKER_HUB_ACCESS_TOKEN }}

      - name: Build and push backend image
        uses: docker/build-push-action@v2
        with:
          context: ./backend
          file: ./backend/Dockerfile
          push: true
          tags: ${{ secrets.DOCKER_HUB_USERNAME }}/my-backend:latest
```

## 5. Secrets Management in GitHub Actions

In the example above, we used `secrets.DOCKER_HUB_USERNAME` and `secrets.DOCKER_HUB_ACCESS_TOKEN`. **Never hardcode secrets in your workflow files.**

GitHub provides a way to store secrets for your repository.

1.  Go to your GitHub repository.
2.  Click on **Settings** > **Secrets** > **Actions**.
3.  Click **New repository secret**.
4.  Create two secrets:
    *   `DOCKER_HUB_USERNAME`: Your Docker Hub username.
    *   `DOCKER_HUB_ACCESS_TOKEN`: A Docker Hub Access Token (not your password). You can generate one in your Docker Hub account settings.

## 6. Expanding the Workflow

This is a basic workflow. You can expand it to:

*   **Run Tests:** Add a step before building the image to run your tests (e.g., `pytest`). If the tests fail, the workflow will stop.
*   **Tag Images with Git SHA:** Use the Git commit SHA as the image tag for better versioning (`tags: ${{ secrets.DOCKER_HUB_USERNAME }}/my-backend:${{ github.sha }}`).
*   **Multi-Stage Builds:** The same multi-stage `Dockerfile`s we've discussed work perfectly in CI/CD.
*   **Deploy to Kubernetes:** Add a final step to update your Kubernetes deployment with the newly pushed image. This typically involves using `kubectl` commands.

```yaml
      # Example step to run tests
      - name: Run tests
        run: |
          # (Assuming you have a way to run tests within a Docker container or directly)
          cd backend
          pip install -r requirements.txt
          pytest

      # Example step to deploy to Kubernetes
      - name: Deploy to Kubernetes
        uses: actions-hub/kubectl@master
        env:
          KUBE_CONFIG: ${{ secrets.KUBE_CONFIG }} # Your Kubernetes config (base64 encoded)
        with:
          args: rollout restart deployment/backend-deployment
```

CI/CD is a deep topic, but this introduction gives you a solid, practical starting point for automating your Docker workflows.
