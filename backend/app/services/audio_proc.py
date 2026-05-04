"""
Service: Xử lý nén Audio (yt-dlp Python API + FFmpeg).

Pipeline: URL YouTube → yt-dlp (tải audio gốc) → FFmpeg (nén Opus) → file .opus
Metadata: URL → yt-dlp (extract_info) → title, channel, thumbnail

Tại sao chọn Opus 64kbps mono 48kHz:
- Opus vượt trội so với MP3/AAC ở bitrate thấp
- 64kbps mono đủ nghe rõ giọng nói podcast/sách nói
- 48kHz là sampling rate chuẩn của Opus (RFC 6716)
"""
import logging
import os
import re
import subprocess
from pathlib import Path

import yt_dlp

logger = logging.getLogger(__name__)

# Đọc đường dẫn storage từ biến môi trường
STORAGE_DIR = Path(os.getenv("STORAGE_DIR", "/app/storage"))

# Regex trích xuất YouTube video ID từ URL
_YT_ID_REGEX = re.compile(
    r"(?:youtube\.com/(?:watch\?.*?v=|shorts/|live/|embed/)"
    r"|youtu\.be/)"
    r"([\w\-]{11})"
)

# Spoofing headers dùng chung cho mọi request yt-dlp
_SPOOF_HEADERS = {
    "User-Agent": (
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
        "AppleWebKit/537.36 (KHTML, like Gecko) "
        "Chrome/120.0.0.0 Safari/537.36"
    ),
    "Accept-Language": "en-US,en;q=0.9",
}


class AudioProcessingError(Exception):
    """Lỗi xảy ra trong quá trình tải hoặc nén audio."""


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

    print(f"[AUDIO_PROC] Fetching metadata: {url}")

    try:
        with yt_dlp.YoutubeDL(opts) as ydl:
            info = ydl.extract_info(url, download=False, process=False)

            if not info:
                raise AudioProcessingError("yt-dlp trả về info rỗng")

            video_id = info.get("id", "")
            title = info.get("title", "Unknown")
            channel = info.get("channel", "") or info.get("uploader", "Unknown")
            duration = info.get("duration", 0)

            # Lấy thumbnail chất lượng cao nhất
            thumbnail = _get_best_thumbnail(info)

            metadata = {
                "video_id": video_id,
                "title": title,
                "channel_name": channel,
                "thumbnail_url": thumbnail,
                "duration_seconds": duration or 0,
            }

            print(f"[AUDIO_PROC] Metadata OK: {video_id} - {title[:50]}...")
            return metadata

    except yt_dlp.utils.DownloadError as exc:
        raise AudioProcessingError(f"Không thể đọc metadata: {exc}")
    except Exception as exc:
        raise AudioProcessingError(f"Lỗi fetch metadata: {exc}")


def _get_best_thumbnail(info: dict) -> str:
    """
    Chọn thumbnail chất lượng cao nhất từ danh sách.
    YouTube cung cấp nhiều kích thước: default, medium, high, maxres.
    """
    thumbnails = info.get("thumbnails", [])
    if thumbnails:
        # Sắp xếp theo preference (hoặc width) giảm dần
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
# VIDEO ID: Trích xuất từ URL
# ─────────────────────────────────────────────────────────

def _extract_video_id(url: str) -> str:
    """Trích xuất YouTube video ID từ URL bằng regex."""
    match = _YT_ID_REGEX.search(url)
    if match:
        video_id = match.group(1)
        print(f"[AUDIO_PROC] Video ID (regex): {video_id}")
        return video_id

    # Fallback yt-dlp
    try:
        with yt_dlp.YoutubeDL({"quiet": True, "no_warnings": True}) as ydl:
            info = ydl.extract_info(url, download=False, process=False)
            video_id = info.get("id")
            if video_id:
                return video_id
    except Exception as exc:
        logger.warning("yt-dlp fallback thất bại: %s", exc)

    raise AudioProcessingError(f"Không trích xuất được video ID từ URL: {url}")


# ─────────────────────────────────────────────────────────
# DOWNLOAD: Tải audio gốc từ YouTube
# ─────────────────────────────────────────────────────────

