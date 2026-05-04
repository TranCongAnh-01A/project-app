"""
API Endpoints: Quản lý Playlists.
- POST /playlists: Tạo playlist mới
- GET /playlists: Liệt kê playlists
- GET /playlists/{id}: Chi tiết playlist + danh sách tracks
- POST /playlists/{id}/tracks/{video_id}: Thêm track vào playlist
- DELETE /playlists/{id}/tracks/{video_id}: Xóa track khỏi playlist
- DELETE /playlists/{id}: Xóa playlist
"""
import os
import logging

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db import get_db
from app.models.audio_track import AudioTrack
from app.models.playlist import Playlist

router = APIRouter(prefix="/playlists", tags=["Playlists"])
logger = logging.getLogger(__name__)

STATIC_BASE = os.getenv("STATIC_BASE_URL", "/static")


# ── Schemas ──

class CreatePlaylistRequest(BaseModel):
    name: str


class PlaylistResponse(BaseModel):
    id: int
    name: str
    track_count: int
    created_at: str

    model_config = {"from_attributes": True}


class TrackInPlaylistResponse(BaseModel):
    video_id: str
    title: str
    custom_name: str | None
    channel_name: str
    thumbnail_url: str | None
    stream_url: str


class PlaylistDetailResponse(BaseModel):
    id: int
    name: str
    created_at: str
    tracks: list[TrackInPlaylistResponse]


class PlaylistListResponse(BaseModel):
    total: int
    items: list[PlaylistResponse]


# ── Endpoints ──

@router.post("/", response_model=PlaylistResponse, status_code=201)
async def create_playlist(
    request: CreatePlaylistRequest,
    db: AsyncSession = Depends(get_db),
):
    """Tạo playlist mới."""
    playlist = Playlist(name=request.name.strip())
    db.add(playlist)
    await db.commit()
    await db.refresh(playlist)

    return PlaylistResponse(
        id=playlist.id,
        name=playlist.name,
        track_count=0,
        created_at=playlist.created_at.isoformat(),
    )


@router.get("/", response_model=PlaylistListResponse)
async def list_playlists(db: AsyncSession = Depends(get_db)):
    """Liệt kê toàn bộ playlists."""
    result = await db.execute(
        select(Playlist).order_by(Playlist.created_at.desc())
    )
    playlists = result.scalars().all()

    items = [
        PlaylistResponse(
            id=pl.id,
            name=pl.name,
            track_count=len(pl.tracks),
            created_at=pl.created_at.isoformat(),
        )
        for pl in playlists
    ]

    return PlaylistListResponse(total=len(items), items=items)


@router.get("/{playlist_id}", response_model=PlaylistDetailResponse)
async def get_playlist(
    playlist_id: int,
    db: AsyncSession = Depends(get_db),
):
    """Xem chi tiết playlist + danh sách tracks."""
    result = await db.execute(
        select(Playlist).filter_by(id=playlist_id)
    )
    playlist = result.scalar_one_or_none()

    if not playlist:
        raise HTTPException(status_code=404, detail="Playlist không tồn tại")

    tracks = [
        TrackInPlaylistResponse(
            video_id=t.video_id,
            title=t.display_name,
            custom_name=t.custom_name,
            channel_name=t.channel_name,
            thumbnail_url=t.thumbnail_url,
            stream_url=f"{STATIC_BASE}/{t.filename}",
        )
        for t in playlist.tracks
    ]

    return PlaylistDetailResponse(
        id=playlist.id,
        name=playlist.name,
        created_at=playlist.created_at.isoformat(),
        tracks=tracks,
    )


@router.post("/{playlist_id}/tracks/{video_id}")
async def add_track_to_playlist(
    playlist_id: int,
    video_id: str,
    db: AsyncSession = Depends(get_db),
):
    """Thêm track vào playlist."""
    # Tìm playlist
    pl_result = await db.execute(select(Playlist).filter_by(id=playlist_id))
    playlist = pl_result.scalar_one_or_none()
    if not playlist:
        raise HTTPException(status_code=404, detail="Playlist không tồn tại")

    # Tìm track
    track_result = await db.execute(select(AudioTrack).filter_by(video_id=video_id))
    track = track_result.scalar_one_or_none()
    if not track:
        raise HTTPException(status_code=404, detail=f"Audio không tồn tại: {video_id}")

    # Kiểm tra đã có trong playlist chưa
    if track in playlist.tracks:
        return {"message": "Track đã có trong playlist", "video_id": video_id}

    playlist.tracks.append(track)
    await db.commit()

    return {
        "message": f"Đã thêm '{track.display_name}' vào '{playlist.name}'",
        "video_id": video_id,
        "playlist_id": playlist_id,
    }


@router.delete("/{playlist_id}/tracks/{video_id}")
async def remove_track_from_playlist(
    playlist_id: int,
    video_id: str,
    db: AsyncSession = Depends(get_db),
):
    """Xóa track khỏi playlist (không xóa track khỏi thư viện)."""
    pl_result = await db.execute(select(Playlist).filter_by(id=playlist_id))
    playlist = pl_result.scalar_one_or_none()
    if not playlist:
        raise HTTPException(status_code=404, detail="Playlist không tồn tại")

    track_result = await db.execute(select(AudioTrack).filter_by(video_id=video_id))
    track = track_result.scalar_one_or_none()
    if not track:
        raise HTTPException(status_code=404, detail=f"Audio không tồn tại: {video_id}")

    if track in playlist.tracks:
        playlist.tracks.remove(track)
        await db.commit()
        return {"message": f"Đã xóa '{track.display_name}' khỏi '{playlist.name}'"}

    return {"message": "Track không có trong playlist"}


@router.delete("/{playlist_id}")
async def delete_playlist(
    playlist_id: int,
    db: AsyncSession = Depends(get_db),
):
    """Xóa playlist (không xóa tracks khỏi thư viện)."""
    result = await db.execute(select(Playlist).filter_by(id=playlist_id))
    playlist = result.scalar_one_or_none()

    if not playlist:
        raise HTTPException(status_code=404, detail="Playlist không tồn tại")

    await db.delete(playlist)
    await db.commit()

    return {"message": f"Đã xóa playlist '{playlist.name}'", "id": playlist_id}
