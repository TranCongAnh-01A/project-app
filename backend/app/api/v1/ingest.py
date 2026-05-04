"""
API Endpoints: Tiếp nhận link & bóc tách nội dung.

NEW (v0.3 — Server-side Pipeline, Async):
  - GET  /metadata:        Xem trước thông tin video
  - POST /youtube-v2:      Pipeline hoàn chỉnh trên server
    1. yt-dlp tải audio gốc (chạy trong executor, không block event loop)
    2. FFmpeg nén + segment (chia nhỏ nếu video dài)
    3. Upload từng chunk lên Telegram Bot API
    4. Lưu metadata vào Supabase
    5. Dọn dẹp file tạm
"""
import asyncio
import glob
import logging
import math
import os
import re
import subprocess
import tempfile
import uuid
from pathlib import Path

import httpx
from fastapi import APIRouter, HTTPException, Query
from pydantic import BaseModel, HttpUrl
 
from app.core.config import get_settings
from app.services.audio_proc import (
    AudioProcessingError,
    fetch_metadata,
    is_playlist_url,
    extract_playlist_entries,
)
router = APIRouter(prefix="/ingest", tags=["Ingest"])
logger = logging.getLogger(__name__)
settings = get_settings()

# Regex kiểm tra URL YouTube hợp lệ (video đơn)
YOUTUBE_URL_PATTERN = re.compile(
    r"^(https?://)?(www\.)?"
    r"(youtube\.com/(watch\?|shorts/|live/|playlist\?)|youtu\.be/)"
)

# ════════════════════════════════════════════════════════════
# CONSTANTS cho Pipeline v2
# ════════════════════════════════════════════════════════════

# Giới hạn thời lượng mỗi segment (giây).
# Opus 64kbps mono: 1.5h ≈ ~35MB → chắc chắn < 50MB limit của Telegram Bot API.
_MAX_SEGMENT_DURATION = 5400  # 1.5 tiếng

# Thư mục temp tạm — dọn dẹp sau khi pipeline hoàn tất.
_TEMP_DIR = Path(tempfile.gettempdir()) / "pmka_ingest"

# User-Agent giả lập Chrome 147 (2026) — tránh bị YouTube/Cloudflare chặn bot.
_CHROME_UA = (
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
    "AppleWebKit/537.36 (KHTML, like Gecko) "
    "Chrome/147.0.0.0 Safari/537.36"
)

# Headers spoofing cho yt-dlp
_SPOOF_HEADERS = {
    "User-Agent": _CHROME_UA,
    "Accept-Language": "en-US,en;q=0.9",
    "Referer": "https://www.youtube.com/",
}


# ════════════════════════════════════════════════════════════
# SCHEMAS
# ════════════════════════════════════════════════════════════

class YouTubeIngestV2Request(BaseModel):
    """Request body cho endpoint nén audio v2 (Server-side Pipeline).

    Fields:
        youtube_url: URL YouTube video cần xử lý.
        user_id:     UUID của user trên Supabase (dùng cho RLS khi insert).
    """
    youtube_url: str
    user_id: str  # UUID dạng string


class IngestV2PartResult(BaseModel):
    """Kết quả xử lý của 1 phần (part) audio."""
    part_number: int
    title: str
    telegram_file_id: str
    duration_seconds: int
    size_bytes: int


class IngestV2Response(BaseModel):
    """Response tổng hợp của pipeline v2."""
    status: str
    video_id: str
    original_title: str
    channel: str
    total_parts: int
    parts: list[IngestV2PartResult]
    message: str


class MetadataResponse(BaseModel):
    """Response xem trước thông tin video."""
    video_id: str
    title: str
    channel_name: str
    thumbnail_url: str
    duration_seconds: int


# ════════════════════════════════════════════════════════════
# LEGACY ENDPOINTS (Giữ nguyên — backward compatible)
# ════════════════════════════════════════════════════════════

