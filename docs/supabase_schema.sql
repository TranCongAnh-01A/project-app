-- ===================================================
-- PMKA — Supabase Database Schema
-- Chạy script này trong Supabase SQL Editor (supabase.com → SQL Editor)
--
-- QUAN TRỌNG: Script này sẽ XÓA và TẠO LẠI bảng từ đầu.
-- Chỉ chạy khi setup lần đầu hoặc muốn reset toàn bộ data.
-- ===================================================

-- ── 0. Dọn trước — Xóa bảng cũ (nếu có) ──────────
-- Phải xóa theo thứ tự: bảng con trước, bảng cha sau
-- (do foreign key references auth.users)

-- Gỡ realtime publication trước khi drop (tránh lỗi)
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND tablename = 'messages'
  ) THEN
    ALTER PUBLICATION supabase_realtime DROP TABLE messages;
  END IF;
END $$;

DROP TABLE IF EXISTS messages CASCADE;
DROP TABLE IF EXISTS audio_metadata CASCADE;


-- ── 1. Bảng audio_metadata ──────────────────────────
-- Mỗi row = 1 file audio đã nén, lưu metadata + telegram file_id.

CREATE TABLE audio_metadata (
    id                  UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    video_id            TEXT UNIQUE NOT NULL,           -- YouTube video ID (11 ký tự)
    title               TEXT NOT NULL,                  -- Tên gốc từ YouTube
    channel_name        TEXT NOT NULL DEFAULT 'Unknown',-- Tên kênh YouTube
    thumbnail_url       TEXT,                           -- URL ảnh thumbnail
    custom_name         TEXT,                           -- Tên tùy chỉnh bởi user
    telegram_file_id    TEXT NOT NULL,                  -- file_id trên Telegram (key để stream)
    duration_seconds    INTEGER DEFAULT 0,              -- Thời lượng audio (giây)
    size_bytes          BIGINT DEFAULT 0,               -- Dung lượng file nén (.opus)
    original_size_bytes BIGINT DEFAULT 0,               -- Dung lượng file gốc trước nén
    compression_ratio   REAL DEFAULT 0.0,               -- Tỉ lệ giảm dung lượng (%)
    user_id             UUID REFERENCES auth.users(id) ON DELETE CASCADE,  -- Owner
    is_favorite         BOOLEAN DEFAULT FALSE,          -- Đánh dấu yêu thích
    created_at          TIMESTAMPTZ DEFAULT NOW(),
    updated_at          TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes cho performance
CREATE INDEX idx_audio_created_at ON audio_metadata(created_at DESC);
CREATE INDEX idx_audio_user_id ON audio_metadata(user_id);
CREATE INDEX idx_audio_video_id ON audio_metadata(video_id);

-- RLS: Mỗi user chỉ thao tác trên data của chính mình
ALTER TABLE audio_metadata ENABLE ROW LEVEL SECURITY;

CREATE POLICY "audio_select_own" ON audio_metadata
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "audio_insert_own" ON audio_metadata
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "audio_update_own" ON audio_metadata
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "audio_delete_own" ON audio_metadata
    FOR DELETE USING (auth.uid() = user_id);


-- ── 2. Bảng messages (Chat chung) ──────────────────
-- Phòng chat global — mọi user cùng sử dụng.

CREATE TABLE messages (
    id          UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id     UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    username    TEXT NOT NULL DEFAULT 'Anonymous',
    content     TEXT NOT NULL CHECK (char_length(content) <= 2000),
    created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- Index cho phân trang infinite scroll
CREATE INDEX idx_messages_created_at ON messages(created_at DESC);

-- RLS: Ai cũng đọc được, chỉ user đã đăng nhập mới gửi được
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "messages_select_all" ON messages
    FOR SELECT USING (true);

CREATE POLICY "messages_insert_auth" ON messages
    FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

-- ── 3. Bật Realtime cho bảng messages ──────────────
ALTER PUBLICATION supabase_realtime ADD TABLE messages;
