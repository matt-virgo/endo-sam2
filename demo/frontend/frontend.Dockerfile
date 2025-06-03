# Stage 1: Build Stage
FROM node:22.9.0 AS build

WORKDIR /app

# Copy package.json and yarn.lock
COPY package.json ./
COPY yarn.lock ./

# Install dependencies
RUN yarn install --frozen-lockfile

# Copy source code
COPY . .

# Build the application
RUN yarn build

# Stage 2: Serve the application with Nginx
FROM nginx:latest

# Remove default Nginx configuration
RUN rm /etc/nginx/conf.d/default.conf

# Create directories for SSL certificates and Nginx snippets
RUN mkdir -p /etc/nginx/snippets /etc/ssl/certs /etc/ssl/private

# Copy custom Nginx configuration files
COPY default.conf /etc/nginx/conf.d/default.conf
COPY self-signed.conf /etc/nginx/snippets/self-signed.conf

# Copy SSL certificates and key
COPY ssl/nginx-selfsigned.crt /etc/ssl/certs/nginx-selfsigned.crt
COPY ssl/nginx-selfsigned.key /etc/ssl/private/nginx-selfsigned.key
COPY ssl/dhparam.pem /etc/ssl/certs/dhparam.pem

# Copy the built application from the build stage
COPY --from=build /app/dist /usr/share/nginx/html

# Expose port 443 for HTTPS and 80 for HTTP (which will redirect)
EXPOSE 80
EXPOSE 443

# Command to run Nginx
CMD ["nginx", "-g", "daemon off;"]