@router.get("/metadata", response_model=MetadataResponse)
async def get_video_metadata(url: str = Query(..., description="YouTube URL")):
    """
    Xem trước metadata video trước khi nén.
    Flutter gọi endpoint này khi người dùng dán link
    để hiện Thumbnail + Tên + Kênh trên UI.
    """
    if not YOUTUBE_URL_PATTERN.match(url):
        raise HTTPException(
            status_code=400,
            detail="URL không phải YouTube.",
        )

    try:
        metadata = fetch_metadata(url)
        return MetadataResponse(**metadata)
    except AudioProcessingError as exc:
        raise HTTPException(status_code=422, detail=str(exc))
    except Exception as exc:
        logger.exception("Lỗi fetch metadata: %s", exc)
        raise HTTPException(status_code=500, detail="Lỗi server khi đọc metadata")


# ════════════════════════════════════════════════════════════
# NEW ENDPOINT: POST /youtube-v2  (Server-side Pipeline)
# ════════════════════════════════════════════════════════════

@router.post("/youtube-v2", response_model=IngestV2Response)
async def ingest_youtube_v2(request: YouTubeIngestV2Request):
    """
    Pipeline nén audio server-side hoàn chỉnh (v0.3).

    Luồng xử lý tuần tự:
      1. Validate URL + UUID
      2. yt-dlp tải audio gốc (bestaudio) — chạy trong executor
      3. FFmpeg nén Opus 64kbps + segment nếu video dài
      4. Upload từng chunk lên Telegram Bot API
      5. Insert metadata vào Supabase (bảng audio_metadata)
      6. Dọn dẹp file tạm

    Tại sao chạy yt-dlp trong executor:
      yt-dlp dùng synchronous I/O (requests + subprocess).
      Nếu gọi trực tiếp trong async handler → block event loop →
      các request khác bị treo. run_in_executor đẩy sang thread pool.

    Tại sao dùng FFmpeg segment thay vì cắt thủ công:
      FFmpeg -f segment tự tìm keyframe gần nhất để cắt →
      không bị lỗi audio glitch/pop ở mối nối giữa 2 phần.
    """
    youtube_url = request.youtube_url.strip()
    user_id = request.user_id.strip()

    # ── Validate ──
    if not YOUTUBE_URL_PATTERN.match(youtube_url):
        raise HTTPException(
            status_code=400,
            detail="URL không phải YouTube. Chỉ hỗ trợ youtube.com và youtu.be.",
        )

    try:
        uuid.UUID(user_id)
    except ValueError:
        raise HTTPException(
            status_code=400,
            detail=f"user_id không hợp lệ (phải là UUID): {user_id}",
        )

    # Tạo thư mục temp riêng cho mỗi request (tránh xung đột file)
    request_id = uuid.uuid4().hex[:12]
    work_dir = _TEMP_DIR / request_id
    work_dir.mkdir(parents=True, exist_ok=True)

    logger.info("[V2] Bắt đầu pipeline: %s (user=%s, dir=%s)", youtube_url, user_id, work_dir)

    try:
        # ── Bước 1: yt-dlp tải audio + trích xuất metadata ──
        raw_file, meta = await _step_download(youtube_url, work_dir)

        video_id = meta["video_id"]
        original_title = meta["title"]
        channel = meta["channel"]
        duration = meta["duration"]
        thumbnail_url = meta["thumbnail_url"]

        logger.info(
            "[V2] Bước 1 OK: %s (%s, %d giây, %.2f MB)",
            video_id, original_title[:50],
            duration, raw_file.stat().st_size / 1_048_576,
        )

        # ── Bước 2: FFmpeg nén + segment ──
        segment_files = await _step_compress_and_segment(
            raw_file, work_dir, duration,
        )

        total_parts = len(segment_files)
        logger.info("[V2] Bước 2 OK: %d phần tạo ra", total_parts)

        # ── Bước 3 + 4: Upload từng chunk lên Telegram → lưu Supabase ──
        parts_result: list[IngestV2PartResult] = []

        for idx, segment_path in enumerate(segment_files):
            part_num = idx + 1

            # Gắn nhãn phần (UX): "Tên bài (Phần 1/3)" nếu > 1 phần
            if total_parts > 1:
                part_title = f"{original_title} (Phần {part_num}/{total_parts})"
            else:
                part_title = original_title

            # Tính thời lượng phần này bằng ffprobe (chính xác hơn ước lượng)
            part_duration = await _get_audio_duration(segment_path)

            # Upload lên Telegram
            file_id = await _step_upload_telegram(
                segment_path, part_title, channel,
            )

            part_size = segment_path.stat().st_size

            logger.info(
                "[V2] Bước 3+4: Phần %d/%d upload OK (file_id=%s, %d giây, %.2f MB)",
                part_num, total_parts, file_id[:20],
                part_duration, part_size / 1_048_576,
            )

            # Lưu vào Supabase
            await _step_save_supabase(
                video_id=f"{video_id}_p{part_num}" if total_parts > 1 else video_id,
                title=part_title,
                channel_name=channel,
                thumbnail_url=thumbnail_url,
                telegram_file_id=file_id,
                duration_seconds=part_duration,
                size_bytes=part_size,
                original_size_bytes=raw_file.stat().st_size,
                user_id=user_id,
            )

            parts_result.append(IngestV2PartResult(
                part_number=part_num,
                title=part_title,
                telegram_file_id=file_id,
                duration_seconds=part_duration,
                size_bytes=part_size,
            ))

        logger.info("[V2] ✅ HOÀN TẤT: %s (%d phần)", video_id, total_parts)

        return IngestV2Response(
            status="success",
            video_id=video_id,
            original_title=original_title,
            channel=channel,
            total_parts=total_parts,
            parts=parts_result,
            message=f"Đã xử lý thành công {total_parts} phần.",
        )

    except HTTPException:
        # Đã có status code → ném lại nguyên xi
        raise

    except Exception as exc:
        logger.exception("[V2] ❌ Pipeline thất bại: %s", exc)
        raise HTTPException(
            status_code=500,
            detail=f"Pipeline xử lý thất bại: {exc}",
        )

    finally:
        # ── Bước 5: Dọn dẹp — LUÔN chạy dù thành công hay thất bại ──
        await _step_cleanup(work_dir)


