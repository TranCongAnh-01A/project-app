# PMKA — Project Context (Bản Đồ Trí Nhớ)

> Cập nhật: 2026-05-04 | Phiên bản Backend: v0.3 | Mobile: v0.1.0+1

---

## 1. Tổng Quan Dự Án

**PMKA (Personal Media & Knowledge Archiver)** — Hệ thống lưu trữ cá nhân: tải audio từ YouTube → nén → lưu trữ miễn phí trên Telegram → stream qua app Flutter.

### Kiến Trúc Tổng Thể

```
┌──────────────┐     ┌──────────────────┐     ┌────────────────┐
│  Mobile App  │────▶│  FastAPI Backend  │────▶│   Telegram     │
│  (Flutter)   │     │  (Python 3.12)   │     │   Bot API      │
│              │◀────│  yt-dlp + FFmpeg  │     │  (File Storage)│
└──────┬───────┘     └──────────────────┘     └────────────────┘
       │                                             ▲
       │             ┌──────────────────┐            │
       └────────────▶│   Supabase       │            │
                     │   (PostgreSQL)   │◀───────────┘
                     │   Auth + DB      │    (Backend lưu file_id)
                     │   Realtime Chat  │
                     └──────────────────┘
       │
┌──────┴───────┐
│  Admin Web   │
│  (React/Vite)│
└──────────────┘
```

---

## 2. Tech Stack

| Tầng | Công nghệ | Vai trò |
|------|-----------|---------|
| **Mobile** | Flutter 3.19+ / Dart 3.3+ | App chính cho user |
| **State Mgmt** | flutter_bloc (Cubit) | Quản lý state theo pattern BLoC |
| **Audio Player** | just_audio | Phát nhạc streaming |
| **Backend** | FastAPI 0.115 / Python 3.12 | API + Pipeline xử lý audio |
| **Audio Tools** | yt-dlp + FFmpeg (libopus) | Tải + Nén audio server-side |
| **Database** | Supabase (PostgreSQL) | Auth, RLS, Realtime, CRUD |
| **File Storage** | Telegram Bot API | Lưu trữ file audio miễn phí (vĩnh viễn) |
| **Admin** | React + Vite | Dashboard quản trị |
| **Deploy** | Docker Compose | PostgreSQL + Redis + Backend + Celery |
| **HTTP Client** | dio (mobile), httpx (backend) | Network layer |

---

## 3. Cấu Trúc Thư Mục

