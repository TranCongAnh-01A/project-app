"""
Service: Trích xuất metadata & playlist từ YouTube (yt-dlp Python API).

v0.3 — Chỉ giữ lại các hàm cần thiết cho:
  - GET /metadata: Preview thông tin video trước khi nén
  - Playlist detection & extraction (hỗ trợ tương lai)

Pipeline tải + nén + upload đã chuyển hoàn toàn sang ingest.py (server-side).
"""
import logging
import re

import yt_dlp

logger = logging.getLogger(__name__)

# Spoofing headers — tránh bị YouTube/Cloudflare chặn bot
_SPOOF_HEADERS = {
    "User-Agent": (
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
        "AppleWebKit/537.36 (KHTML, like Gecko) "
        "Chrome/147.0.0.0 Safari/537.36"
    ),
    "Accept-Language": "en-US,en;q=0.9",
}


class AudioProcessingError(Exception):
    """Lỗi xảy ra trong quá trình trích xuất metadata hoặc playlist."""


# ─────────────────────────────────────────────────────────
# METADATA: Trích xuất thông tin video (không tải file)
# ─────────────────────────────────────────────────────────

def fetch_metadata(url: str) -> dict:
    """
    Trích xuất metadata từ YouTube URL mà KHÔNG tải file.
    Dùng cho API preview trước khi người dùng nhấn Nén.

    Returns:
        dict: video_id, title, channel_name, thumbnail_url, duration_seconds
    """
    opts = {
        "quiet": True,
        "no_warnings": True,
        "nocheckcertificate": True,
        "skip_download": True,
        "noplaylist": True,
        "http_headers": _SPOOF_HEADERS,
    }

    logger.info("Fetching metadata: %s", url)

    try:
        with yt_dlp.YoutubeDL(opts) as ydl:
            info = ydl.extract_info(url, download=False, process=False)

            if not info:
                raise AudioProcessingError("yt-dlp trả về info rỗng")

            video_id = info.get("id", "")
            title = info.get("title", "Unknown")
            channel = info.get("channel", "") or info.get("uploader", "Unknown")
            duration = info.get("duration", 0)

            thumbnail = _get_best_thumbnail(info)

            metadata = {
                "video_id": video_id,
                "title": title,
                "channel_name": channel,
                "thumbnail_url": thumbnail,
                "duration_seconds": duration or 0,
            }

            logger.info("Metadata OK: %s - %s", video_id, title[:50])
            return metadata

    except yt_dlp.utils.DownloadError as exc:
        raise AudioProcessingError(f"Không thể đọc metadata: {exc}")
    except AudioProcessingError:
        raise
    except Exception as exc:
        raise AudioProcessingError(f"Lỗi fetch metadata: {exc}")


def _get_best_thumbnail(info: dict) -> str:
    """
    Chọn thumbnail chất lượng cao nhất từ danh sách.
    YouTube cung cấp nhiều kích thước: default, medium, high, maxres.
    """
    thumbnails = info.get("thumbnails", [])
    if thumbnails:
        sorted_thumbs = sorted(
            thumbnails,
            key=lambda t: t.get("preference", t.get("width", 0) or 0),
            reverse=True,
        )
        return sorted_thumbs[0].get("url", "")

    # Fallback: dùng thumbnail mặc định của YouTube
    video_id = info.get("id", "")
    if video_id:
        return f"https://img.youtube.com/vi/{video_id}/hqdefault.jpg"

    return ""


# ─────────────────────────────────────────────────────────
# PLAYLIST: Phát hiện & trích xuất danh sách video từ URL
# ─────────────────────────────────────────────────────────

# Regex phát hiện YouTube Playlist URL
_YT_PLAYLIST_REGEX = re.compile(
    r"(?:youtube\.com/(?:playlist\?|watch\?.*?&?list=))"
    r"([a-zA-Z0-9_\-]+)"
)


def is_playlist_url(url: str) -> bool:
    """
    Kiểm tra URL có phải YouTube Playlist không.
    Trả True nếu URL chứa param 'list=' (playlist ID).
    """
    return bool(_YT_PLAYLIST_REGEX.search(url))


def extract_playlist_entries(url: str) -> list[dict]:
    """
    Trích xuất toàn bộ video entries từ Playlist YouTube.
    Không tải file, chỉ lấy metadata cơ bản (id, title, url).

    Tại sao dùng flat_playlist=True:
    - Chỉ lấy danh sách video, không resolve từng video (nhanh hơn)
    - Tiết kiệm thời gian: playlist 100 bài chỉ mất ~2-3s

    Returns:
        list[dict]: Mỗi item chứa {video_id, title, url}
    """
    opts = {
        "quiet": True,
        "no_warnings": True,
        "nocheckcertificate": True,
        "skip_download": True,
        "extract_flat": True,
        "flat_playlist": True,
        "http_headers": _SPOOF_HEADERS,
    }

    logger.info("Đang trích xuất playlist: %s", url)

    try:
        with yt_dlp.YoutubeDL(opts) as ydl:
            info = ydl.extract_info(url, download=False)

            if not info:
                raise AudioProcessingError("yt-dlp trả về info rỗng cho playlist")

            entries = info.get("entries", [])
            if not entries:
                raise AudioProcessingError("Playlist rỗng hoặc không tìm thấy video nào")

            results = []
            for entry in entries:
                if entry is None:
                    continue

                video_id = entry.get("id", "")
                if not video_id:
                    continue

                results.append({
                    "video_id": video_id,
                    "title": entry.get("title", video_id),
                    "url": entry.get("url", f"https://www.youtube.com/watch?v={video_id}"),
                })

            logger.info("Playlist có %d video", len(results))
            return results

    except yt_dlp.utils.DownloadError as exc:
        raise AudioProcessingError(f"Không thể đọc playlist: {exc}")
    except AudioProcessingError:
        raise
    except Exception as exc:
        raise AudioProcessingError(f"Lỗi trích xuất playlist: {exc}")