# ════════════════════════════════════════════════════════════
# PIPELINE STEPS (Private)
# ════════════════════════════════════════════════════════════

async def _step_download(youtube_url: str, work_dir: Path) -> tuple[Path, dict]:
    """
    Bước 1: Tải audio gốc từ YouTube bằng yt-dlp.

    Chạy trong executor (thread pool) vì yt-dlp là sync I/O.
    Dùng format 'bestaudio/best' để lấy luồng audio chất lượng cao nhất.

    Returns:
        (đường dẫn file đã tải, dict metadata)

    Raises:
        HTTPException 400: URL YouTube không hợp lệ hoặc yt-dlp không trích xuất được
        HTTPException 500: Lỗi hệ thống không xác định
    """
    import yt_dlp

    output_template = str(work_dir / "raw_audio.%(ext)s")

    opts = {
        "format": "bestaudio/best",
        "outtmpl": output_template,
        "http_headers": _SPOOF_HEADERS,
        "quiet": True,
        "no_warnings": True,
        "nocheckcertificate": True,
        "noplaylist": True,
        "retries": 3,
        "socket_timeout": 60,
        "ignoreerrors": False,
        # Extractor args giúp bypass một số kiểu chặn của YouTube
        "extractor_args": {
            "youtube": {"player_client": ["web", "web_embedded"]},
        },
    }

    def _sync_download() -> tuple[Path, dict]:
        """Thực thi yt-dlp đồng bộ — sẽ được gọi trong executor."""
        try:
            with yt_dlp.YoutubeDL(opts) as ydl:
                info = ydl.extract_info(youtube_url, download=True)

                if not info:
                    raise AudioProcessingError("yt-dlp trả về info rỗng")

                # Tìm file thực tế mà yt-dlp đã tải
                actual_file = None
                requested = info.get("requested_downloads")
                if requested and len(requested) > 0:
                    actual_file = requested[0].get("filepath")

                if not actual_file:
                    # Fallback: quét thư mục tìm file có prefix "raw_audio"
                    candidates = list(work_dir.glob("raw_audio.*"))
                    if candidates:
                        actual_file = str(candidates[0])

                if not actual_file or not Path(actual_file).exists():
                    raise AudioProcessingError(
                        "Không tìm thấy file audio sau khi yt-dlp tải xong"
                    )

                # Trích xuất metadata
                video_id = info.get("id", "")
                title = info.get("title", "Unknown")
                channel = info.get("channel", "") or info.get("uploader", "Unknown")
                duration = info.get("duration", 0) or 0

                # Chọn thumbnail chất lượng cao nhất
                thumbnails = info.get("thumbnails", [])
                thumbnail_url = ""
                if thumbnails:
                    sorted_thumbs = sorted(
                        thumbnails,
                        key=lambda t: t.get("preference", t.get("width", 0) or 0),
                        reverse=True,
                    )
                    thumbnail_url = sorted_thumbs[0].get("url", "")

                if not thumbnail_url and video_id:
                    thumbnail_url = f"https://img.youtube.com/vi/{video_id}/hqdefault.jpg"

                return Path(actual_file), {
                    "video_id": video_id,
                    "title": title,
                    "channel": channel,
                    "duration": duration,
                    "thumbnail_url": thumbnail_url,
                }

        except yt_dlp.utils.DownloadError as exc:
            raise AudioProcessingError(f"yt-dlp tải thất bại: {exc}")

    loop = asyncio.get_running_loop()

    try:
        result = await loop.run_in_executor(None, _sync_download)
        return result
    except AudioProcessingError as exc:
        raise HTTPException(status_code=400, detail=str(exc))
    except Exception as exc:
        raise HTTPException(
            status_code=500,
            detail=f"Lỗi tải audio từ YouTube: {exc}",
        )


