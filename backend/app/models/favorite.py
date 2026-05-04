"""
Model: Favorite — Đánh dấu audio yêu thích.

Vì chưa có Auth, dùng bảng global: mỗi audio_track chỉ
có 1 record. Khi thêm Auth sau, sẽ thêm cột user_id.
"""
from datetime import datetime

from sqlalchemy import DateTime, ForeignKey, Integer, UniqueConstraint, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db import Base


class Favorite(Base):
    """Bảng lưu audio được yêu thích."""

    __tablename__ = "favorites"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)

    # FK tới audio_track — cascade xóa khi track bị xóa
    track_id: Mapped[int] = mapped_column(
        Integer,
        ForeignKey("audio_tracks.id", ondelete="CASCADE"),
        nullable=False,
    )

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
    )

    # Relationship để eager load track info
    track = relationship("AudioTrack", lazy="selectin")

    # Mỗi track chỉ có 1 favorite record (global, chưa có user)
    __table_args__ = (
        UniqueConstraint("track_id", name="uq_favorite_track"),
    )

    def __repr__(self) -> str:
        return f"<Favorite track_id={self.track_id}>"
