# Docker with Python

Containerizing Python applications with Docker brings numerous benefits, including consistent environments, simplified dependency management, and easy deployment across various platforms. This section will guide you through the process of Dockerizing your Python projects, from basic setups to more advanced configurations.

## 1. Basic Python Application

Let's start with a very simple Python application. We'll create a file named `app.py` that simply prints a message.

**`app.py` (example within this section's subdirectory)**
```python
# app.py
import time

print("Hello from inside the Docker container!")
print("This is a Python application.")

for i in range(5):
    print(f"Counting: {i+1}")
    time.sleep(1)

print("Python application finished.")
```

## 2. Basic Dockerfile for Python

A `Dockerfile` contains the instructions to build a Docker image for your Python application.

**`Dockerfile` (example within this section's subdirectory)**
```dockerfile
# Use an official Python runtime as a parent image
FROM python:3.9-slim-buster

# Set the working directory in the container
WORKDIR /app

# Copy the current directory contents into the container at /app
COPY . /app

# Install any needed packages specified in requirements.txt
# If you have a requirements.txt file, uncomment the following lines:
# COPY requirements.txt .
# RUN pip install --no-cache-dir -r requirements.txt

# Run app.py when the container launches
CMD ["python", "app.py"]
```

## 3. Building and Running Your Python Docker Image

Navigate to the directory containing your `app.py` and `Dockerfile`.

1.  **Build the Docker image:**

    ```bash
    docker build -t my-python-app .
    ```
    This command builds an image named `my-python-app` using the `Dockerfile` in the current directory (`.`).

2.  **Run the Docker container:**

    ```bash
    docker run my-python-app
    ```
    You should see the output of your `app.py` script in your terminal.

## 4. Managing Python Dependencies with `requirements.txt`

For most real-world Python applications, you'll have external dependencies. It's best practice to list these in a `requirements.txt` file.

**`requirements.txt` (example within this section's subdirectory)**
```
Flask==2.0.2
gunicorn==20.1.0
```

To incorporate `requirements.txt` into your `Dockerfile`:

```dockerfile
FROM python:3.9-slim-buster

WORKDIR /app

# Copy only requirements.txt first to leverage Docker's build cache
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of your application code
COPY . /app

CMD ["python", "app.py"]
```
By copying `requirements.txt` and installing dependencies *before* copying the rest of the application code, Docker can cache the `pip install` layer. If your application code changes but `requirements.txt` does not, Docker will reuse the cached dependency installation, speeding up subsequent builds.

## 5. Running a Web Application (e.g., Flask)

Let's consider a simple Flask web application.

**`web_app.py` (example within this section's subdirectory)**
```python
# web_app.py
from flask import Flask
import os

app = Flask(__name__)

@app.route('/')
def hello():
    return f"Hello from Flask in a Docker container! Hostname: {os.uname().nodename}\n"

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
```

**`requirements.txt` for Flask app:**
```
Flask==2.0.2
```

**`Dockerfile` for Flask app:**
```dockerfile
FROM python:3.9-slim-buster

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . /app

EXPOSE 5000

CMD ["python", "web_app.py"]
```

**Build and Run the Flask app:**

```bash
docker build -t my-flask-app .
docker run -p 5000:5000 my-flask-app
```
Then, open your browser and navigate to `http://localhost:5000`.

## 6. Best Practices for Python Dockerfiles

*   **Use smaller base images:** `python:3.9-slim-buster` is generally better than `python:3.9` as it contains fewer unnecessary packages, leading to smaller image sizes.
*   **Leverage Docker cache:** Copy `requirements.txt` and install dependencies before copying the rest of the code.
*   **Multi-stage builds:** For complex applications, use multi-stage builds to separate build-time dependencies from runtime dependencies, resulting in even smaller final images.
*   **Non-root user:** Run your application as a non-root user inside the container for security reasons.
*   **Set environment variables:** Use `ENV` instructions to set environment variables for your application.
*   **Optimize `pip`:** Use `pip install --no-cache-dir` to prevent `pip` from storing cached files, reducing image size.
*   **Gunicorn/uWSGI for production:** For production web applications, use a production-ready WSGI server like Gunicorn or uWSGI to run your Flask/Django app instead of the development server.

In the next part, we'll explore how to set up a simple Python project and Dockerize it.