async def _step_compress_and_segment(
    raw_file: Path,
    work_dir: Path,
    duration: int,
) -> list[Path]:
    """
    Bước 2: Nén audio sang Opus 64kbps + chia nhỏ nếu video dài.

    Cơ chế phân đoạn (Segmenting):
      Nếu duration > MAX_SEGMENT_DURATION (5400s = 1.5h):
        → FFmpeg dùng -f segment để cắt thành nhiều file .opus
        → Mỗi segment ≤ 1.5h → Opus 64kbps mono ≈ 35MB → an toàn < 50MB Telegram limit

      Nếu duration ≤ MAX_SEGMENT_DURATION:
        → Nén thẳng 1 file (không segment)

    Lệnh FFmpeg segment:
      ffmpeg -i input -c:a libopus -b:a 64k -ac 1 -ar 48000 -vbr on
             -f segment -segment_time 5400 output_%03d.opus

    Tại sao dùng -f segment thay vì -ss/-to thủ công:
      - FFmpeg segment tự tìm keyframe gần nhất → không bị audio pop/click
      - 1 lệnh duy nhất thay vì N lệnh riêng lẻ → nhanh hơn
      - Tự đánh số file liên tục (000, 001, 002...) → dễ sắp xếp

    Returns:
        Danh sách đường dẫn các file segment đã nén (sắp xếp theo tên).

    Raises:
        HTTPException 500: FFmpeg thất bại
    """
    total_parts = math.ceil(duration / _MAX_SEGMENT_DURATION) if duration > 0 else 1
    use_segment = total_parts > 1

    if use_segment:
        # ── Segment mode: Chia nhỏ + nén cùng lúc ──
        output_pattern = str(work_dir / "part_%03d.opus")
        cmd = [
            "ffmpeg",
            "-i", str(raw_file),
            "-vn",                  # Bỏ video track
            "-c:a", "libopus",      # Codec Opus
            "-b:a", "64k",          # Bitrate 64kbps
            "-ac", "1",             # Mono
            "-ar", "48000",         # Sample rate 48kHz (chuẩn Opus RFC 6716)
            "-vbr", "on",           # Variable bitrate cho chất lượng tốt hơn
            "-f", "segment",        # Bật chế độ segment
            "-segment_time", str(_MAX_SEGMENT_DURATION),
            "-y",                   # Overwrite nếu file đã tồn tại
            output_pattern,
        ]
        logger.info(
            "[V2] FFmpeg segment: %d phần x %d giây mỗi phần",
            total_parts, _MAX_SEGMENT_DURATION,
        )
    else:
        # ── Single file mode: Nén thẳng 1 file ──
        output_path = str(work_dir / "part_000.opus")
        cmd = [
            "ffmpeg",
            "-i", str(raw_file),
            "-vn",
            "-c:a", "libopus",
            "-b:a", "64k",
            "-ac", "1",
            "-ar", "48000",
            "-vbr", "on",
            "-y",
            output_path,
        ]
        logger.info("[V2] FFmpeg nén 1 file (duration=%d giây)", duration)

    # Chạy FFmpeg trong executor (subprocess blocking I/O)
    loop = asyncio.get_running_loop()

    def _run_ffmpeg() -> None:
        try:
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                # Timeout dài cho video rất dài (3h → ~600s encode)
                timeout=1200,
            )
            if result.returncode != 0:
                stderr_tail = result.stderr[-800:] if result.stderr else "Không có stderr"
                raise AudioProcessingError(
                    f"FFmpeg exit code {result.returncode}: {stderr_tail}"
                )
        except subprocess.TimeoutExpired:
            raise AudioProcessingError(
                "FFmpeg timeout (> 20 phút) — video quá dài hoặc server quá tải"
            )

    try:
        await loop.run_in_executor(None, _run_ffmpeg)
    except AudioProcessingError as exc:
        raise HTTPException(status_code=500, detail=str(exc))

    # Thu thập các file segment đã tạo, sắp xếp theo tên (part_000, part_001, ...)
    segment_files = sorted(work_dir.glob("part_*.opus"))

    if not segment_files:
        raise HTTPException(
            status_code=500,
            detail="FFmpeg không tạo ra file output nào.",
        )

    # Validate: file nào rỗng → lỗi
    for seg in segment_files:
        if seg.stat().st_size == 0:
            raise HTTPException(
                status_code=500,
                detail=f"FFmpeg tạo file rỗng: {seg.name}",
            )

    logger.info("[V2] FFmpeg tạo %d file segment thành công", len(segment_files))
    return segment_files


