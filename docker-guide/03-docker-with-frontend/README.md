# Docker with Frontend Applications

Dockerizing frontend applications, especially those built with frameworks like React, Angular, or Vue, offers significant advantages. It ensures consistent build environments, simplifies deployment, and allows for easier integration with backend services. This section will guide you through containerizing a simple React application.

## 1. Basic Frontend Application (React Example)

Let's assume you have a basic React application. You can create one using `create-react-app`:

```bash
npx create-react-app my-react-app
cd my-react-app
```
For this guide, we'll focus on the files usually present: `package.json`, `package-lock.json` (or `yarn.lock`), and the `src` directory.

## 2. Basic Dockerfile for a React Application

A common approach for Dockerizing frontend applications involves a multi-stage build. This allows you to use a Node.js image to build your application and then serve the static assets using a lightweight web server like Nginx, resulting in a much smaller final image.

**`Dockerfile` (example within this section's subdirectory)**
```dockerfile
# --- Stage 1: Build the React application ---
FROM node:16-alpine as build

WORKDIR /app

# Copy package.json and package-lock.json to install dependencies
COPY package.json ./
COPY yarn.lock ./ # Use package-lock.json if you are using npm

RUN yarn install --frozen-lockfile # Or `npm install` if using npm

# Copy the rest of the application code
COPY . .

# Build the React application for production
RUN yarn build # Or `npm run build`

# --- Stage 2: Serve the application with Nginx ---
FROM nginx:alpine

# Copy the built React app from the build stage to Nginx's public directory
COPY --from=build /app/build /usr/share/nginx/html

# Copy a custom Nginx configuration (optional, but good for SPAs)
# COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
```

**`nginx.conf` (Optional, for Single Page Applications - SPAs)**
If your frontend is a Single Page Application (like most React, Angular, Vue apps), you might need an Nginx configuration that redirects all traffic to `index.html` to handle client-side routing.

```nginx
server {
  listen 80;

  location / {
    root /usr/share/nginx/html;
    index index.html index.htm;
    try_files $uri $uri/ /index.html;
  }

  error_page 500 502 503 504 /50x.html;
  location = /50x.html {
    root /usr/share/nginx/html;
  }
}
```

## 3. Building and Running Your Frontend Docker Image

Navigate to the root directory of your React application (where `package.json` and `Dockerfile` are located).

1.  **Build the Docker image:**

    ```bash
    docker build -t my-react-app-frontend .
    ```
    This command builds a multi-stage image named `my-react-app-frontend`.

2.  **Run the Docker container:**

    ```bash
    docker run -p 80:80 my-react-app-frontend
    ```
    Open your browser and navigate to `http://localhost`. You should see your React application running.

## 4. Development Workflow with Docker (Live Reloading)

For development, you often want live reloading and faster build times. While Docker can be used for development, it often adds overhead for frontend apps compared to local development servers.

A common pattern is:
*   **Develop locally:** Run your frontend development server directly on your machine (`npm start` or `yarn start`).
*   **Dockerize for production:** Use the multi-stage build `Dockerfile` for production deployments.

If you *must* use Docker for development, you can use volume mounts to synchronize code changes:

```dockerfile
# Development Dockerfile (e.g., Dockerfile.dev)
FROM node:16-alpine

WORKDIR /app

COPY package.json ./
COPY yarn.lock ./

RUN yarn install

COPY . .

EXPOSE 3000 # Default port for create-react-app

CMD ["yarn", "start"] # Or `npm start`
```

**Building and Running for Development:**

```bash
docker build -f Dockerfile.dev -t my-react-app-dev .
docker run -p 3000:3000 -v $(pwd):/app my-react-app-dev
```
The `-v $(pwd):/app` part mounts your local project directory into the container, so changes made locally are reflected inside the container.

## 5. Best Practices for Frontend Dockerfiles

*   **Multi-stage builds:** Always use multi-stage builds for production to keep final image sizes small.
*   **Optimize dependency caching:** Copy `package.json` (and lock files) and install dependencies as a separate layer to leverage Docker's build cache.
*   **Use lightweight base images:** `node:alpine` and `nginx:alpine` are excellent choices for their small footprint.
*   **Environment variables:** Use `ARG` for build-time variables and `ENV` for runtime variables (e.g., API endpoints).
*   **Serve static files efficiently:** Use a dedicated web server like Nginx for serving static frontend assets in production.
*   **Minify and bundle:** Ensure your build process includes minification and bundling of assets to optimize performance.

This section provides a solid foundation for Dockerizing your frontend applications. In the next section, we'll dive into more advanced Docker concepts.
