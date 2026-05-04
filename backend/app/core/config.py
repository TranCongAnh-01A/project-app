"""
Core: Cấu hình hệ thống, biến môi trường.
v0.3 — Chỉ giữ các config cần thiết cho pipeline server-side.
"""
from pydantic_settings import BaseSettings
from functools import lru_cache


class Settings(BaseSettings):
    """Quản lý tập trung biến môi trường qua Pydantic."""

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