async def _step_upload_telegram(
    file_path: Path,
    title: str,
    performer: str,
) -> str:
    """
    Bước 3: Upload file .opus lên Telegram Bot API.

    Endpoint: POST https://api.telegram.org/bot{token}/sendAudio
    Telegram trả về response chứa file_id — mã định danh vĩnh viễn
    để stream lại file mà không cần lưu trữ local.

    Returns:
        telegram_file_id (string)

    Raises:
        HTTPException 500: Telegram API trả lỗi hoặc timeout
    """
    bot_token = settings.TELEGRAM_BOT_TOKEN
    chat_id = settings.TELEGRAM_CHAT_ID

    if not bot_token or not chat_id:
        raise HTTPException(
            status_code=500,
            detail="TELEGRAM_BOT_TOKEN hoặc TELEGRAM_CHAT_ID chưa được cấu hình.",
        )

    url = f"https://api.telegram.org/bot{bot_token}/sendAudio"

    # Giới hạn title/performer cho Telegram metadata tag
    safe_title = title[:256] if title else "Audio"
    safe_performer = performer[:128] if performer else "Unknown"

    async with httpx.AsyncClient(timeout=120.0) as client:
        with open(file_path, "rb") as audio_file:
            response = await client.post(
                url,
                data={
                    "chat_id": chat_id,
                    "title": safe_title,
                    "performer": safe_performer,
                },
                files={
                    "audio": (file_path.name, audio_file, "audio/ogg"),
                },
            )

    if response.status_code != 200:
        detail = response.text[:500]
        logger.error("[V2] Telegram API lỗi %d: %s", response.status_code, detail)
        raise HTTPException(
            status_code=500,
            detail=f"Telegram API trả HTTP {response.status_code}: {detail}",
        )

    result = response.json()
    if not result.get("ok"):
        description = result.get("description", "Không rõ lỗi")
        raise HTTPException(
            status_code=500,
            detail=f"Telegram API từ chối: {description}",
        )

    # Trích file_id từ response
    # Telegram trả về audio object trong result.audio
    audio_obj = result.get("result", {}).get("audio", {})
    file_id = audio_obj.get("file_id", "")

    if not file_id:
        raise HTTPException(
            status_code=500,
            detail="Telegram response thiếu file_id — không thể stream lại file.",
        )

    return file_id