```
project-app/
├── backend/                    # FastAPI Backend
│   ├── Dockerfile
│   ├── requirements.txt
│   ├── app/
│   │   ├── main.py             # Entry point FastAPI
│   │   ├── db.py               # SQLAlchemy async engine (LEGACY — không còn dùng)
│   │   ├── core/
│   │   │   ├── config.py       # Pydantic Settings (env vars)
│   │   │   └── security.py     # JWT + bcrypt (LEGACY — Supabase Auth thay thế)
│   │   ├── api/v1/
│   │   │   └── ingest.py       # ⭐ API chính: /metadata + /youtube-v2
│   │   ├── models/             # SQLAlchemy models (LEGACY)
│   │   │   ├── audio_track.py
│   │   │   ├── favorite.py
│   │   │   └── playlist.py
│   │   ├── schemas/            # Pydantic schemas (trống)
│   │   └── services/
│   │       ├── audio_proc.py   # yt-dlp + FFmpeg wrapper
│   │       ├── admin_service.py  # TODO stub
│   │       ├── file_manager.py   # TODO stub
│   │       └── scraper.py        # TODO stub
│   └── storage/                # Mount volume Docker
│
├── mobile/                     # Flutter Mobile App
│   ├── pubspec.yaml
│   ├── .env.example
│   └── lib/
│       ├── main.dart           # Entry point + App theme + BlocProvider
│       ├── core/config/
│       │   └── env_config.dart # Quản lý env vars
│       ├── data/
│       │   ├── models/
│       │   │   ├── audio_metadata.dart
│       │   │   └── chat_message.dart
│       │   └── repositories/
│       │       ├── audio_repository.dart  # ⭐ CRUD Supabase
│       │       └── chat_repository.dart
│       ├── logic/              # Cubit (State Management)
│       │   ├── auth_cubit/
│       │   ├── audio_list_cubit/
│       │   ├── player_cubit/
│       │   ├── ingest_cubit/
│       │   └── chat_cubit/
│       ├── services/
│       │   ├── supabase_service.dart     # Singleton Supabase client
│       │   ├── youtube_service.dart      # Gọi Backend API ingest
│       │   ├── theme_notifier.dart       # Dark/Light mode
│       │   └── storage/
│       │       ├── base_storage_service.dart      # Abstract interface
│       │       └── telegram_storage_provider.dart  # Impl Telegram
│       └── ui/
│           ├── screens/
│           │   ├── auth_screen.dart      # Đăng nhập/đăng ký
│           │   ├── home_screen.dart      # Trang chính + danh sách audio
│           │   ├── ingest_screen.dart    # Dán link → nén audio
│           │   ├── player_screen.dart    # Full audio player
│           │   ├── chat_screen.dart      # Chat realtime
│           │   └── reader_screen.dart    # TODO: Đọc truyện
│           └── widgets/
│               └── mini_player.dart      # Player thu nhỏ
│
├── admin-web/                  # React Admin Dashboard
│   ├── Dockerfile
│   ├── package.json
│   └── src/
│       ├── App.jsx             # Sidebar + Router
│       ├── main.jsx
│       ├── api/client.js
│       ├── pages/
│       │   ├── Dashboard.jsx
│       │   ├── ContentManager.jsx
│       │   └── UserManager.jsx
│       └── components/
│           └── DataTable.jsx
│
├── docs/
│   ├── PROJECT_CONTEXT.md      # ← BẠN ĐANG ĐỌC FILE NÀY
│   └── supabase_schema.sql     # Schema: audio_metadata + messages
│
├── docker-compose.yml          # PostgreSQL + Redis + Backend + Celery
├── .env.example
└── .gitignore
```

---

## 4. Luồng Dữ Liệu Chính (Data Flow)

### 4.1. Pipeline Nén Audio (Server-side v0.3)

```
User dán YouTube URL (Mobile)
    │
    ▼
[GET /api/v1/ingest/metadata]  ← Preview metadata + thumbnail
    │
    ▼
[POST /api/v1/ingest/youtube-v2]  ← Bắt đầu pipeline
    │
    ├── Bước 1: yt-dlp tải audio gốc (bestaudio, chạy trong executor)
    ├── Bước 2: FFmpeg nén Opus 64kbps mono 48kHz + segment nếu >1.5h
    ├── Bước 3: Upload từng segment lên Telegram Bot API → nhận file_id
    ├── Bước 4: INSERT metadata + file_id vào Supabase (audio_metadata)
    └── Bước 5: Dọn dẹp file tạm (finally block)
    │
    ▼
Mobile nhận response → AudioListCubit.loadInitial() → Hiển thị bài mới
```

### 4.2. Phát Nhạc (Streaming)

```
User tap bài hát
    │
    ▼
PlayerCubit → TelegramStorageProvider.getStreamUrl(file_id)
    │
    ▼
GET /getFile → Telegram trả file_path → Ghép URL download tạm (~1h)
    │
    ▼
just_audio.setUrl(streamUrl) → Stream audio trực tiếp
```

### 4.3. Auth Flow

```
AuthScreen (Login/Register)
    │
    ▼
Supabase Auth (email/password) → JWT token tự quản lý bởi supabase_flutter
    │
    ▼
AuthCubit → AuthAuthenticated → load AudioListCubit + ChatCubit
```

