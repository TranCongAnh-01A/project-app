"""
API Endpoints: Quản lý audio yêu thích (Favorites).
- POST /favorite/{video_id}: Toggle yêu thích (thêm/xóa)
- GET /favorites: Lấy danh sách yêu thích
"""
import os
import logging

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db import get_db
from app.models.audio_track import AudioTrack
from app.models.favorite import Favorite

router = APIRouter(prefix="/favorites", tags=["Favorites"])
logger = logging.getLogger(__name__)

STATIC_BASE = os.getenv("STATIC_BASE_URL", "/static")


# ── Schemas ──

class FavoriteItemResponse(BaseModel):
    """Schema cho audio yêu thích."""
    video_id: str
    title: str
    custom_name: str | None
    channel_name: str
    thumbnail_url: str | None
    size_mb: float
    stream_url: str

    model_config = {"from_attributes": True}


class FavoriteListResponse(BaseModel):
    total: int
    items: list[FavoriteItemResponse]


class ToggleFavoriteResponse(BaseModel):
    video_id: str
    is_favorite: bool
    message: str


# ── Endpoints ──

@router.post("/{video_id}", response_model=ToggleFavoriteResponse)
async def toggle_favorite(
    video_id: str,
    db: AsyncSession = Depends(get_db),
):
    """
    Toggle yêu thích: nếu chưa có → thêm, nếu đã có → xóa.
    Thiết kế toggle thay vì tách add/remove:
    - Đơn giản hóa UI (1 nút duy nhất)
    - Giảm logic xử lý phía client
    """
    # Tìm track trong DB
    result = await db.execute(
        select(AudioTrack).filter_by(video_id=video_id)
    )
    track = result.scalar_one_or_none()

    if not track:
        raise HTTPException(status_code=404, detail=f"Không tìm thấy audio: {video_id}")

    # Kiểm tra đã favorite chưa
    fav_result = await db.execute(
        select(Favorite).filter_by(track_id=track.id)
    )
    existing_fav = fav_result.scalar_one_or_none()

    if existing_fav:
        # Đã có → xóa (bỏ yêu thích)
        await db.delete(existing_fav)
        await db.commit()
        return ToggleFavoriteResponse(
            video_id=video_id,
            is_favorite=False,
            message="Đã bỏ yêu thích",
        )
    else:
        # Chưa có → thêm
        new_fav = Favorite(track_id=track.id)
        db.add(new_fav)
        await db.commit()
        return ToggleFavoriteResponse(
            video_id=video_id,
            is_favorite=True,
            message="Đã thêm vào yêu thích",
        )


@router.get("/", response_model=FavoriteListResponse)
async def list_favorites(db: AsyncSession = Depends(get_db)):
    """Lấy danh sách audio đã yêu thích."""
    result = await db.execute(
        select(Favorite).order_by(Favorite.created_at.desc())
    )
    favorites = result.scalars().all()

    items = []
    for fav in favorites:
        track = fav.track
        if track:
            items.append(FavoriteItemResponse(
                video_id=track.video_id,
                title=track.display_name,
                custom_name=track.custom_name,
                channel_name=track.channel_name,
                thumbnail_url=track.thumbnail_url,
                size_mb=round(track.size_bytes / 1_048_576, 2),
                stream_url=f"{STATIC_BASE}/{track.filename}",
            ))

    return FavoriteListResponse(total=len(items), items=items)
