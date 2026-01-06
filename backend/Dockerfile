# Backend Dockerfile for Kubernetes Webstack
# ===========================================
# This Dockerfile creates a container image for the FastAPI backend.
#
# BUILD COMMAND:
#   docker build -t svb-backend:latest ./backend
#
# WHY THESE CHOICES?
# - python:3.12-slim: Smaller image size than full Python, but includes pip
# - Multi-stage build could be used for even smaller images, but adds complexity

# ==============================================================================
# BASE IMAGE
# ==============================================================================
# Using Python 3.12 slim variant
# WHY slim?
# - Full python image: ~1GB
# - slim variant: ~150MB  
# - alpine variant: Even smaller but can have compatibility issues with some packages
FROM python:3.12-slim

# ==============================================================================
# WORKING DIRECTORY
# ==============================================================================
# Set the working directory inside the container
# All subsequent commands will run from this directory
WORKDIR /app

# ==============================================================================
# INSTALL DEPENDENCIES
# ==============================================================================
# Copy requirements first (Docker layer caching optimization)
# WHY copy requirements.txt separately?
# - Docker caches each layer
# - If only code changes (not dependencies), Docker reuses the cached layer
# - This speeds up subsequent builds significantly
COPY requirements.txt .

# Install Python dependencies
# WHY --no-cache-dir?
# - Reduces image size by not caching pip packages
# - We don't need the cache in the final image
RUN pip install --no-cache-dir -r requirements.txt

# ==============================================================================
# COPY APPLICATION CODE
# ==============================================================================
# Copy the rest of the application code
COPY main.py .

# ==============================================================================
# EXPOSE PORT
# ==============================================================================
# Document that the container listens on port 8000
# WHY 8000?
# - This is Uvicorn's default port
# - EXPOSE doesn't publish the port, it's documentation
EXPOSE 8000

# ==============================================================================
# HEALTH CHECK
# ==============================================================================
# Built-in Docker health check
# WHY?
# - Docker can monitor container health
# - Useful for docker-compose and standalone Docker
# - Kubernetes uses its own probes, but this is good for Docker-only deployments
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/api/health')" || exit 1

# ==============================================================================
# RUN COMMAND
# ==============================================================================
# Start the FastAPI application with Uvicorn
# WHY these flags?
# - --host 0.0.0.0: Listen on all network interfaces (required for containers)
# - --port 8000: The port to listen on
# - main:app: The module:variable pattern (main.py, app = FastAPI())
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
