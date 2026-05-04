"""
PMKA Backend - Điểm khởi chạy FastAPI.
Đăng ký API routers + mount static + khởi tạo DB.
"""
import os
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from app.api.v1 import ingest

STORAGE_DIR = os.getenv("STORAGE_DIR", "/app/storage")


@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    Lifecycle hook: chạy khi server khởi động.
    """
    print("[STARTUP] V0.3 - Using Supabase Direct, skipping local DB init.")
    yield
    print("[SHUTDOWN] Server tắt.")


app = FastAPI(
    title="PMKA API",
    description="Personal Media & Knowledge Archiver",
    version="0.2.0",
    lifespan=lifespan,
)

# Cho phép Admin-Web và Mobile truy cập API
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # TODO: Thu hẹp origins cho production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Mount thư mục storage để phục vụ file tĩnh (streaming audio)
os.makedirs(STORAGE_DIR, exist_ok=True)
app.mount("/static", StaticFiles(directory=STORAGE_DIR), name="static")

# Đăng ký tất cả API routers với prefix /api/v1
app.include_router(ingest.router, prefix="/api/v1")


@app.get("/health")
async def health_check():
    """Endpoint kiểm tra trạng thái server."""
    return {"status": "ok", "service": "pmka-backend", "version": "0.2.0"}