def _download_raw_audio(url: str, output_path: Path) -> tuple[Path, dict]:
    """
    Tải audio + trích xuất metadata cùng lúc.
    Trả về (đường dẫn file, metadata dict).

    Tại sao gộp download + metadata:
    - Tiết kiệm 1 request network (extract_info đã có metadata)
    - Tránh bị rate limit khi gọi YouTube API 2 lần liên tiếp
    """
    raw_template = str(output_path) + ".%(ext)s"

    opts = {
        "format": "bestaudio/best",
        "outtmpl": raw_template,
        "http_headers": _SPOOF_HEADERS,
        "quiet": True,
        "no_warnings": True,
        "nocheckcertificate": True,
        "ignoreerrors": False,
        "noplaylist": True,
        "retries": 3,
        "socket_timeout": 30,
    }

    print(f"[AUDIO_PROC] yt-dlp bắt đầu tải: {url}")
    logger.info("Đang tải audio từ: %s", url)

    try:
        with yt_dlp.YoutubeDL(opts) as ydl:
            info = ydl.extract_info(url, download=True)

            # Trích xuất metadata từ info dict
            metadata = {
                "title": info.get("title", "Unknown"),
                "channel_name": info.get("channel", "") or info.get("uploader", "Unknown"),
                "thumbnail_url": _get_best_thumbnail(info),
                "duration_seconds": info.get("duration", 0) or 0,
            }

            actual_file = None
            requested = info.get("requested_downloads")
            if requested and len(requested) > 0:
                actual_file = requested[0].get("filepath")

            downloaded = Path(actual_file) if actual_file else _find_downloaded_file(output_path)

    except yt_dlp.utils.DownloadError as exc:
        error_msg = str(exc)
        print(f"[AUDIO_PROC] yt-dlp THẤT BẠI: {error_msg}")

        if "format is not available" in error_msg.lower():
            print("[AUDIO_PROC] Thử fallback format='best'...")
            return _download_raw_audio_fallback(url, output_path)

        raise AudioProcessingError(f"yt-dlp tải thất bại: {exc}")

    if downloaded is None or not downloaded.exists():
        raise AudioProcessingError(f"Không tìm thấy file audio sau khi tải: {output_path}")

    size_mb = downloaded.stat().st_size / 1_048_576
    print(f"[AUDIO_PROC] Đã tải: {downloaded.name} ({size_mb:.2f} MB)")
    return downloaded, metadata


def _download_raw_audio_fallback(url: str, output_path: Path) -> tuple[Path, dict]:
    """Fallback: format='best' + player_client web_embedded/mweb."""
    raw_template = str(output_path) + ".%(ext)s"

    opts = {
        "format": "best",
        "outtmpl": raw_template,
        "http_headers": _SPOOF_HEADERS,
        "quiet": True,
        "no_warnings": True,
        "nocheckcertificate": True,
        "noplaylist": True,
        "retries": 3,
        "socket_timeout": 30,
        "extractor_args": {
            "youtube": {"player_client": ["web_embedded", "mweb"]},
        },
    }

    try:
        with yt_dlp.YoutubeDL(opts) as ydl:
            info = ydl.extract_info(url, download=True)
            metadata = {
                "title": info.get("title", "Unknown"),
                "channel_name": info.get("channel", "") or info.get("uploader", "Unknown"),
                "thumbnail_url": _get_best_thumbnail(info),
                "duration_seconds": info.get("duration", 0) or 0,
            }
            actual_file = None
            requested = info.get("requested_downloads")
            if requested and len(requested) > 0:
                actual_file = requested[0].get("filepath")
            downloaded = Path(actual_file) if actual_file else _find_downloaded_file(output_path)
    except Exception as exc:
        raise AudioProcessingError(f"Fallback cũng thất bại: {exc}")

    if downloaded is None or not downloaded.exists():
        raise AudioProcessingError("Không tìm thấy file sau fallback")

    return downloaded, metadata


def _find_downloaded_file(base_path: Path) -> Path | None:
    """Tìm file yt-dlp đã tải (tự thêm extension)."""
    parent = base_path.parent
    stem = base_path.stem

    for f in parent.iterdir():
        if f.is_file() and f.stem == stem:
            return f
    for f in parent.iterdir():
        if f.is_file() and f.stem.startswith(stem):
            return f
    return None


