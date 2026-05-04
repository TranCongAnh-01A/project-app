"""
Database: Kết nối PostgreSQL async qua SQLAlchemy 2.0.

Tại sao dùng async:
- FastAPI chạy trên event loop (asyncio), dùng async DB driver
  tránh block event loop khi query
- asyncpg nhanh hơn psycopg2 khoảng 3x cho async workload

Tại sao chia engine vs session:
- Engine quản lý connection pool (tạo 1 lần duy nhất)
- Session quản lý transaction scope (tạo mới mỗi request)
"""
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine
from sqlalchemy.orm import DeclarativeBase, sessionmaker

from app.core.config import get_settings

settings = get_settings()

# Tạo async engine — connection pool mặc định 5, max overflow 10
engine = create_async_engine(
    settings.DATABASE_URL,
    echo=False,     # True để debug SQL queries
    pool_size=5,
    max_overflow=10,
)

# Session factory — mỗi request tạo 1 session mới
async_session = sessionmaker(
    engine,
    class_=AsyncSession,
    expire_on_commit=False,  # Không expire object sau commit (tránh lazy load lỗi async)
)


class Base(DeclarativeBase):
    """Base class cho tất cả SQLAlchemy models."""


async def get_db() -> AsyncSession:
    """
    Dependency Injection: Tạo DB session cho mỗi request.
    FastAPI sẽ tự động close session sau khi request xử lý xong.
    """
    async with async_session() as session:
        try:
            yield session
        finally:
            await session.close()


async def init_db():
    """
    Tạo tất cả bảng từ models (chỉ dùng cho dev).
    Production nên dùng Alembic migration.
    """
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
