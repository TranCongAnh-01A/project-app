"""
API Endpoints: Quản lý danh sách audio/truyện.
Mobile gọi các endpoint này để hiển thị thư viện và xóa file.

Nâng cấp v2:
- Search: tìm theo tên audio hoặc tên kênh
- Sort: sắp xếp theo created_at, title, size
"""
import os
from pathlib import Path
from typing import Literal

from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel
from sqlalchemy import or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db import get_db
from app.models.audio_track import AudioTrack
from app.models.favorite import Favorite

router = APIRouter(prefix="/content", tags=["Content"])

STORAGE_DIR = Path(os.getenv("STORAGE_DIR", "/app/storage"))
STATIC_BASE = os.getenv("STATIC_BASE_URL", "/static")


# ── Schemas ──

class AudioItemResponse(BaseModel):
    """Schema cho một audio item trong danh sách."""
    video_id: str
    filename: str
    title: str
    custom_name: str | None
    channel_name: str
    thumbnail_url: str | None
    size_mb: float
    stream_url: str
    created_at: str
    is_favorite: bool = False

    model_config = {"from_attributes": True}


class AudioListResponse(BaseModel):
    """Schema response danh sách audio."""
    total: int
    items: list[AudioItemResponse]


# ── Endpoints ──

@router.get("/audio", response_model=AudioListResponse)
async def list_audio(
    search: str | None = Query(
        None,
        description="Tìm theo tên audio hoặc tên kênh",
        min_length=1,
        max_length=100,
    ),
    sort_by: Literal["newest", "oldest", "title_asc", "title_desc", "size_asc", "size_desc"] = Query(
        "newest",
        description="Thứ tự sắp xếp",
    ),
    db: AsyncSession = Depends(get_db),
):
    """
    Lấy danh sách audio từ DB.
    Hỗ trợ search (tìm kiếm) và sort (sắp xếp).

    Tham số sort_by:
    - newest: Mới nhất (mặc định)
    - oldest: Cũ nhất
    - title_asc: Tên A-Z
    - title_desc: Tên Z-A
    - size_asc: Nhẹ nhất
    - size_desc: Nặng nhất
    """
    # Xây dựng query cơ sở
    query = select(AudioTrack)

    # Áp dụng search filter (tìm trong title, custom_name, channel_name)
    if search:
        search_pattern = f"%{search}%"
        query = query.where(
            or_(
                AudioTrack.title.ilike(search_pattern),
                AudioTrack.custom_name.ilike(search_pattern),
                AudioTrack.channel_name.ilike(search_pattern),
            )
        )

    # Áp dụng sort
    sort_mapping = {
        "newest": AudioTrack.created_at.desc(),
        "oldest": AudioTrack.created_at.asc(),
        "title_asc": AudioTrack.title.asc(),
        "title_desc": AudioTrack.title.desc(),
        "size_asc": AudioTrack.size_bytes.asc(),
        "size_desc": AudioTrack.size_bytes.desc(),
    }
    query = query.order_by(sort_mapping[sort_by])

    result = await db.execute(query)
    tracks = result.scalars().all()

    # Lấy danh sách favorite track_ids (1 query duy nhất)
    fav_result = await db.execute(select(Favorite.track_id))
    fav_track_ids = {row for row in fav_result.scalars().all()}

    items = []
    for track in tracks:
        items.append(AudioItemResponse(
            video_id=track.video_id,
            filename=track.filename,
            title=track.title,
            custom_name=track.custom_name,
            channel_name=track.channel_name,
            thumbnail_url=track.thumbnail_url,
            size_mb=round(track.size_bytes / 1_048_576, 2),
            stream_url=f"{STATIC_BASE}/{track.filename}",
            created_at=track.created_at.isoformat() if track.created_at else "",
            is_favorite=track.id in fav_track_ids,
        ))

    return AudioListResponse(total=len(items), items=items)


@router.delete("/audio/{video_id}")
async def delete_audio(
    video_id: str,
    db: AsyncSession = Depends(get_db),
):
    """Xóa file .opus + xóa record DB theo video_id."""
    # Chặn path traversal
    if "/" in video_id or "\\" in video_id or ".." in video_id:
        raise HTTPException(status_code=400, detail="video_id không hợp lệ")

    result = await db.execute(
        select(AudioTrack).filter_by(video_id=video_id)
    )
    track = result.scalar_one_or_none()

    # Xóa file từ disk
    file_path = STORAGE_DIR / f"{video_id}.opus"
    if file_path.exists():
        try:
            file_path.unlink()
        except OSError as exc:
            raise HTTPException(status_code=500, detail=f"Lỗi xóa file: {exc}")

    # Xóa record DB (cascade xóa favorite + playlist_tracks)
    if track:
        await db.delete(track)
        await db.commit()

    if not track and not file_path.exists():
        raise HTTPException(status_code=404, detail=f"Không tìm thấy: {video_id}")

    return {
        "message": f"Đã xóa: {video_id}.opus",
        "video_id": video_id,
    }


@router.get("/text")
async def list_text():
    """Lấy danh sách truyện/bài viết đã lưu."""
    # TODO: Query DB → trả về danh sách
    return {"items": []}
