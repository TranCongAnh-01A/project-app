"""
Model: AudioTrack — Lưu metadata của audio đã nén.

Tại sao lưu metadata vào DB thay vì đọc từ file:
- File system chỉ có video_id.opus, không chứa tên bài, thumbnail, kênh
- DB cho phép search, filter, sort nhanh hơn quét thư mục
- Hỗ trợ custom_name (người dùng đặt tên riêng)
"""
from datetime import datetime

from sqlalchemy import DateTime, Float, Integer, String, func
from sqlalchemy.orm import Mapped, mapped_column

from app.db import Base


class AudioTrack(Base):
    """Bảng lưu thông tin audio đã tải và nén."""

    __tablename__ = "audio_tracks"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)

    # ── Thông tin từ YouTube ──
    video_id: Mapped[str] = mapped_column(String(20), unique=True, index=True)
    title: Mapped[str] = mapped_column(String(500), nullable=False)
    channel_name: Mapped[str] = mapped_column(String(200), nullable=False, default="Unknown")
    thumbnail_url: Mapped[str] = mapped_column(String(1000), nullable=True)

    # ── Thông tin người dùng ──
    custom_name: Mapped[str | None] = mapped_column(String(500), nullable=True)

    # ── Thông tin file ──
    filename: Mapped[str] = mapped_column(String(100), nullable=False)
    size_bytes: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    original_size_bytes: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    compression_ratio: Mapped[float] = mapped_column(Float, nullable=False, default=0.0)

    # ── Timestamps ──
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
    )

    def __repr__(self) -> str:
        return f"<AudioTrack {self.video_id}: {self.display_name}>"

    @property
    def display_name(self) -> str:
        """Trả về tên hiển thị: ưu tiên custom_name, fallback title."""
        return self.custom_name or self.title
