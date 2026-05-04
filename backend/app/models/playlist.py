"""
Model: Playlist — Danh sách phát do người dùng tạo.

Quan hệ N-N với AudioTrack thông qua bảng liên kết playlist_tracks.
Vì chưa có Auth, toàn bộ playlists là Global (chung cho tất cả).
"""
from datetime import datetime

from sqlalchemy import Column, DateTime, ForeignKey, Integer, String, Table, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db import Base


# Bảng liên kết N-N: playlist <-> audio_track
playlist_tracks = Table(
    "playlist_tracks",
    Base.metadata,
    Column("playlist_id", Integer, ForeignKey("playlists.id", ondelete="CASCADE"), primary_key=True),
    Column("track_id", Integer, ForeignKey("audio_tracks.id", ondelete="CASCADE"), primary_key=True),
    Column("added_at", DateTime(timezone=True), server_default=func.now()),
)


class Playlist(Base):
    """Bảng lưu danh sách phát."""

    __tablename__ = "playlists"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    name: Mapped[str] = mapped_column(String(200), nullable=False)

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
    )

    # Quan hệ N-N với AudioTrack
    tracks = relationship(
        "AudioTrack",
        secondary=playlist_tracks,
        backref="playlists",
        lazy="selectin",
    )

    def __repr__(self) -> str:
        return f"<Playlist {self.id}: {self.name}>"
