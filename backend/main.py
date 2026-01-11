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


DB_HOST = os.getenv("DB_HOST")      
DB_PORT = os.getenv("DB_PORT")           
DB_NAME = os.getenv("DB_NAME")       
DB_USER = os.getenv("DB_USER")       
DB_PASSWORD = os.getenv("DB_PASSWORD")  

pool: asyncpg.Pool = None


async def init_db():
    global pool
    pool = await asyncpg.create_pool(
        host=DB_HOST,
        port=int(DB_PORT),
        database=DB_NAME,
        user=DB_USER,
        password=DB_PASSWORD,
        min_size=1, 
        max_size=10 
    )

async def close_db():
    global pool
    if pool:
        await pool.close()

@asynccontextmanager
async def lifespan(app: FastAPI):
    await init_db()
    yield
    await close_db()


app = FastAPI(
    title="Webstack API",
    description="Backend API for Kubernetes Webstack project",
    version="1.0.0",
    lifespan=lifespan
)

Instrumentator().instrument(app).expose(app)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], 
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class UserResponse(BaseModel):
    name: str


class ContainerResponse(BaseModel):
    id: str

@app.get("/api/user", response_model=UserResponse)
async def get_user():
    async with pool.acquire() as conn:
        row = await conn.fetchrow("SELECT name FROM users LIMIT 1")
        if not row:
            raise HTTPException(status_code=404, detail="No user found")
        return {"name": row["name"]}


@app.get("/api/id", response_model=ContainerResponse)
async def get_container_id():
    # hiermee krijgen we de container naam van k8s
    return {"id": socket.gethostname()}


@app.get("/api/health")
async def health_check():
    try:
        async with pool.acquire() as conn:
            await conn.fetchval("SELECT 1")
        return {"status": "healthy", "database": "connected"}
    except Exception as e:
        raise HTTPException(status_code=503, detail=f"Unhealthy: {str(e)}")
