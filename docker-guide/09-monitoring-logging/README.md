# Monitoring and Logging for Dockerized Applications

In a production environment, it's not enough to just run your application; you need visibility into its performance and behavior. Monitoring and logging are two pillars of observability that allow you to understand what's happening inside your containers.

## 1. Introduction to Monitoring and Logging

*   **Monitoring:** The process of collecting and analyzing metrics to track the performance and health of your application over time. Key metrics include CPU usage, memory consumption, latency, and error rates.
*   **Logging:** The process of recording discrete events that happen in your application. Logs are crucial for debugging issues and understanding the application's behavior.

For this guide, we'll use a popular, open-source stack:
*   **Prometheus** for metrics collection.
*   **Grafana** for visualization (dashboards).
*   **Loki** for log aggregation.
*   **Promtail** as the log collection agent.

## 2. Monitoring with Prometheus and Grafana

### a. Architecture

1.  **Your Application:** Exposes an HTTP endpoint (e.g., `/metrics`) with its current metrics.
2.  **Prometheus:** Periodically "scrapes" (fetches) the metrics from your application's endpoint and stores them in a time-series database.
3.  **Grafana:** Connects to Prometheus as a data source and allows you to create powerful dashboards to visualize your metrics.

### b. Instrumenting Your Application

First, your application needs to expose metrics. Here's how you can do it in a Python Flask application using the `prometheus-client` library.

**`backend/app_instrumented.py` (Example)**
```python
from flask import Flask
from prometheus_client import Counter, generate_latest, REGISTRY
import time
import random

app = Flask(__name__)

# Create a counter metric
c = Counter('my_app_requests_total', 'Total number of requests received')

@app.route('/')
def hello():
    c.inc() # Increment the counter on each request
    time.sleep(random.uniform(0.1, 0.6)) # Simulate work
    return "Hello from an instrumented Flask App!"

@app.route('/metrics')
def metrics():
    return generate_latest(REGISTRY)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
```
**`backend/requirements.txt` would need:**
```
Flask==2.0.2
prometheus-client==0.11.0
```

## 3. Logging with Loki and Promtail

### a. Architecture

1.  **Your Application:** Writes logs to `stdout` and `stderr` (a Docker best practice).
2.  **Docker Logging Driver:** The Docker daemon captures these logs.
3.  **Promtail:** An agent (running as a container) that is configured to read logs from the Docker daemon or directly from log files. It tails the logs, adds labels, and pushes them to Loki.
4.  **Loki:** A log aggregation system that stores and indexes the logs.
5.  **Grafana:** Connects to Loki as a data source to search and visualize the logs.

Loki is powerful because it uses the same labeling system as Prometheus, allowing you to seamlessly correlate metrics and logs.

## 4. Putting It All Together: A Docker Compose Setup

Here is a `docker-compose.yml` file that sets up a complete monitoring and logging stack for our instrumented Flask application.

**`docker-compose.monitoring.yml`**
```yaml
version: '3.8'

services:
  app:
    build: ./backend
    ports:
      - "5000:5000"
    networks:
      - monitor-net

  prometheus:
    image: prom/prometheus:v2.26.0
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
    ports:
      - "9090:9090"
    networks:
      - monitor-net

  grafana:
    image: grafana/grafana:7.5.7
    ports:
      - "3000:3000"
    volumes:
      - grafana-data:/var/lib/grafana
    networks:
      - monitor-net

  loki:
    image: grafana/loki:2.2.1
    ports:
      - "3100:3100"
    networks:
      - monitor-net

  promtail:
    image: grafana/promtail:2.2.1
    volumes:
      - /var/lib/docker/containers:/var/lib/docker/containers:ro
      - ./promtail-config.yml:/etc/promtail/config.yml
    command: -config.file=/etc/promtail/config.yml
    networks:
      - monitor-net

networks:
  monitor-net:

volumes:
  grafana-data:
```

### Configuration Files:

You would need the following configuration files in the same directory as your `docker-compose.monitoring.yml`.

**`prometheus.yml`**
```yaml
scrape_configs:
  - job_name: 'flask-app'
    static_configs:
      - targets: ['app:5000'] # 'app' is the service name from docker-compose
```

**`promtail-config.yml`**
```yaml
server:
  http_listen_port: 9080
  grpc_listen_port: 0

positions:
  filename: /tmp/positions.yaml

clients:
  - url: http://loki:3100/loki/api/v1/push

scrape_configs:
- job_name: system
  static_configs:
  - targets:
      - localhost
    labels:
      job: varlogs
      __path__: /var/log/*log
- job_name: containers
  static_configs:
    - labels:
        job: containerlogs
        __path__: /var/lib/docker/containers/*/*-json.log
  pipeline_stages:
    - docker: {}
```

## 5. How to Use the Stack

1.  **Launch:** Run `docker-compose -f docker-compose.monitoring.yml up`.
2.  **Generate Traffic:** Access `http://localhost:5000` a few times to generate metrics and logs.
3.  **Prometheus:** Go to `http://localhost:9090`. You can query for your `my_app_requests_total` metric.
4.  **Grafana:**
    *   Go to `http://localhost:3000` (admin/admin).
    *   Add a new **Data Source** for Prometheus (`http://prometheus:9090`).
    *   Add another **Data Source** for Loki (`http://loki:3100`).
    *   Go to the **Explore** tab. You can now switch between your Prometheus metrics and your Loki logs to debug your application.

This setup provides a powerful, integrated view of your application's behavior, which is essential for maintaining and troubleshooting applications in production.
