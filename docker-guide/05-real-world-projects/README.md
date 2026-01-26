# Real-world Projects

This section brings together all the concepts learned so far to build a more complex, multi-service application. We will design a simple full-stack application and demonstrate how to orchestrate its various components using Docker Compose. This approach mirrors how many modern applications are developed and deployed.

## Project Idea: A Simple Full-Stack To-Do Application

We will create a basic To-Do application with the following components:

*   **Frontend:** A React.js application (as covered in the "Docker with Frontend" section)
*   **Backend:** A Python Flask API (as covered in the "Docker with Python" section)
*   **Database:** A PostgreSQL database

The frontend will communicate with the Flask API, which in turn will interact with the PostgreSQL database to store and retrieve To-Do items.

## Architecture Overview

```
+----------------+       +---------------+       +---------------+
|    Frontend    | ----> |    Backend    | ----> |   Database    |
| (React/Nginx)  |       |    (Flask)    |       | (PostgreSQL)  |
+----------------+       +---------------+       +---------------+
        ^                        ^
        |                        |
        +------------------------+
             Docker Network
```

Each component will run in its own Docker container, managed by a single `docker-compose.yml` file.

## Recommended Directory Structure

```
.
├── docker-compose.yml
├── frontend/
│   ├── Dockerfile
│   ├── nginx.conf
│   ├── package.json
│   ├── yarn.lock
│   └── src/... (React app files)
└── backend/
    ├── Dockerfile
    ├── requirements.txt
    └── app.py (Flask API)
```

## `docker-compose.yml` for the Full-Stack Application

This `docker-compose.yml` orchestrates all three services:

**`docker-compose.yml` (example within this section's subdirectory)**
```yaml
version: '3.8'

services:
  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile
    ports:
      - "80:80"
    depends_on:
      - backend
    networks:
      - app-network

  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile
    ports:
      - "5000:5000"
    environment:
      DATABASE_URL: postgresql://user:password@db:5432/mydatabase
    depends_on:
      - db
    networks:
      - app-network

  db:
    image: postgres:13
    environment:
      POSTGRES_DB: mydatabase
      POSTGRES_USER: user
      POSTGRES_PASSWORD: password
    volumes:
      - db-data:/var/lib/postgresql/data
    networks:
      - app-network

networks:
  app-network:
    driver: bridge

volumes:
  db-data:
```

## Setup and Run Instructions

1.  **Create the project directories:**
    Make sure you have the `frontend` and `backend` directories as described in the `Recommended Directory Structure` above. You would place your React application files inside `frontend/src` and your Flask application files inside `backend`.

2.  **Populate `frontend/Dockerfile` and `nginx.conf`:**
    Use the `Dockerfile` and `nginx.conf` provided in the "Docker with Frontend" section.

3.  **Populate `backend/Dockerfile`, `requirements.txt`, and `app.py`:**
    *   **`backend/Dockerfile`**:
        ```dockerfile
        FROM python:3.9-slim-buster
        WORKDIR /app
        COPY requirements.txt .
        RUN pip install --no-cache-dir -r requirements.txt
        COPY . .
        CMD ["python", "app.py"]
        ```
    *   **`backend/requirements.txt`**:
        ```
        Flask==2.0.2
        psycopg2-binary==2.9.1 # For PostgreSQL
        ```
    *   **`backend/app.py`**:
        A simple Flask app connecting to PostgreSQL:
        ```python
        from flask import Flask, jsonify, request
        import os
        import psycopg2

        app = Flask(__name__)

        def get_db_connection():
            conn = psycopg2.connect(os.environ.get("DATABASE_URL"))
            return conn

        @app.route('/')
        def hello():
            return "Hello from Flask Backend!"

        @app.route('/todos', methods=['GET', 'POST'])
        def todos():
            conn = get_db_connection()
            cur = conn.cursor()
            if request.method == 'POST':
                data = request.json
                cur.execute("INSERT INTO todos (title) VALUES (%s)", (data['title'],))
                conn.commit()
                cur.close()
                conn.close()
                return jsonify({"message": "Todo added!"}), 201
            else:
                cur.execute("SELECT * FROM todos")
                todos = cur.fetchall()
                cur.close()
                conn.close()
                return jsonify(todos)

        if __name__ == '__main__':
            # Initialize database table (for simplicity, run once on start)
            conn = get_db_connection()
            cur = conn.cursor()
            cur.execute("""
                CREATE TABLE IF NOT EXISTS todos (
                    id SERIAL PRIMARY KEY,
                    title VARCHAR NOT NULL,
                    completed BOOLEAN DEFAULT FALSE
                );
            """)
            conn.commit()
            cur.close()
            conn.close()

            app.run(host='0.0.0.0', port=5000)
        ```
        *Note: For a real application, database migrations should be handled more robustly.*

4.  **Run the application:**
    Navigate to the root directory where `docker-compose.yml` is located and run:
    ```bash
    docker-compose up --build
    ```
    This command will build the images for your frontend and backend services (if they haven't been built or if their `Dockerfile` or context has changed) and start all the services.

5.  **Access the application:**
    Open your web browser and go to `http://localhost`. You should see your React frontend. The frontend will then communicate with your Flask backend, which will use the PostgreSQL database.

## Further Enhancements

*   **Add Authentication:** Implement user authentication for the To-Do application.
*   **More Robust Database Setup:** Use a dedicated migration tool for database schema changes.
*   **Testing:** Add unit and integration tests for both frontend and backend.
*   **CI/CD Pipeline:** Automate building, testing, and deploying your Dockerized application.
*   **Monitoring and Logging:** Integrate monitoring tools and a centralized logging solution.

This project demonstrates the power of Docker Compose in bringing together multiple services to form a complete application.
