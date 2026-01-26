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
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
