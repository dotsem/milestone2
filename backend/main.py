# Backend (FastAPI) Application for Kubernetes Webstack
# ======================================================
# This is the main FastAPI application that serves as the API layer.
#
# WHY FASTAPI?
# - FastAPI is a modern, high-performance Python web framework.
# - It provides automatic OpenAPI documentation.
# - Easy integration with async database drivers.
# - Built-in data validation using Pydantic.
#
# ENDPOINTS:
# - GET /api/user  : Returns the user name from the database.
# - GET /api/id    : Returns the container/pod hostname (for load balancing demo).
# - GET /api/health: Health check endpoint for Kubernetes probes.

import os
import socket
import asyncpg
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from prometheus_fastapi_instrumentator import Instrumentator
from pydantic import BaseModel
from contextlib import asynccontextmanager
from dotenv import load_dotenv

load_dotenv()

# ==============================================================================
# CONFIGURATION FROM ENVIRONMENT VARIABLES
# ==============================================================================
# These values are injected via Kubernetes ConfigMaps and Secrets.
# This follows the 12-Factor App methodology for configuration.

DB_HOST = os.getenv("DB_HOST")      # Database hostname (K8s Service name)
DB_PORT = os.getenv("DB_PORT")           # Database port
DB_NAME = os.getenv("DB_NAME")       # Database name
DB_USER = os.getenv("DB_USER")       # Database user
DB_PASSWORD = os.getenv("DB_PASSWORD")  # Database password (from Secret)

# ==============================================================================
# DATABASE CONNECTION POOL
# ==============================================================================
# We use a connection pool for efficiency. This is created on startup.
pool: asyncpg.Pool = None


async def init_db():
    """
    Initialize the database: create the table if it doesn't exist,
    and insert a default row if the table is empty.
    """
    global pool
    # Create connection pool
    # WHY asyncpg?
    # - It's the fastest PostgreSQL driver for Python.
    # - Native async support works perfectly with FastAPI's async nature.
    pool = await asyncpg.create_pool(
        host=DB_HOST,
        port=int(DB_PORT),
        database=DB_NAME,
        user=DB_USER,
        password=DB_PASSWORD,
        min_size=1,  # Minimum connections in pool
        max_size=10  # Maximum connections in pool
    )

    # Create table if not exists
    async with pool.acquire() as conn:
        await conn.execute("""
            CREATE TABLE IF NOT EXISTS settings (
                id SERIAL PRIMARY KEY,
                name VARCHAR(255) NOT NULL
            )
        """)
        # Insert default value if table is empty
        count = await conn.fetchval("SELECT COUNT(*) FROM settings")
        if count == 0:
            await conn.execute("INSERT INTO settings (name) VALUES ($1)", "Student")


async def close_db():
    """Close the database connection pool on shutdown."""
    global pool
    if pool:
        await pool.close()


# ==============================================================================
# FASTAPI APPLICATION SETUP
# ==============================================================================

@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    Lifespan context manager for startup/shutdown events.
    WHY? FastAPI recommends this over deprecated @app.on_event decorators.
    """
    await init_db()
    yield
    await close_db()


app = FastAPI(
    title="Webstack API",
    description="Backend API for Kubernetes Webstack project",
    version="1.0.0",
    lifespan=lifespan
)

# Instrument the app object to expose Prometheus metrics
Instrumentator().instrument(app).expose(app)

# ==============================================================================
# CORS MIDDLEWARE
# ==============================================================================
# Cross-Origin Resource Sharing (CORS) allows the frontend to call this API.
# WHY?
# - Even with Ingress routing, browsers may still check CORS headers.
# - This is a security best practice.

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, specify exact origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ==============================================================================
# PYDANTIC MODELS
# ==============================================================================
# These define the request/response schemas for our API.

class UserResponse(BaseModel):
    """Response model for user endpoint."""
    name: str


class ContainerResponse(BaseModel):
    """Response model for container ID endpoint."""
    id: str


class UserUpdate(BaseModel):
    """Request model for updating user name."""
    name: str


# ==============================================================================
# API ENDPOINTS
# ==============================================================================

@app.get("/api/user", response_model=UserResponse)
async def get_user():
    """
    GET /api/user
    Returns the current user name from the database.

    This endpoint is called by the frontend to display the user name.
    When the name changes in the database, refreshing the page will show
    the updated name.
    """
    async with pool.acquire() as conn:
        row = await conn.fetchrow("SELECT name FROM settings LIMIT 1")
        if not row:
            raise HTTPException(status_code=404, detail="No user found")
        return {"name": row["name"]}


@app.get("/api/id", response_model=ContainerResponse)
async def get_container_id():
    """
    GET /api/id
    Returns the container/pod hostname.

    WHY?
    - In Kubernetes, each pod has a unique hostname.
    - This endpoint demonstrates load balancing: when multiple replicas
      are running, different requests may hit different pods.
    - The frontend displays this to show which backend instance responded.
    """
    # socket.gethostname() returns the pod name in Kubernetes
    return {"id": socket.gethostname()}


@app.get("/api/health")
async def health_check():
    """
    GET /api/health
    Health check endpoint for Kubernetes probes.

    WHY?
    - Kubernetes uses this to determine if the pod is healthy.
    - Liveness probe: If this fails, Kubernetes restarts the pod.
    - Readiness probe: If this fails, Kubernetes removes the pod from
      the service load balancer.
    """
    # Check database connectivity
    try:
        async with pool.acquire() as conn:
            await conn.fetchval("SELECT 1")
        return {"status": "healthy", "database": "connected"}
    except Exception as e:
        raise HTTPException(status_code=503, detail=f"Unhealthy: {str(e)}")
