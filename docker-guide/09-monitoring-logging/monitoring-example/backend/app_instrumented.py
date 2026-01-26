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
