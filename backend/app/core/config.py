"""
Core: Cấu hình hệ thống, bảo mật, biến môi trường.
"""
from pydantic_settings import BaseSettings
from functools import lru_cache


class Settings(BaseSettings):
    """Quản lý tập trung biến môi trường qua Pydantic."""

    # ── Database ──
    DATABASE_URL: str = "postgresql+asyncpg://pmka:pmka_secret@db:5432/pmka_db"

    # ── Redis ──
    REDIS_URL: str = "redis://redis:6379/0"

    # ── Security ──
    SECRET_KEY: str = "dev-secret-key-change-in-production"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60

    # ── Telegram Bot API (Pipeline v2) ──
    TELEGRAM_BOT_TOKEN: str = ""
    TELEGRAM_CHAT_ID: str = ""

    # ── Supabase (Pipeline v2) ──
    SUPABASE_URL: str = ""
    SUPABASE_SERVICE_ROLE_KEY: str = ""

    model_config = {"env_file": ".env", "extra": "ignore"}


@lru_cache
def get_settings() -> Settings:
    """
    Singleton pattern: đọc biến môi trường một lần duy nhất,
    cache lại cho các request sau để tránh đọc file .env lặp lại.
    """
    return Settings()