# ─────────────────────────────────────────────────────────
# COMPRESS: Nén audio bằng FFmpeg
# ─────────────────────────────────────────────────────────

def _compress_to_opus(input_path: Path, output_path: Path) -> None:
    """Nén sang Opus: libopus 64kbps, Mono, 48kHz, VBR on."""
    cmd = [
        "ffmpeg",
        "-i", str(input_path),
        "-vn",
        "-c:a", "libopus",
        "-b:a", "64k",
        "-ac", "1",
        "-ar", "48000",
        "-vbr", "on",
        "-y",
        str(output_path),
    ]

    print(f"[AUDIO_PROC] FFmpeg nén: {input_path.name} → {output_path.name}")

    try:
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=300)
        if result.returncode != 0:
            raise AudioProcessingError(f"FFmpeg thất bại: {result.stderr[-500:]}")
    except subprocess.TimeoutExpired:
        output_path.unlink(missing_ok=True)
        raise AudioProcessingError("Timeout nén audio (>5 phút)")

    if not output_path.exists() or output_path.stat().st_size == 0:
        raise AudioProcessingError("FFmpeg tạo file rỗng")

    size_mb = output_path.stat().st_size / 1_048_576
    print(f"[AUDIO_PROC] Nén xong: {output_path.name} ({size_mb:.2f} MB)")


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
        "extract_flat": True,     # Chỉ lấy list, không resolve deep
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


# ─────────────────────────────────────────────────────────
# PIPELINE CHÍNH
# ─────────────────────────────────────────────────────────

def download_and_compress(url: str, custom_name: str | None = None) -> dict:
    """
    Pipeline: URL YouTube → file .opus + metadata.

    Args:
        url: YouTube URL
        custom_name: Tên tùy chỉnh từ người dùng (nullable)

    Returns:
        dict: video_id, output_path, metadata (title, channel, thumbnail),
              sizes, compression_ratio
    """
    os.makedirs(str(STORAGE_DIR), exist_ok=True)
    print(f"[AUDIO_PROC] STORAGE_DIR = {STORAGE_DIR}")

    video_id = _extract_video_id(url)
    output_path = STORAGE_DIR / f"{video_id}.opus"

    # Skip nếu file đã tồn tại
    if output_path.exists():
        print(f"[AUDIO_PROC] File đã tồn tại: {output_path}")
        # Vẫn cần metadata cho DB record
        try:
            metadata = fetch_metadata(url)
        except Exception:
            metadata = {"title": video_id, "channel_name": "Unknown", "thumbnail_url": "", "duration_seconds": 0}

        return {
            "video_id": video_id,
            "output_path": str(output_path),
            "original_size": 0,
            "compressed_size": output_path.stat().st_size,
            "compression_ratio": 0,
            "skipped": True,
            "title": metadata.get("title", video_id),
            "channel_name": metadata.get("channel_name", "Unknown"),
            "thumbnail_url": metadata.get("thumbnail_url", ""),
            "custom_name": custom_name,
        }

    raw_audio_path = None
    try:
        # Tải audio + trích xuất metadata cùng lúc
        raw_audio_path, metadata = _download_raw_audio(url, STORAGE_DIR / video_id)
        original_size = raw_audio_path.stat().st_size

        # Nén sang Opus
        _compress_to_opus(raw_audio_path, output_path)
        compressed_size = output_path.stat().st_size

        ratio = ((original_size - compressed_size) / original_size * 100) if original_size > 0 else 0
        print(f"[AUDIO_PROC] ✅ HOÀN TẤT: {video_id}.opus (giảm {ratio:.1f}%)")

        return {
            "video_id": video_id,
            "output_path": str(output_path),
            "original_size": original_size,
            "compressed_size": compressed_size,
            "compression_ratio": round(ratio, 1),
            "skipped": False,
            "title": metadata.get("title", video_id),
            "channel_name": metadata.get("channel_name", "Unknown"),
            "thumbnail_url": metadata.get("thumbnail_url", ""),
            "custom_name": custom_name,
        }
    finally:
        if raw_audio_path and raw_audio_path.exists():
            raw_audio_path.unlink(missing_ok=True)