### 4.4. Chat Realtime

```
User gửi tin nhắn
    │
    ▼
ChatRepository.sendMessage() → INSERT vào bảng "messages"
    │
    ▼
Supabase Realtime (Publication) → Stream broadcast → Tất cả clients nhận
```

---

## 5. Trạng Thái Các Module

### ✅ Hoàn Thành (Production-ready)

| Module | Mô tả | Ghi chú |
|--------|--------|---------|
| Supabase Auth | Đăng ký/Đăng nhập email | RLS enabled |
| Supabase DB | audio_metadata + messages | Schema chuẩn, indexes tối ưu |
| Audio Pipeline v2 | Server-side download → compress → upload | Segment support cho video dài |
| Telegram Storage | Upload/Stream zero-cost | Abstract interface cho future swap |
| Audio Repository | CRUD + cursor pagination + search | Supabase PostgREST |
| Player | just_audio streaming | Mini player + Full player |
| Chat Realtime | Global chat room | Supabase Realtime publication |
| Dark/Light Theme | ThemeNotifier + Material 3 | Gradient-based design |
| Env Config | Validate sớm tại startup | fail-fast pattern |

### ⚠️ Hoàn Thành Một Phần (Cần Review)

| Module | Vấn đề |
|--------|--------|
| Admin Web | Skeleton UI — chỉ có stub pages, chưa kết nối Supabase |
| Reader Screen | Chỉ có placeholder |
| Ingest Screen | Đã chuyển sang server-side nhưng có thể còn code mobile cũ |

### ❌ Chưa Triển Khai (TODO Stubs)

| Module | File | Ghi chú |
|--------|------|---------|
| System Stats | `admin_service.py` | `raise NotImplementedError` |
| Storage Cleanup | `admin_service.py` | `raise NotImplementedError` |
| Text Scraper | `scraper.py` | `raise NotImplementedError` |
| File Manager | `file_manager.py` | `raise NotImplementedError` |
| Playlist Feature | Mobile side | Chưa có UI/Cubit |

---

## 6. 🔴 Vấn Đề Cần Xử Lý (Bug Matrix)

### 🔴 CRITICAL — Bắt buộc sửa

| # | Vấn đề | File | Chi tiết |
|---|--------|------|----------|
| C1 | **YouTubeService dùng `_dio` (undefined)** | `youtube_service.dart` L40,67 | Khai báo `dio` (public) ở L31 nhưng sử dụng `_dio` (private, chưa khai báo) → **crash runtime** khi gọi fetchMetadata/processOnServer |
| C2 | **YouTubeService dùng `dotenv.env` chưa import** | `youtube_service.dart` L32 | Sử dụng `dotenv.env['API_BASE_URL']` nhưng không import `flutter_dotenv`. Cũng không consistent với `EnvConfig` pattern đã dùng ở L41,68 |
| C3 | **CORS allow_origins=["*"]** | `main.py` L37 | Mở toàn bộ origins — nguy cơ CSRF. Production phải restrict |
| C4 | **Backend lưu Supabase bằng service_role key** | `ingest.py` L628 | service_role key bypass RLS → nếu bị lộ key = toàn quyền DB. Cần kiểm tra cấu hình bảo mật |

### 🟠 HIGH — Ảnh hưởng trải nghiệm/logic