async def _step_save_supabase(
    *,
    video_id: str,
    title: str,
    channel_name: str,
    thumbnail_url: str,
    telegram_file_id: str,
    duration_seconds: int,
    size_bytes: int,
    original_size_bytes: int,
    user_id: str,
) -> None:
    """
    Bước 4: Insert metadata vào Supabase (bảng audio_metadata).

    Dùng Supabase REST API (PostgREST) thay vì supabase-py client
    để tránh thêm dependency nặng. PostgREST là HTTP JSON đơn giản.

    Tại sao dùng REST API trực tiếp:
      - supabase-py có overhead khởi tạo client, quản lý session
      - Ở đây chỉ cần 1 INSERT → HTTP POST đơn giản hơn
      - Dùng service_role key (bypass RLS) vì server đang action thay user

    Raises:
        HTTPException 500: Supabase trả lỗi INSERT
    """
    supabase_url = settings.SUPABASE_URL
    supabase_key = settings.SUPABASE_SERVICE_ROLE_KEY

    if not supabase_url or not supabase_key:
        raise HTTPException(
            status_code=500,
            detail="SUPABASE_URL hoặc SUPABASE_SERVICE_ROLE_KEY chưa được cấu hình.",
        )

    # Tính compression ratio
    compression_ratio = 0.0
    if original_size_bytes > 0:
        compression_ratio = round(
            (original_size_bytes - size_bytes) / original_size_bytes * 100, 1
        )

    endpoint = f"{supabase_url}/rest/v1/audio_metadata"
    headers = {
        "apikey": supabase_key,
        "Authorization": f"Bearer {supabase_key}",
        "Content-Type": "application/json",
        "Prefer": "return=minimal",  # Không cần response body
    }

    payload = {
        "video_id": video_id,
        "title": title,
        "channel_name": channel_name,
        "thumbnail_url": thumbnail_url,
        "telegram_file_id": telegram_file_id,
        "duration_seconds": duration_seconds,
        "size_bytes": size_bytes,
        "original_size_bytes": original_size_bytes,
        "compression_ratio": compression_ratio,
        "user_id": user_id,
    }

    async with httpx.AsyncClient(timeout=30.0) as client:
        response = await client.post(endpoint, json=payload, headers=headers)

    if response.status_code not in (200, 201, 204):
        detail = response.text[:500]
        logger.error(
            "[V2] Supabase INSERT lỗi %d: %s", response.status_code, detail,
        )
        raise HTTPException(
            status_code=500,
            detail=f"Lỗi lưu metadata vào Supabase: {detail}",
        )

    logger.info("[V2] Supabase INSERT OK: %s", video_id)


async def _get_audio_duration(file_path: Path) -> int:
    """
    Lấy thời lượng chính xác (giây) của file audio bằng ffprobe.

    Tại sao không ước lượng bằng file_size / bitrate:
      Opus dùng VBR (Variable Bitrate) → kích thước file
      không tỉ lệ tuyến tính với thời lượng.
      ffprobe đọc header container → chính xác 100%.
    """
    cmd = [
        "ffprobe",
        "-v", "error",
        "-show_entries", "format=duration",
        "-of", "default=noprint_wrappers=1:nokey=1",
        str(file_path),
    ]

    loop = asyncio.get_running_loop()

    def _run():
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=30)
        if result.returncode != 0:
            return 0
        try:
            return int(float(result.stdout.strip()))
        except (ValueError, TypeError):
            return 0

    try:
        return await loop.run_in_executor(None, _run)
    except Exception:
        return 0


async def _step_cleanup(work_dir: Path) -> None:
    """
    Bước 5: Dọn dẹp file tạm.

    Xóa toàn bộ file trong thư mục work_dir và chính thư mục đó.
    Chạy trong finally block → luôn thực thi dù pipeline thành công hay thất bại.
    Mục đích: tránh file tạm tích tụ làm đầy ổ cứng server.
    """
    import shutil

    try:
        if work_dir.exists():
            shutil.rmtree(work_dir, ignore_errors=True)
            logger.info("[V2] Đã dọn dẹp: %s", work_dir)
    except Exception as exc:
        # Lỗi dọn dẹp không nên crash pipeline
        logger.warning("[V2] Không thể dọn dẹp %s: %s", work_dir, exc)
