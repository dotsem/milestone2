# Frontend Dockerfile for Kubernetes Webstack
# ============================================
# This Dockerfile creates a container image for the Nginx frontend.
#
# BUILD COMMAND:
#   docker build -t svb-frontend:latest ./frontend
#
# WHY NGINX?
# - Nginx is a high-performance web server
# - Very lightweight (~20MB Alpine image)
# - Perfect for serving static files (HTML, CSS, JS)
# - Can also act as a reverse proxy (though we use Ingress for that in K8s)

# ==============================================================================
# BASE IMAGE
# ==============================================================================
# Using Nginx Alpine variant for minimal image size
# WHY Alpine?
# - nginx:alpine is only ~40MB compared to ~140MB for the full image
# - Alpine Linux is security-focused with minimal attack surface
FROM nginx:1.25-alpine

# ==============================================================================
# COPY STATIC FILES
# ==============================================================================
# Copy our HTML file to Nginx's default web root
# WHY /usr/share/nginx/html?
# - This is Nginx's default document root
# - The default nginx.conf serves files from this directory
COPY index.html /usr/share/nginx/html/index.html

# ==============================================================================
# COPY CUSTOM NGINX CONFIGURATION
# ==============================================================================
# Copy our custom Nginx configuration that includes API proxying
# WHY custom config?
# - We need to proxy /api/* requests to the backend
# - This enables the frontend to make API calls without CORS issues
# - The default nginx.conf doesn't include proxy settings
COPY nginx.conf /etc/nginx/conf.d/default.conf

# ==============================================================================
# EXPOSE PORT
# ==============================================================================
# Document that the container listens on port 80
# WHY 80?
# - This is the standard HTTP port
# - Nginx's default configuration listens on port 80
EXPOSE 80

# ==============================================================================
# RUN COMMAND
# ==============================================================================
# Nginx runs automatically when the container starts
# The default CMD from the base image is: nginx -g 'daemon off;'
# WHY 'daemon off'?
# - Containers need a foreground process to stay running
# - By default, Nginx runs as a daemon (background)
# - 'daemon off' keeps it in the foreground