| # | Vấn đề | File | Chi tiết |
|---|--------|------|----------|
| H1 | **Legacy code chưa dọn: `db.py`** | `db.py` | SQLAlchemy engine + session factory vẫn tồn tại. `main.py` đã print `"skipping local DB init"` nhưng `db.py` vẫn tạo engine khi import (eager init) |
| H2 | **Legacy code chưa dọn: Models** | `models/` | `AudioTrack`, `Favorite`, `Playlist` — SQLAlchemy models không còn dùng (đã chuyển sang Supabase) |
| H3 | **Legacy code chưa dọn: `security.py`** | `core/security.py` | JWT + bcrypt — không còn dùng (Supabase Auth thay thế) |
| H4 | **Legacy code chưa dọn: `audio_proc.py` pipeline cũ** | `services/audio_proc.py` | Hàm `download_and_compress()` (L394-462), `_download_raw_audio()` + fallback — là pipeline v1 cũ, logic đã được rewrite trong `ingest.py` |
| H5 | **Docker Compose: Celery Worker** | `docker-compose.yml` L59-81 | Service `celery_worker` vẫn chạy nhưng không có `app.worker` module → container sẽ crash loop |
| H6 | **Docker Compose: Redis** | `docker-compose.yml` L23-33 | Redis service vẫn chạy nhưng không còn Celery consumer → lãng phí tài nguyên |
| H7 | **requirements.txt: Celery dependency** | `requirements.txt` L12 | `celery[redis]==5.4.0` vẫn được cài nhưng không còn sử dụng |
| H8 | **.env.example: Celery vars** | `.env.example` L13-14 | `REDIS_URL` + `CELERY_BROKER_URL` vẫn liệt kê nhưng không còn cần |

### 🟡 MEDIUM — Cải thiện được

| # | Vấn đề | File | Chi tiết |
|---|--------|------|----------|
| M1 | **Duplicate thumbnail logic** | `audio_proc.py` + `ingest.py` | Cùng logic `_get_best_thumbnail` xuất hiện ở 2 nơi |
| M2 | **Duplicate spoof headers** | `audio_proc.py` + `ingest.py` | Headers spoofing khai báo 2 lần, Chrome version khác nhau (120 vs 147) |
| M3 | **Không có rate limiting** | `ingest.py` | API endpoint không giới hạn request → có thể bị abuse để spam Telegram upload |
| M4 | **Không retry khi Telegram upload fail** | `ingest.py` L557 | httpx single request, không có retry logic |
| M5 | **schemas/ package trống** | `backend/app/schemas/` | Chỉ có `__init__.py` trống — schemas inline trong `ingest.py` |
| M6 | **ThemeNotifier không persist** | `theme_notifier.dart` | Dark/Light mode không lưu giữa các lần mở app |
| M7 | **`BlocBuilder` trong `home` widget gọi side effects** | `main.dart` L189-192 | `loadInitial()` và `updateUsername()` gọi trong builder → gọi lại mỗi rebuild |

### 🔵 LOW — Tech debt

| # | Vấn đề | File | Chi tiết |
|---|--------|------|----------|
| L1 | `psycopg2-binary` trong requirements | `requirements.txt` L8 | Chỉ cần asyncpg, psycopg2 thừa |
| L2 | `alembic` trong requirements | `requirements.txt` L9 | Không có migration files, Supabase tự quản schema |
| L3 | `beautifulsoup4 + lxml` | `requirements.txt` L23-24 | Scraper chưa triển khai, dependencies thừa |
| L4 | Backend version mismatch | `main.py` L22 vs L32 | Startup print `V0.3` nhưng app version khai báo `0.2.0` |
| L5 | `print()` thay vì `logger` | `audio_proc.py` | Nhiều chỗ dùng `print()` thay vì `logger.info()` |
| L6 | Missing unit tests | Mobile + Backend | Không có bất kỳ test nào |

---

## 7. Database Schema (Supabase)

### Bảng `audio_metadata`
| Column | Type | Note |
|--------|------|------|
| id | UUID (PK) | auto gen |
| video_id | TEXT UNIQUE | YouTube ID |
| title | TEXT | Tên gốc |
| channel_name | TEXT | Kênh YouTube |
| thumbnail_url | TEXT | URL ảnh |
| custom_name | TEXT | Tên do user đặt |
| telegram_file_id | TEXT | Key stream nhạc |
| duration_seconds | INTEGER | Thời lượng |
| size_bytes | BIGINT | Dung lượng nén |
| original_size_bytes | BIGINT | Dung lượng gốc |
| compression_ratio | REAL | % giảm |
| user_id | UUID FK → auth.users | Owner |
| is_favorite | BOOLEAN | Yêu thích |
| created_at | TIMESTAMPTZ | Timestamp |
| updated_at | TIMESTAMPTZ | Timestamp |

**RLS**: SELECT/INSERT/UPDATE/DELETE chỉ cho `auth.uid() = user_id`

### Bảng `messages`
| Column | Type | Note |
|--------|------|------|
| id | UUID (PK) | auto gen |
| user_id | UUID FK → auth.users | Người gửi |
| username | TEXT | Tên hiển thị |
| content | TEXT (≤2000 chars) | Nội dung |
| created_at | TIMESTAMPTZ | Timestamp |

**RLS**: SELECT all, INSERT chỉ khi `auth.uid() IS NOT NULL`
**Realtime**: Enabled qua `supabase_realtime` publication

---

## 8. Biến Môi Trường

### Backend (`.env`)
| Key | Mô tả | Bắt buộc |
|-----|--------|----------|
| POSTGRES_USER/PASSWORD/DB | PostgreSQL local | ⚠️ Legacy |
| SECRET_KEY | JWT secret | ⚠️ Legacy |
| TELEGRAM_BOT_TOKEN | Bot API token | ✅ |
| TELEGRAM_CHAT_ID | Chat lưu file | ✅ |
| SUPABASE_URL | Project URL | ✅ |
| SUPABASE_SERVICE_ROLE_KEY | Admin key | ✅ |

### Mobile (`.env`)
| Key | Mô tả | Bắt buộc |
|-----|--------|----------|
| SUPABASE_URL | Project URL | ✅ |
| SUPABASE_ANON_KEY | Public key | ✅ |
| TELEGRAM_BOT_TOKEN | Bot API token | ✅ |
| TELEGRAM_CHAT_ID | Chat ID | ✅ |
| API_BASE_URL | Backend endpoint | ✅ |

---

## 9. Lộ Trình Đề Xuất (Roadmap)

### Phase 1: Dọn Dẹp Legacy (Hotfix)
- [ ] Fix `YouTubeService` — sửa `_dio` → `dio`, import dotenv hoặc dùng `EnvConfig`
- [ ] Xóa `celery_worker` + Redis khỏi `docker-compose.yml`
- [ ] Xóa `celery[redis]`, `psycopg2-binary`, `alembic`, `beautifulsoup4`, `lxml` khỏi `requirements.txt`
- [ ] Xóa toàn bộ thư mục `models/` (SQLAlchemy legacy)
- [ ] Xóa `db.py`, `core/security.py`
- [ ] Xóa hoặc refactor `audio_proc.py` (chỉ giữ `fetch_metadata`, `is_playlist_url`, `extract_playlist_entries`)
- [ ] Xóa `CELERY_BROKER_URL`, `REDIS_URL` khỏi `.env.example`
- [ ] Fix version mismatch (`V0.3` vs `0.2.0`)

### Phase 2: Tăng Cường Chất Lượng
- [ ] Di chuyển `BlocBuilder` side effects ra `BlocListener`
- [ ] Persist theme preference (SharedPreferences)
- [ ] Thêm rate limiting cho ingest endpoint
- [ ] Retry logic cho Telegram upload
- [ ] Restrict CORS origins

### Phase 3: Tính Năng Mới
- [ ] Playlist management (Supabase tables + Mobile UI)
- [ ] Admin Dashboard kết nối Supabase
- [ ] Text scraper (nếu vẫn cần)
- [ ] Push notification khi pipeline xong

### Phase 4: Production Ready
- [ ] Unit tests (Backend + Mobile)
- [ ] CI/CD pipeline
- [ ] Monitoring + alerting
- [ ] Rate limiting production-grade
